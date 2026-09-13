#!/usr/bin/env python3
"""mk_boot_image_v1082.py - build v10.8.2 Linux boot images for Verilator.

Produces two $readmemh hex files (one byte per line):
  kernel.hex       (LOW region)  - bin2v.bin (kernel+initramfs) at 0x100000
  boot_v1082.hex   (HIGH region) - patched boot stub at the reset vector 0xFFC00

The v10.8.2 core resets at EIP=0xFFC00 in 32-bit protected mode (cr0.PE=1,
paging off). The original boot.mem bit-bangs an SPI flash to copy the kernel
into RAM. We do not have that flash image, so we preload the kernel directly
into RAM at 0x100000 and run a minimal boot stub that replicates the
boot_params setup the original boot.mem performed, then does
`ljmp $0x10:0x100000` (esi=0x90000), exactly like the original tail.

Memory layout (physical; paging off at boot):
  0x00090000  -> struct boot_params  (esi on kernel entry)
  0x00090800  -> kernel command line string
  0x00100000  -> bin2v.bin (Linux 4.5 kernel + embedded cpio initramfs)
  0x000ffc00  -> boot stub (reset vector)
"""
import argparse
import os
import struct
import subprocess
import sys
import tempfile

KERNEL_LOAD   = 0x00100000
BOOTPARAMS_PA = 0x00090000
CMDLINE_PA    = 0x00090800
RESET_VECTOR  = 0x000ffc00

# boot_params field offsets (arch/x86/include/uapi/asm/bootparam.h)
OFF_HDR            = 0x1f1
H_SETUP_SECTS      = 0x1f1
H_BOOT_FLAG        = 0x1fe
H_JUMP             = 0x200
H_HEADER           = 0x202   # "HdrS"
H_VERSION          = 0x206
H_TYPE_OF_LOADER   = 0x210
H_LOADFLAGS        = 0x211
H_CODE32_START     = 0x214
H_RAMDISK_IMAGE    = 0x218
H_RAMDISK_SIZE     = 0x21c
H_HEAP_END_PTR     = 0x224
H_CMD_LINE_PTR     = 0x228
H_CMDLINE_SIZE     = 0x238
H_HARDWARE_SUBARCH = 0x23c
OFF_E820_ENTRIES   = 0x1e8
OFF_SENTINEL       = 0x1ef
E820_MAP_OFF       = 0x2d0
E820_RAM           = 1

LOADED_HIGH   = 0x01
KEEP_SEGMENTS  = 0x40
CAN_USE_HEAP  = 0x80

def le32(v): return struct.pack('<I', v & 0xffffffff)
def le16(v): return struct.pack('<H', v & 0xffff)
def le64(v): return struct.pack('<Q', v & 0xffffffffffffffff)

BOOT_STUB_ASM = r"""
/* v10.8.2 sim boot stub - runs at the reset vector 0xFFC00 in 32-bit PM.
 * Replicates the boot_params setup of the original boot.mem tail, then
 * hands control to the Linux kernel preloaded at 0x100000.
 *   esi = 0x90000 (boot_params), ljmp $0x10:0x100000
 * The original boot stub set cr0=1 then ljmp $0:0xFFC20; we keep that entry
 * so the same reset fetch semantics apply, then fall through to setup.
 * The command line is embedded as data in this ROM (at cmdline_lbl) and
 * copied to 0x90800, exactly like the original boot.mem copied from 0xfff20.
 */
    .code32
    .section .text
    .globl _start
_start:
    /* re-assert cr0.PE (matches original boot.mem first instruction) */
    movl    $1, %eax
    movl    %eax, %cr0
    /* ljmp to clear prefetch / set cs=0 like the original (target = next) */
    ljmp    $0x0, $1f
1:
    /* zero 0x400 bytes of boot_params at 0x90000 */
    movl    $0x90000, %edi
    movl    $0x400/4, %ecx
    xorl    %eax, %eax
    rep     stosl
    /* copy command line from ROM (cmdline_lbl) -> 0x90800 (256 bytes) */
    movl    $0x90800, %edi
    movl    $cmdline_lbl, %esi
    movl    $0x100/4, %ecx
    rep     movsl
    /* cmd_line_ptr = 0x90800 */
    movl    $0x90800, %eax
    movl    %eax, 0x90228
    /* type_of_loader = 1 */
    movb    $1, 0x90210
    /* ramdisk_image = 0x500000, ramdisk_size = 0x300000 (kept for parity,
     * though the kernel uses its embedded initramfs if present) */
    movl    $0x500000, %eax
    movl    %eax, 0x90218
    movl    $0x300000, %eax
    movl    %eax, 0x9021c
    /* setup_header magic + version + flags (so the kernel trusts boot_params) */
    movw    $0xaa55, 0x901fe
    movw    $0x020c, 0x90206     # version 2.12
    movb    $0xff, 0x90210       # type_of_loader = 0xff (unknown)
    movb    $0x41, 0x90211       # loadflags: LOADED_HIGH|KEEP_SEGMENTS|CAN_USE_HEAP
    movl    $0x100000, 0x90214   # code32_start
    movw    $0xfe00, 0x90224     # heap_end_ptr
    movl    $0x100, 0x90238      # cmdline_size
    movl    $0x0,   0x9023c      # hardware_subarch = 0
    /* e820: one RAM entry 0..0x800000 */
    movb    $1, 0x901e8
    movl    $0, 0x902d0          # addr lo
    movl    $0, 0x902d4          # addr hi
    movl    $0x800000, 0x902d8   # size lo
    movl    $0, 0x902dc          # size hi
    movl    $1, 0x902e0          # type = RAM
    /* esi = boot_params, jump to kernel */
    movl    $0x90000, %esi
    ljmp    $0x10, $0x100000
1:  hlt
    jmp     1b
    .align 16
cmdline_lbl:
    .asciz "__CMDLINE__"
"""

