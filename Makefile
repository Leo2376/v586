# Makefile for the v586 simulation platform (Verilator, Icarus fallback)
#
# Targets:
#   make sim        - build & run the Verilator simulation
#   make build      - compile the Verilator model only
#   make run        - run a previously built model
#   make trace      - run with VCD tracing (waves/top_sim.vcd)
#   make iverilog   - build & run with Icarus Verilog (fallback)
#   make lint       - Verilator lint-only pass (no build)
#   make clean
#
# Requires: verilator (>= 4) and g++, OR iverilog. Neither is bundled.

VDIR     := old/v14.0
SDIR     := sim
BUILD    := build
TOP      := TOP_SYS_sim

VERILATOR ?= verilator
IVERILOG   ?= iverilog

# --- Core RTL files needed by the sim platform --------------------------
# CPU core + memory system + AXI bus + IP wrapper
CORE_V := \
	$(VDIR)/v586.v \
	$(VDIR)/biu32_axi.v \
	$(VDIR)/core.v \
	$(VDIR)/cpu.v \
	$(VDIR)/useq.v \
	$(VDIR)/deco.v \
	$(VDIR)/deco8.v \
	$(VDIR)/deco_rm.v \
	$(VDIR)/udeco.v \
	$(VDIR)/udecox.v \
	$(VDIR)/vliw.v \
	$(VDIR)/acu.v \
	$(VDIR)/arithbox.v \
	$(VDIR)/shiftbox.v \
	$(VDIR)/synthetic_op.v \
	$(VDIR)/cmp14.v \
	$(VDIR)/Itlb.v \
	$(VDIR)/Dtlb.v \
	$(VDIR)/tlb.v \
	$(VDIR)/datacache.v \
	$(VDIR)/realign.v \
	$(VDIR)/mem_deco.v \
	$(VDIR)/axi_cache.v

# Peripheral hub + its sub-devices (no Xilinx primitives)
PERIPH_V := \
	$(VDIR)/periph.v \
	$(VDIR)/uart_16750.v \
	$(VDIR)/v8259.v \
	$(VDIR)/v8253.v \
	$(VDIR)/v8253_counter.v \
	$(VDIR)/v8042_stub.v \
	$(VDIR)/tiny_spi.v

# Simulation-only functional models
SIM_V := \
	$(SDIR)/ddr_axi_sim.v \
	$(SDIR)/axi_mem128.v \
	$(SDIR)/notech_cells.v \
	$(SDIR)/TOP_SYS_sim.v

ALL_V := $(CORE_V) $(PERIPH_V) $(SIM_V)

# Boot image preloaded at the reset vector (0x40d00000). Override with
#   make sim BOOT_HEX=path/to/hex
BOOT_HEX ?= $(abspath $(SDIR)/boot.hex)

# --- Verilator flags -----------------------------------------------------
# Broad lint suppression: the original RTL uses casex/implicit widths/etc.
VL_FLAGS := --Wall -Wno-WIDTH -Wno-UNUSED -Wno-UNOPTFLAT -Wno-CASEX \
            -Wno-CASEINCOMPLETE -Wno-PINMISSING -Wno-PINNOCONNECT \
            -Wno-IMPLICIT -Wno-COMBDLY -Wno-UNDRIVEN -Wno-BLKANDNBLK \
            -Wno-DECLFILENAME -Wno-UNOPT -Wno-LATCH -Wno-WIDTHCONCAT \
            -Wno-CASEOVERLAP -Wno-REALCVT -Wno-INITIALDLY -Wno-TIMESCALEMOD \
            -Wno-fatal --trace --top-module $(TOP) \
            -DBOOT_HEX=\"$(BOOT_HEX)\"

TB_CPP := $(SDIR)/tb_top_sim.cpp
EXE    := $(BUILD)/V$(TOP)

MAX_CYC ?= 200000

.PHONY: sim build run trace iverilog lint clean

sim: build
	@mkdir -p waves
	$(EXE) --cycles $(MAX_CYC)

trace: build
	@mkdir -p waves
	$(EXE) --cycles $(MAX_CYC) --trace

build: $(EXE)

$(EXE): $(ALL_V) $(TB_CPP)
	@mkdir -p $(BUILD)
	$(VERILATOR) --cc --exe $(VL_FLAGS) \
	    -CFLAGS "-std=c++17 -O2" \
	    -Mdir $(BUILD) \
	    $(ALL_V) $(TB_CPP)
	$(MAKE) -C $(BUILD) -f V$(TOP).mk -j 1 \
	    CFG_CXXFLAGS_PCH= CFG_CXXFLAGS_PCH_I= \
	    VK_PCH_I_FAST= VK_PCH_I_SLOW= \
	    V$(TOP)__pch.h.fast.gch= V$(TOP)__pch.h.slow.gch=
	@test -f $(BUILD)/V$(TOP) && cp $(BUILD)/V$(TOP) $(EXE) || true

run:
	@mkdir -p waves
	$(EXE) --cycles $(MAX_CYC)

lint:
	@mkdir -p $(BUILD)
	$(VERILATOR) --lint-only $(VL_FLAGS) -Mdir $(BUILD) $(ALL_V)

# --- Icarus fallback -----------------------------------------------------
IVERILOG_EXE := $(BUILD)/sim.vvp

iverilog: $(IVERILOG_EXE)
	@mkdir -p waves
	vvp $(IVERILOG_EXE) +vcdplus_on=waves/top_sim.vcd

# Icarus needs a small Verilog testbench wrapper since there is no C++ TB.
$(IVERILOG_EXE): $(ALL_V) $(SDIR)/tb_iverilog.v
	@mkdir -p $(BUILD)
	$(IVERILOG) -g2012 -o $(IVERILOG_EXE) $(ALL_V) $(SDIR)/tb_iverilog.v

clean:
	rm -rf $(BUILD) waves
