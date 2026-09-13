/*
 * boot.S - v586 Linux boot stub
 *
 * The v586 core resets in 32-bit protected mode (CR0.PE=1, CR0.PG=0)
 * with EIP=0x40d00000, flat segments (no GDT loaded; the fetch unit
 * drives linear addresses straight onto the AXI bus). Paging is off,
 * so virtual == physical.
 *
 * This stub runs at the reset vector (0x40d00000) and hands control to
 * the Linux 3.14 kernel loaded at physical 0x100000. The kernel's own
 * head code (startup_32) builds its GDT, page tables, enables paging,
 * and jumps to start_kernel. The ONLY contract the kernel head imposes
 * on entry is:
 *
 *     esi = physical address of a valid struct boot_params
 *
 * So this stub:
 *   1. Loads esi with the boot_params address (0x90000).
 *   2. Jumps to 0x100000.
 *
 * NOTE: the v586 core does NOT implement `jmp r/m32` (FF /4) - it decodes
 * that as an illegal instruction. We use `jmp rel32` (E9), which is
 * supported, computed relative to the end of the jump instruction.
 *
 * Build: see mk_boot_image.py (assembles this with `as` + `objcopy`).
 */

    .code32
    .section .text
    .globl _start
_start:
    /* esi = boot_params physical address (0x90000) */
    movl    $0x90000, %esi
    /* jmp rel32 to 0x100000. The displacement is PC-relative, computed
     * by the linker from the section VMA (0x40d00000, set in mk_boot_image.py).
     * We cannot use `jmp r/m32` (FF /4): the v586 core treats it as illegal. */
    jmp     0x100000

    /* Should never return; halt if it does. */
1:  hlt
    jmp     1b
