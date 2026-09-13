# v586

A from-scratch, 32-bit **Pentium-class x86-compatible soft processor core** written in
Verilog, together with a small FPGA **SoC** wrapper that boots on real hardware. The CPU
implements the Intel 80386/80486/Pentium (P5) user and system programming model
(real mode, protected mode, segmentation, paging, MMU/TLB) and exposes a wide **AXI4**
memory interface so it can sit on a modern FPGA fabric alongside a DDR controller and
standard PC-style peripherals.

> All of the design RTL lives under [`old/v14.0/`](old/v14.0/). This tree is the
> "v14.0" snapshot of a personal project originally written around 2013–2017 and
> committed here verbatim. It **did compile and boot on an FPGA** at the time; it is
> preserved as-is, including known bugs and missing features (see
> [Known issues / gaps](#known-issues--gaps)).

## Highlights

- **Instruction-set compatible** with the 80386/80486/Pentium integer subset:
  8/16/32-bit register and memory operations, the full ALU/shift/rotate/BCD set,
  string and `REP`/`REPNE` prefixes, conditional and unconditional control flow,
  stack, I/O, and the system instructions needed to enter and manage protected mode.
- **System programming model**: real mode + protected mode, segmentation
  (GDTR/IDTR/LDTR/TR, segment descriptors, RPL/CPL privilege checks), and 32-bit
  **paging** with a real **MMU and TLB**.
- **Harvard-style fetch/execute split** with a 128-bit instruction fetch path and a
  128-bit data path, plus a **VLIW-style microcoded execution engine** (see
  [`vliw.v`](old/v14.0/vliw.v)).
- **On-chip instruction cache** in the fetch unit (`useq.v`) and a separate data cache
  path with byte-enable **realignment** logic (`realign.v`).
- **AXI4 bus interface** — three independent AXI4 master ports (instruction, data, and
  32-bit I/O) driven through a single bus-interface unit (`biu32_axi.v`).
- **FPGA SoC**: `TOP_SYS.v` wires the core to a Xilinx **DDR2/DDR3** memory controller
  (MIG), an AXI boot ROM, AXI EthernetLite + RMII PHY, SPI flash (N25Q), a 16750 UART,
  a PC-style interrupt controller (8259) and timer (8253), a VGA/HDMI framebuffer, and
  GPIO — i.e. enough of a "PC" to boot a real-mode/protected-mode firmware.

## Repository layout

Everything is under `old/v14.0/`. Files are grouped here by role.

### CPU core

| File | Role |
|------|------|
| [`core.v`](old/v14.0/core.v) | Top of the CPU: instantiates fetch, decode, execution, MMU/TLB and caches, and the memory realignment path. |
| [`cpu.v`](old/v14.0/cpu.v) | CPU control shell: CR0/CR2/CR3, paging enable, interrupt acknowledge, fault routing, PC/branch handshake. |
| [`useq.v`](old/v14.0/useq.v) | **Instruction fetch unit + micro-instruction sequencer**: 128-bit fetch, 256-bit fetch queue, on-chip instruction cache, `useq_ptr` dispatch into the decode/execute pipeline. `useq_cache_8k_ddr.v` / `useq.v.sa` are alternate cache-sized variants. |
| [`deco.v`](old/v14.0/deco.v) | **Length/prefix/operand decoder**: parses x86 prefixes, ModR/M, SIB, immediates and displacements, one-/two-byte opcodes, and FPU (ESC) escape bytes. Emits a packed "to_acu"/"to_vliw" descriptor for the execution engine. |
| [`deco8.v`](old/v14.0/deco8.v), [`deco_rm.v`](old/v14.0/deco_rm.v) | Combinatorial 8-bit opcode pattern recognizers feeding the decoder. |
| [`udeco.v`](old/v14.0/udeco.v), [`udecox.v`](old/v14.0/udecox.v) | **Micro-op decode**: maps each decoded opcode + ModR/M + operand size / CPL / EM bit into a 128-bit micro-op word (`udeco`) consumed by the execution engine. Also synthesises the interrupt-vector micro-ops for faults and for FPU-not-available. |
| [`vliw.v`](old/v14.0/vliw.v) | **VLIW execution engine** (the largest core file): register file (8 GPRs × 8/16/32-bit views + segment regs + eflags), ALU/shift/string/branch FSMs, CR0/CR1/CR3, paging enable, GDTR/IDTR/LDTR/TR and descriptor loads, privilege/CPL handling, and the read/write/IO handshake to memory. |
| [`acu.v`](old/v14.0/acu.v) | **Address calculation unit**: decodes ModR/M/SIB, selects base/index registers and segment, computes effective addresses. |
| [`arithbox.v`](old/v14.0/arithbox.v) | ALU arithmetic/logic primitive (ADD/ADC/SUB/SBB/CMP/AND/OR, carry/overflow/auxiliary flags). |
| [`shiftbox.v`](old/v14.0/shiftbox.v) | Shift/rotate primitive (SHL/SHR/SAR/ROL/ROR/RCL/RCR, with 32/16/8-bit width). |
| [`synthetic_op.v`](old/v14.0/synthetic_op.v) | Pipelined signed/unsigned multiply/divide helper for `MUL`/`IMUL`/`DIV`/`IDIV`/`AAD`/`AAM`. |
| [`cmp14.v`](old/v14.0/cmp14.v) | 14-bit tag comparator used by the caches/TLB. |

### MMU, caches and memory system

| File | Role |
|------|------|
| [`Itlb.v`](old/v14.0/Itlb.v), [`Dtlb.v`](old/v14.0/Dtlb.v), [`tlb.v`](old/v14.0/tlb.v) | **Translation Lookaside Buffers** for instruction and data accesses. Walk page directories/tables on miss, generate page faults / write-protect faults, expose CR2 and page-table fault status. `tlb.v` is the shared base TLB walker. |
| [`datacache.v`](old/v14.0/datacache.v), [`cacheram.v`](old/v14.0/cacheram.v), [`axi_cache.v`](old/v14.0/axi_cache.v) | Data/instruction cache RAM primitives (128-bit lines, 22-bit tags) and cache glue. `axi_cache.v` is a currently-empty placeholder. |
| [`realign.v`](old/v14.0/realign.v) | Converts the CPU's byte/word/dword natural-width accesses to/from 128-bit cache-line bursts and produces the AXI byte-strobe (`WSTRB`) mask. |
| [`mem_deco.v`](old/v14.0/mem_deco.v) | Look-up ROM of decoded ModR/M / addressing cases used by the address-calculation path. |
| [`extram.v`](old/v14.0/extram.v) | Simple SRAM-style external memory model used in simulation. |
| [`axi_rom.v`](old/v14.0/axi_rom.v) | Small AXI4 read-only boot ROM holding the reset vector code. |

### AXI bus interface

| File | Role |
|------|------|
| [`biu32_axi.v`](old/v14.0/biu32_axi.v) | **Bus interface unit**: bridges the core's code/data/I/O request handshake to **three AXI4 master ports** — `m00` 128-bit instruction, `m01` 128-bit data, `m02` 32-bit peripheral I/O. |
| [`v586.v`](old/v14.0/v586.v) | Top-level **IP wrapper** exposing the three AXI4 master ports plus interrupt (`int_pic`/`ivect`/`iack`) and a debug bus. This is the "soft IP" boundary you would instantiate. |

### SoC / board (`TOP_SYS.v` and peripherals)

| File | Role |
|------|------|
| [`TOP_SYS.v`](old/v14.0/TOP_SYS.v) | **Board-level SoC**: instantiates `v586`, the Xilinx DDR MIG (`ddr_axi`), a clock wizard (`clk_wiz_0`), reset generator, boot ROM, an AXI interconnect, and all the peripherals below. This is what was wired to the FPGA pins. |
| [`clk_wiz_0.v`](old/v14.0/clk_wiz_0.v), [`rstgen.v`](old/v14.0/rstgen.v) | Xilinx MMCM clock wizard and a reset synchroniser (Arch Laboratory / BSD). |
| [`periph.v`](old/v14.0/periph.v) | AXI4-Lite peripheral hub aggregating the SPI/UART/PIC/PIT/VGA slaves. |
| [`uart_16750.v`](old/v14.0/uart_16750.v) | 16750-compatible UART (with FIFOs) for the serial console. |
| [`tiny_spi.v`](old/v14.0/tiny_spi.v) | OpenCores-style SPI master for the SPI flash. |
| [`N25Qxxx.v`](old/v14.0/N25Qxxx.v) | Micron N25Q SPI flash behavioral model (simulation). |
| [`v8259.v`](old/v14.0/v8259.v), [`v8253.v`](old/v14.0/v8253.v), [`v8253_counter.v`](old/v14.0/v8253_counter.v), [`v8042_stub.v`](old/v14.0/v8042_stub.v) | PC-compatible **8259 PIC**, **8253 PIT** (+ counter), and a stubbed **8042** keyboard controller. |
| [`vga.v`](old/v14.0/vga.v), [`vga8.v`](old/v14.0/vga8.v), [`hdmi.v`](old/v14.0/hdmi.v) | AXI frame-buffer VGA (640×200 RGB565 / 8bpp) and an HDMI/DVI test pattern generator. |

### Simulation / memory models

| File | Role |
|------|------|
| [`tb_top.v`](old/v14.0/tb_top.v) | Top-level testbench driving `TOP_SYS` with a DDR2 model and a clock/reset. |
| [`tb_udeco.v`](old/v14.0/tb_udeco.v) | Standalone testbench for the micro-op decoder. |
| [`ddr2.v`](old/v14.0/ddr2.v), [`ddr3.v`](old/v14.0/ddr3.v), [`ddr3_model.sv`](old/v14.0/ddr3_model.sv), [`ddr3_module.v`](old/v14.0/ddr3_module.v), [`ddr3_dimm.v`](old/v14.0/ddr3_dimm.v), [`ddr3_mcp.v`](old/v14.0/ddr3_mcp.v) | Micron DDR2/DDR3 **bus-functional memory models** for simulation (note: the synthesizable DRAM controller itself comes from the Xilinx MIG, referenced as `ddr_axi` in `TOP_SYS.v` and not checked in). |
| [`sdModel.v`](old/v14.0/sdModel.v) | SD-card behavioral model. |

## Architecture notes

### Pipeline / execution model

The core is not a classic RISC pipeline; it is a **fetch → decode → VLIW-execute**
flow tuned to x86's variable-length, prefix-heavy encoding:

1. **Fetch** (`useq.v`): 128-bit instruction fetch with a small on-chip cache and a
   256-bit (16-byte) fetch queue, aligned by `addrshft`. It tracks `valid_len` (how
   many valid bytes are in the queue) and supplies a 128-bit instruction window plus a
   `useq_ptr` to the decoder.
2. **Decode** (`deco.v` + `udeco.v`/`udecox.v`): consumes the fetch window, parses
   prefixes, ModR/M/SIB, immediates and displacements, and produces a packed
   descriptor (`to_acu` for addressing, `to_vliw`/`udeco` for the micro-op). It also
   recognises the FPU (ESC) escape and, per `CR0.EM`, synthesises a
   device-not-available (`#NM`, vector 7) micro-op instead of executing it.
3. **Execute** (`vliw.v`): the VLIW engine holds the GPR file, segment registers,
   eflags, CR0/CR1/CR3 and the system registers (GDTR/IDTR/LDTR/TR). It runs a small FSM
   per instruction class (ALU, shifts, strings with `REP`, branches, descriptor loads,
   system instructions) and issues 128-bit data read/write requests with 8/16/32-bit
   width selection to the memory system.
4. **Addressing** (`acu.v` + `arithbox.v` + `shiftbox.v`): computes effective
   addresses, performs ALU and shift primitives, and feeds results back to `vliw.v`.

### Memory model and MMU

- Segmentation is fully implemented: segment registers (CS/DS/ES/SS/FS/GS), descriptors
  loaded from GDT/LDT, RPL/CPL privilege checks, and segment-limit/limit faults.
- Paging is gated by `CR0.PG` (bit 31) and `CR0.PE` (bit 0). On a TLB miss the
  instruction TLB (`Itlb.v`) / data TLB (`Dtlb.v`) walk the two-level page directory +
  page table using `CR3` as the base, generating page faults (`#PF`) with `CR2` and a
  page-table-fault status. TLBs are flushed on `CR3` writes / TLB-flush instructions.
- The data side runs through `realign.v` so byte/word/dword accesses are mapped to
  128-bit cache-line bursts with correct AXI `WSTRB` byte masks.

### AXI interface

`v586.v` exposes three AXI4 master ports:

| Port | Width | Purpose |
|------|-------|---------|
| `m00_AXI_*` | 128-bit | Instruction fetch (code) |
| `m01_AXI_*` | 128-bit | Data load/store |
| `m02_AXI_*` | 32-bit  | Memory-mapped I/O (peripherals) |

`BVALID` is tied high on the masters (`m??_AXI_BREADY` driven by the core), matching the
simple-burst memory model used in the original FPGA build. In `TOP_SYS.v` the
instruction/data ports connect to the DDR MIG and boot ROM; the I/O port connects to the
peripheral hub.

### SoC boot path

At reset the CPU starts from the AXI boot ROM (`axi_rom.v`) in real mode. The boot ROM
provides the reset vector / early init code; after DDR calibration
(`init_calib_complete`) the system runs from DDR2/DDR3. Interrupts are routed through the
8259 PIC (`v8259.v`) into the core's `int_pic`/`ivect`/`iack` pins; the 8253 PIT is the
timer source.

## Tooling

- **HDL**: Verilog-2001 (a few SystemVerilog files for the DDR3 memory models,
  `ddr3_model.sv`).
- **Target / synthesis**: Xilinx 7-series toolchain (uses `STARTUPE2`, MMCM
  `clk_wiz_0`, and the Xilinx **MIG** DDR2/DDR3 controller — the MIG wrapper `ddr_axi`
  is generated by the tools and is **not** in this repo).
- **Simulation**: the provided `tb_top.v` testbench plus the Micron DDR2/DDR3
  bus-functional models; several files carry `verilator lint_off` pragmas, indicating
  the project was at least lint-checked with Verilator.

The repo does not contain a Makefile, constraints (`.xdc`), or the MIG IP — those were
kept in the original FPGA project. To rebuild you would regenerate the MIG and clock
wizard IPs for your board and add pin constraints.

## Simulation (Verilator)

A self-contained, vendor-IP-free **Verilator simulation platform** lives in [`sim/`](sim/)
with a [`Makefile`](Makefile) at the repo root. It replaces all Xilinx primitives (MIG,
clock wizard, crossbar, STARTUPE2) and the broken `TOP_SYS.v` board top with a clean sim
harness so the v586 core and its real peripheral hub run end-to-end under Verilator.

### Quick start

```bash
# Build + run the Verilator simulation (default 200k cycles)
make sim
# Short run
make sim MAX_CYC=5000
# Build only
make build
# Run with VCD trace -> waves/top_sim.vcd
make trace MAX_CYC=2000
# Verilator lint-only pass
make lint
# Icarus Verilog fallback (if verilator is unavailable)
make iverilog
make clean
```

### What is in the sim platform

| File | Role |
|------|------|
| [`sim/TOP_SYS_sim.v`](sim/TOP_SYS_sim.v) | Simulation-only system top. Wires `v586` `m00` (128-bit code/data) to a functional AXI RAM and `m01` (32-bit I/O) to the real [`periph`](old/v14.0/periph.v) hub; `m02` is tied off. Short calibration delay mimics MIG `init_calib_complete`. |
| [`sim/axi_mem128.v`](sim/axi_mem128.v) | Simple 128-bit AXI4 slave RAM (16 MiB). Honours `WSTRB`, INCR bursts, one-cycle accept/read. **Address-windowed**: subtracts `BASE` (0x40d00000, the reset vector) and masks to `AW` bits so the reset fetch lands at offset 0. Preloads a `$readmemh` boot image at offset 0. |
| [`sim/boot.hex`](sim/boot.hex) | Minimal boot image: `jmp $` (`EB FE`) + NOPs, proving the fetch path. Replace with a real boot image (one byte per line, hex). |
| [`sim/ddr_axi_sim.v`](sim/ddr_axi_sim.v) | Functional replacement for the Xilinx MIG `ddr_axi` wrapper (same port list for compatibility). DDR2 pads driven inert; backs the AXI slave with a flat byte-addressed array. **Not used by the sim top** (kept for parity with `TOP_SYS.v`). |
| [`sim/notech_cells.v`](sim/notech_cells.v) | Behavioral models for the `notech_*` standard-cell library used by the gate-level [`uart_16750.v`](old/v14.0/uart_16750.v) (DFFs, gates, muxes, adders). The cell models were never checked in. |
| [`sim/tb_top_sim.cpp`](sim/tb_top_sim.cpp) | Verilator C++ testbench: 100 MHz clock, 16-cycle reset, runs for `--cycles`, prints UART TXD and debug-port transitions, optional `--trace` VCD output. |
| [`sim/tb_iverilog.v`](sim/tb_iverilog.v) | Minimal Verilog testbench for the Icarus fallback. |

### Reset vector and boot image

The core fetches its reset vector at **0x40d00000** (set in [`useq.v`](old/v14.0/useq.v) and
[`vliw.v`](old/v14.0/vliw.v) — *not* the standard x86 0xFFFF0). The sim RAM windows this
address to offset 0. To run real code, provide a boot image:

```bash
# use a custom boot image
make sim BOOT_HEX=/path/to/firmware.hex
```

The hex file is a `$readmemh` file (one byte per line, hex). The default
[`sim/boot.hex`](sim/boot.hex) holds `EB FE` (`jmp $`) so the core fetches and stays at the
reset vector, confirming the full fetch path (useq → biu → axi_mem128) works.

### RTL fixes needed to build

Several original files had genuine syntax/structural bugs that only parsed under the
lenient tools of a decade ago. Minimal fixes (no behavioural changes) were applied so the
RTL compiles cleanly under Verilator 5:

- [`axi_cache.v`](old/v14.0/axi_cache.v) — was a broken empty stub (`axi_cache ();endmodule`);
  replaced with a proper empty module with `clk`/`rstn` ports. Never instantiated.
- [`biu32_axi.v`](old/v14.0/biu32_axi.v) — stray `:` → `;`, and port/reg name mismatches
  (`I_axi_io_`/`D_axD_`/`I_axi_` vs header names) that only worked under old lenient tools.
  **Functional fix:** the instruction-fetch path never captured the AXI read data —
  `code_data` was declared `output reg` but never assigned, so every fetch returned zeros.
  The code-fetch FSM now latches `axi_R` into `code_data` on the beat and uses a single
  128-bit (16-byte) burst (`ARLEN=0`, `ARSIZE=4`) matching the 16-byte `useq` line fill.
  Without this the core could never execute any real code.
- [`realign.v`](old/v14.0/realign.v) — added missing `reg [15:0] write_msk_ff;` declaration;
  fixed a missing semicolon after a concatenation.
- [`mem_deco.v`](old/v14.0/mem_deco.v) — `inital`→`initial`, removed stray `end`/`; else`
  tokens, fixed a prematurely-closed concatenation brace.
- [`core.v`](old/v14.0/core.v) — split a mixed `input`/`output` declaration so `Daddr`/`io_add`
  are correctly `output` (driven by internal submodules).

### Notes

- The original `TOP_SYS.v` is **not used** for simulation: it has width-mismatch bugs
  (128-bit v586 master ports connected to 32-bit crossbar wires) and depends on Xilinx IP
  not in this repo. `TOP_SYS_sim.v` wires the core directly.
- `v586.v`'s `debug[4:0]` port is declared but **never driven** internally, so it stays 0;
  it is an unconnected observation stub. Core activity is observable via the m00 AXI bus
  and UART TXD.
- The `v586` port split is `m00`=128-bit instruction+data, `m01`=32-bit I/O, `m02`=32-bit
  (unused internally). The sim top honours this.

## Linux boot investigation

The repo ships an old `old/v14.0/vmlinux.bin` (a Linux 3.14-era i386 `startup_32`
kernel image, ~1.4 MB) that the original FPGA build used to boot. A minimal
bootloader (`sim/boot.S`, assembled by `sim/mk_boot_image.py`) was written to satisfy
the kernel head's only entry contract — `esi = &boot_params` — and jump to the
kernel at physical `0x100000`:

```asm
    movl    $0x90000, %esi      ; esi = boot_params physical address
    jmp     0x100000            ; jmp rel32 (E9); the v586 core does not
                                ; implement `jmp r/m32` (FF /4)
```

`mk_boot_image.py` synthesises a `boot_params` block (zero-filled, with a
`hdr->cmd_line_ptr` and a `cmdline` of `console=ttyS0`) and produces two
`$readmemh` images: `build/boot.hex` (at the `0x40d00000` reset vector) and
`build/kernel.hex` (low memory, kernel + boot_params + cmdline).

### Result of the attempt

With the `code_data` fetch fix above, the simulation **boots the kernel through
early `startup_32` and into the paged high-kernel virtual address**:

1. Reset at `0x40d00000` → executes `mov esi,0x90000` → `jmp 0x100000` (the
   `jmp rel32` is correctly decoded and the PC redirects to the kernel).
2. Linux `startup_32` runs: loads the GDT (`lgdt`), loads segment registers with
   selector `0x18`, clears the BSS (`rep stosd` over `0x256000..0x275000`, ~349k
   cycles), and builds identity + kernel page directories with a `loop`-based
   page-table fill loop (`stos` / `add eax,0x1000` / `loop`) — the `loop`
   instruction's ECX decrement works and the loop terminates.
3. Enables paging (`mov %eax,%cr0` with `0x50033` at `0x1000e1`) and jumps to
   the kernel's linked virtual address `0xc010016b` (`0xc0000000` + text).

So the core, the I-TLB pass-through, the `lgdt`/segment loads, `rep stosd`,
`loop`, and the `mov cr0` / paging-enable path all work, and paging successfully
relocates execution to `0xc010xxxx`.

### Where it currently hangs

The boot then stalls at `0xc0100171` (`mov eax,[0xc0234c80]`) — the first data
read from a high kernel virtual address after paging is on. Probing the DTLB
shows:

- the virtual address `0xc0234c80` is translated to physical `0x00256c00`
  (it should be `0x00234c80` — `0xc0000000` → `0x00000000`), and
- `pg_fault` asserts and stays high forever.

This is a **DTLB translation bug**: the data TLB mis-translates a high-virtual
kernel address and then wedges in a page-fault loop (the kernel has not yet
installed its IDT/page-fault handler, so the fault cannot be delivered).
This is the concrete manifestation of the “few bugs that make it hang” the
project had on hardware, now isolated to the `Dtlb.v`/`tlb.v` page-walk /
translation path for `0xc0000000+` mappings.

Reproducing:
```bash
make sim MAX_CYC=600000      # ~600k cycles reaches the hang
# summary line: "... DID reached high kernel ... Final EIP=c0100171 ... stuck"
make sim MAX_CYC=5000000 --verbose   # longer run confirms it never recovers
```

The remaining work to actually reach `start_kernel` is in the DTLB: fix the
wrong physical translation for `0xc0000000+` pages (likely a tag/offset
assembly bug in the page-walk FSM in [`Dtlb.v`](old/v14.0/Dtlb.v) /
[`tlb.v`](old/v14.0/tlb.v)) and ensure the page-fault delivery path can
vector through the (BIOS/default) IDT.

## Known issues / gaps

This is an old, archived snapshot. What is preserved works at the level it did when
last touched on hardware, but there are known problems to fix before it is usable again:

- **No FPU / x87.** The x87 (ESC) opcodes are *recognised and decoded* (`deco.v` sets
  `fpu`, `udeco.v`/`udecox.v` handle the EM bit) but **no floating-point datapath
  exists**. With `CR0.EM = 1` the decoder synthesises a device-not-available exception
  (`#NM`, vector 7); with EM cleared the instruction is effectively skipped. Adding the
  FPU is the biggest missing feature.
- **Hang bugs.** The design had intermittent hangs on the FPGA. Likely areas, based on
  the handshake style in the core: the read/write `*_req`/`*_ack` handshakes between
  `vliw.v` ↔ `realign.v` ↔ `biu32_axi.v`, the TLB miss / page-fault recovery FSMs in
  `Itlb.v`/`Dtlb.v`, and the fetch-queue refill / `valid_len` logic in `useq.v`. These
  have not been triaged in this snapshot.
- **Empty placeholder.** `axi_cache.v` is an empty module (`axi_cache (); endmodule`)
  and `useq.v.sa` is a saved-but-unused variant of the fetch unit.
- **Vendor IP not checked in.** The MIG DDR controller (`ddr_axi`), the full
  `clk_wiz_0`, and pin constraints are absent — they must be regenerated for a target
  board.
- **Code style.** The RTL predates modern lint hygiene: broad `casex`/`caseX` use,
  implicit widths, and many `verilator lint_off` suppression pragmas. A cleanup pass
  would be needed for current Verilator / synthesis warning behaviour.

## Status

Archived, as-authored. The project is here as a reference implementation of an
x86/Pentium-class soft core with MMU, caches and an AXI SoC. Booting it again, fixing
the hang bugs, and adding the FPU are the open work items.
