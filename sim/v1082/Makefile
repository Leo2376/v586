# Makefile for the v10.8.2 v586 simulation platform (Verilator)
#
# Run from the repo root:  make -C sim/v1082 <target>
# or:                       make -f sim/v1082/Makefile <target>
#
# Targets:
#   make sim        - build & run the Verilator simulation
#   make build      - compile the Verilator model only
#   make run        - run a previously built model
#   make trace      - run with VCD tracing (waves/top_sim.vcd)
#   make lint       - Verilator lint-only pass (no build)
#   make clean
#
# Requires: verilator (>= 4) and g++. The verilator-python wheel provides
# `verilator` on site-packages/verilator/bin (added to PATH below if missing).

# repo root = parent of this Makefile's directory
ROOT    := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../..)
VDIR    := $(ROOT)/old/v10.8.2
SDIR    := $(ROOT)/sim/v1082
BUILD   := $(SDIR)/build
WAVES   := $(SDIR)/waves
TOP     := TOP_SYS_sim
VERILATOR ?= verilator

# --- v10.8.2 core + memory system (32-bit AXI) --------------------------
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
	$(VDIR)/mem_deco.v

# --- peripheral hub + sub-devices (notech cells for the uart netlist) ---
PERIPH_V := \
	$(VDIR)/periph.v \
	$(VDIR)/uart_16750.v \
	$(ROOT)/sim/notech_cells.v \
	$(VDIR)/v8259.v \
	$(VDIR)/v8253.v \
	$(VDIR)/v8253_counter.v \
	$(VDIR)/v8042_stub.v \
	$(VDIR)/tiny_spi.v

# --- simulation-only functional models ---------------------------------
SIM_V := \
	$(SDIR)/axi_mem32.v \
	$(SDIR)/TOP_SYS_sim.v

ALL_V := $(CORE_V) $(PERIPH_V) $(SIM_V)

LOW_HEX  ?= $(BUILD)/kernel.hex
HIGH_HEX ?= $(BUILD)/boot_v1082.hex
KERNEL   ?= $(VDIR)/bin2v.bin

VL_FLAGS := --Wall -Wno-WIDTH -Wno-UNUSED -Wno-UNOPTFLAT -Wno-CASEX \
            -Wno-CASEINCOMPLETE -Wno-PINMISSING -Wno-PINNOCONNECT -Wno-PINNOTFOUND \
            -Wno-IMPLICIT -Wno-COMBDLY -Wno-UNDRIVEN -Wno-BLKANDNBLK \
            -Wno-DECLFILENAME -Wno-UNOPT -Wno-LATCH -Wno-WIDTHCONCAT \
            -Wno-CASEOVERLAP -Wno-REALCVT -Wno-INITIALDLY -Wno-TIMESCALEMOD \
            -Wno-fatal --trace --top-module $(TOP) \
            -DLOW_HEX=\"$(LOW_HEX)\" -DHIGH_HEX=\"$(HIGH_HEX)\"

TB_CPP := $(SDIR)/tb_top_sim.cpp
EXE    := $(BUILD)/V$(TOP)
MAX_CYC ?= 300000
IMG_PY  := $(SDIR)/mk_boot_image_v1082.py

.PHONY: sim build run trace lint clean images

images: $(LOW_HEX) $(HIGH_HEX)
$(LOW_HEX) $(HIGH_HEX): $(IMG_PY) $(KERNEL)
	@mkdir -p $(BUILD)
	python3 $(IMG_PY) --kernel $(KERNEL) --outdir $(BUILD)

sim: build
	@mkdir -p $(WAVES)
	$(EXE) --cycles $(MAX_CYC)

trace: build
	@mkdir -p $(WAVES)
	$(EXE) --cycles $(MAX_CYC) --trace

build: $(EXE)
$(EXE): $(ALL_V) $(TB_CPP) $(LOW_HEX) $(HIGH_HEX)
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
	@mkdir -p $(WAVES)
	$(EXE) --cycles $(MAX_CYC)

lint:
	@mkdir -p $(BUILD)
	$(VERILATOR) --lint-only $(VL_FLAGS) -Mdir $(BUILD) $(ALL_V)

clean:
	rm -rf $(BUILD) $(WAVES)
