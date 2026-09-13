#!/usr/bin/env python3
"""
mk_boot_image.py - build the v586 Linux boot images for Verilator simulation.

Produces two $readmemh hex files (one byte per line, hex):

  boot.hex   (HIGH region)  - the boot stub at the reset vector 0x40d00000
  kernel.hex (LOW region)   - vmlinux.bin at 0x100000 + boot_params at 0x90000
                              + command line + e820 memory map

Memory layout (all physical, the v586 runs with paging off at reset):

  0x00000000 .. 0x0009ffff   low RAM
  0x00090000              ->  struct boot_params  (esi points here on entry)
  0x000a0000              ->  kernel command line string
  0x00100000              ->  vmlinux.bin  (Linux startup_32 entry)
  ...
  0x40d00000              ->  boot stub (this is where the core fetches at reset)

The kernel head (startup_32 at 0x100000) only requires:
    esi = physical address of struct boot_params

It then builds its own GDT, page tables, enables paging, and jumps to
start_kernel. We populate boot_params with:
  - hdr (setup_header): type_of_loader, loadflags, cmd_line_ptr
  - e820_entries + e820_map: one RAM entry covering the sim DDR window
  - sentinel = 0  (tells the kernel boot_params was cleanly initialised)

The hex files are loaded by axi_mem128 via $readmemh at region base 0.
"""

import argparse
import os
import struct
import subprocess
import sys
import tempfile

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
KERNEL_LOAD    = 0x00100000   # physical load address of vmlinux.bin
BOOTPARAMS_PA  = 0x00090000  # physical address of struct boot_params (-> esi)
CMDLINE_PA     = 0x000a0000  # physical address of the command-line string
RESET_VECTOR   = 0x40d00000  # v586 reset fetch address (boot stub lives here)

# boot_params struct offsets (see arch/x86/include/uapi/asm/bootparam.h)
OFF_E820_ENTRIES = 0x1e8     # u8  e820_entries
OFF_SENTINEL     = 0x1ef     # u8  sentinel  (0 => clean buffer)
OFF_HDR          = 0x1f1     # struct setup_header
# setup_header field offsets (relative to 0x1f1)
H_SETUP_SECTS   = 0x1f1
H_ROOT_FLAGS    = 0x1f2
H_SYSSIZE       = 0x1f4
H_RAM_SIZE      = 0x1f8
H_VID_MODE      = 0x1fa
H_ROOT_DEV      = 0x1fc
H_BOOT_FLAG     = 0x1fe
H_JUMP          = 0x200
H_HEADER        = 0x202      # "HdrS"
H_VERSION       = 0x206
H_TYPE_OF_LOADER = 0x210
H_LOADFLAGS     = 0x211
H_CODE32_START  = 0x214
H_RAMDISK_IMAGE = 0x218
H_RAMDISK_SIZE  = 0x21c
H_HEAP_END_PTR  = 0x224
H_CMD_LINE_PTR  = 0x228
H_CMDLINE_SIZE  = 0x238
H_HARDWARE_SUBARCH = 0x23c
# e820 map at 0x2d0, each entry 20 bytes: {u64 addr, u64 size, u32 type}
E820_MAP_OFF    = 0x2d0
E820_RAM        = 1
E820_RESERVED   = 2

# loadflags bits
LOADED_HIGH    = 0x01        # kernel loaded at 0x100000
KEEP_SEGMENTS  = 0x40        # do not reload segment regs at 32-bit entry
CAN_USE_HEAP   = 0x80

BOOTPARAMS_SIZE = 0x1000     # the kernel head copies 0x1000 bytes from esi


def le32(v): return struct.pack('<I', v & 0xffffffff)
def le16(v): return struct.pack('<H', v & 0xffff)
def le64(v): return struct.pack('<Q', v & 0xffffffffffffffff)


def assemble_boot_stub(src_path):
    """Assemble boot.S -> raw binary bytes.

    The stub runs at the reset vector 0x40d00000, and it uses a PC-relative
    `jmp rel32` to reach 0x100000. For the assembler to compute the correct
    displacement we must link the .text section at VMA 0x40d00000.
    """
    with tempfile.TemporaryDirectory() as td:
        obj = os.path.join(td, 'boot.o')
        linked = os.path.join(td, 'boot.elf')
        binf = os.path.join(td, 'boot.bin')
        subprocess.run(['as', '--32', '-o', obj, src_path], check=True)
        # link at the reset vector so PC-relative displacements are correct
        subprocess.run(
            ['ld', '-m', 'elf_i386', '--section-start', '.text=0x40d00000',
             '-Ttext', '0x40d00000', '-o', linked, obj],
            check=True)
        subprocess.run(['objcopy', '-O', 'binary', '-j', '.text', linked, binf],
                       check=True)
        with open(binf, 'rb') as f:
            return f.read()