def assemble_stub(asm_text, vma=RESET_VECTOR):
    with tempfile.TemporaryDirectory() as td:
        obj = os.path.join(td, 's.o')
        elf = os.path.join(td, 's.elf')
        binf = os.path.join(td, 's.bin')
        with open(os.path.join(td, 's.S'), 'w') as f:
            f.write(asm_text)
        subprocess.run(['as', '--32', '-o', obj, os.path.join(td, 's.S')], check=True)
        subprocess.run(['ld', '-m', 'elf_i386',
                        '--section-start', '.text=0x%x' % vma,
                        '-Ttext', '0x%x' % vma, '-o', elf, obj], check=True)
        subprocess.run(['objcopy', '-O', 'binary', '-j', '.text', elf, binf],
                       check=True)
        with open(binf, 'rb') as f:
            return f.read()

def write_hex(img_map, path):
    if not img_map:
        with open(path, 'w') as f:
            f.write('00\n')
        return
    mx = max(img_map)
    with open(path, 'w') as f:
        for a in range(mx + 1):
            f.write('%02x\n' % img_map.get(a, 0))

def main():
    ap = argparse.ArgumentParser(description='v586 v10.8.2 Linux boot image builder')
    ap.add_argument('--kernel', required=True, help='path to bin2v.bin (kernel)')
    ap.add_argument('--outdir', default='.', help='output directory')
    ap.add_argument('--cmdline', default='console=ttyS0,115200n8 root=/dev/ram0 rw',
                    help='kernel command line (placed at 0xfff20 for the stub)')
    args = ap.parse_args()

    with open(args.kernel, 'rb') as f:
        kernel = f.read()
    print('kernel (bin2v.bin): %d bytes (0x%x)' % (len(kernel), len(kernel)))

    stub = assemble_stub(BOOT_STUB_ASM.replace('__CMDLINE__', args.cmdline),
                        RESET_VECTOR)
    print('boot stub: %d bytes' % len(stub))
    if len(stub) > 1024:
        print('WARNING: boot stub (%d) exceeds the 1 KiB boot ROM window' % len(stub))

    # LOW region: kernel at 0x100000 (region base 0)
    low_img = {}
    for i, b in enumerate(kernel):
        low_img[KERNEL_LOAD + i] = b

    # HIGH region: boot stub at reset vector (region base = 0xFFC00)
    high_img = {i: b for i, b in enumerate(stub)}

    os.makedirs(args.outdir, exist_ok=True)
    low_path  = os.path.join(args.outdir, 'kernel.hex')
    high_path = os.path.join(args.outdir, 'boot_v1082.hex')
    write_hex(low_img, low_path)
    write_hex(high_img, high_path)
    print('wrote %s (%d entries -> 0x%x)' % (low_path, max(low_img)+1, max(low_img)+1))
    print('wrote %s (%d entries)' % (high_path, max(high_img)+1))
    print('done')

if __name__ == '__main__':
    main()