def build_bootparams(cmdline, ram_base, ram_size):
    """Build a 0x1000-byte struct boot_params blob."""
    bp = bytearray(BOOTPARAMS_SIZE)

    def put(off, data):
        bp[off:off+len(data)] = data

    # sentinel = 0  => boot_params was cleanly initialised by the loader
    put(OFF_SENTINEL, b'\x00')

    # e820: one RAM entry covering the sim DDR window
    put(OFF_E820_ENTRIES, b'\x01')   # 1 entry
    e820 = le64(ram_base) + le64(ram_size) + le32(E820_RAM)
    put(E820_MAP_OFF, e820)

    # --- setup_header (hdr) ---
    put(H_SETUP_SECTS, b'\x04')              # 4 setup sectors (conventional)
    put(H_ROOT_FLAGS, le16(0x0001))          # root mounted readonly
    put(H_BOOT_FLAG, le16(0xaa55))           # magic
    put(H_JUMP, b'\xeb\x1e')                # jump (short, +0x1e)
    put(H_HEADER, b'HdrS')                   # magic
    put(H_VERSION, le16(0x020c))            # boot protocol 2.12
    put(H_TYPE_OF_LOADER, b'\xff')          # 0xFF = unknown bootloader
    put(H_LOADFLAGS, bytes([LOADED_HIGH | KEEP_SEGMENTS | CAN_USE_HEAP]))
    put(H_CODE32_START, le32(KERNEL_LOAD))   # 0x100000
    put(H_RAMDISK_IMAGE, le32(0))            # no initrd
    put(H_RAMDISK_SIZE, le32(0))
    put(H_HEAP_END_PTR, le16(0xfe00))        # heap end
    put(H_CMD_LINE_PTR, le32(CMDLINE_PA))    # command line physical address
    put(H_CMDLINE_SIZE, le32(255))          # max cmdline size
    put(H_HARDWARE_SUBARCH, le32(0))        # 0 = default x86/PC

    return bytes(bp)


def build_low_image(vmlinux_bin, bootparams, cmdline_bytes):
    """Build the LOW-memory image as a sparse (addr->byte) map, then
    serialize to a $readmemh file covering 0..max_addr."""
    img = {}   # physical byte address -> byte value

    # boot_params at 0x90000
    for i, b in enumerate(bootparams):
        img[BOOTPARAMS_PA + i] = b

    # command line at 0xa0000
    for i, b in enumerate(cmdline_bytes):
        img[CMDLINE_PA + i] = b

    # vmlinux.bin at 0x100000
    for i, b in enumerate(vmlinux_bin):
        img[KERNEL_LOAD + i] = b

    return img


def write_hex(img_map, path):
    """Write a sparse byte map as a $readmemh file (one byte per line).
    $readmemh fills memory[0..N-1] sequentially; gaps are written as 00
    by axi_mem128's zero-init, so we only need to emit up to the highest
    set address, padding holes with 00."""
    if not img_map:
        with open(path, 'w') as f:
            f.write('00\n')
        return
    max_addr = max(img_map)
    with open(path, 'w') as f:
        for a in range(max_addr + 1):
            f.write('%02x\n' % img_map.get(a, 0))


def main():
    ap = argparse.ArgumentParser(description='v586 Linux boot image builder')
    ap.add_argument('--vmlinux', required=True, help='path to vmlinux.bin')
    ap.add_argument('--boot-S', default=None,
                    help='path to boot.S (default: alongside this script)')
    ap.add_argument('--outdir', default='.', help='output directory')
    ap.add_argument('--cmdline',
                    default='console=ttyS0,115200 root=/dev/ram0 rw earlyprintk=serial',
                    help='kernel command line')
    ap.add_argument('--ram-base', type=lambda x: int(x, 0), default=0,
                    help='e820 RAM base (default 0)')
    ap.add_argument('--ram-size', type=lambda x: int(x, 0), default=0x01000000,
                    help='e820 RAM size (default 16 MiB)')
    args = ap.parse_args()

    here = os.path.dirname(os.path.abspath(__file__))
    boot_s = args.boot_S or os.path.join(here, 'boot.S')

    with open(args.vmlinux, 'rb') as f:
        vmlinux = f.read()
    print('vmlinux.bin: %d bytes (0x%x)' % (len(vmlinux), len(vmlinux)))

    boot_stub = assemble_boot_stub(boot_s)
    print('boot stub: %d bytes' % len(boot_stub))

    cmdline = args.cmdline.encode() + b'\x00'
    print('cmdline: %r (%d bytes)' % (args.cmdline, len(cmdline)))

    bootparams = build_bootparams(args.cmdline, args.ram_base, args.ram_size)
    print('boot_params: %d bytes at 0x%08x' % (len(bootparams), BOOTPARAMS_PA))

    # LOW image: boot_params + cmdline + kernel, addressed from region base 0
    low_img = build_low_image(vmlinux, bootparams, cmdline)
    # HIGH image: boot stub at reset vector. mem1 is loaded at region offset 0,
    # so the hex file simply lists the stub bytes sequentially.
    high_img = {i: b for i, b in enumerate(boot_stub)}

    os.makedirs(args.outdir, exist_ok=True)
    low_path = os.path.join(args.outdir, 'kernel.hex')
    high_path = os.path.join(args.outdir, 'boot.hex')

    write_hex(low_img, low_path)
    write_hex(high_img, high_path)
    print('wrote %s (%d entries -> 0x%x)' % (low_path, max(low_img)+1, max(low_img)+1))
    print('wrote %s (%d entries)' % (high_path, max(high_img)+1))
    print('done')


if __name__ == '__main__':
    main()
