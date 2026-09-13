//==========================================================================
//  tb_top_sim.cpp  --  Verilator C++ testbench for TOP_SYS_sim
//
//  Generates a 100 MHz clock, holds the CPU in reset for a short time,
//  then releases it and lets the platform run for --max-cycles cycles
//  (default 200_000). Prints the v586 debug[4:0] port and UART TXD
//  transitions so you can see whether the core is fetching/executing.
//
//  Build:  see ../Makefile  (make sim)
//==========================================================================
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VTOP_SYS_sim.h"

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>

static vluint64_t sim_time = 0;
static double      clk_period_ns = 10.0;  // 100 MHz

// tick: toggles clk and advances sim_time
static void tick(VTOP_SYS_sim* dut) {
    dut->clk = 0;
    dut->eval();
    sim_time += clk_period_ns / 2;
    dut->clk = 1;
    dut->eval();
    sim_time += clk_period_ns / 2;
}

int main(int argc, char** argv) {
    vluint64_t max_cycles = 200000;
    bool       trace = false;
    const char* trace_file = "waves/top_sim.vcd";

    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--cycles") && i + 1 < argc) {
            max_cycles = strtoull(argv[++i], nullptr, 10);
        } else if (!strcmp(argv[i], "--trace")) {
            trace = true;
        }
    }

    Verilated::commandArgs(argc, argv);
    VTOP_SYS_sim* dut = new VTOP_SYS_sim;

    VerilatedVcdC* tfp = nullptr;
    if (trace) {
        Verilated::traceEverOn(true);
        tfp = new VerilatedVcdC;
        dut->trace(tfp, 99);
        tfp->open(trace_file);
    }

    // initial inputs
    dut->clk = 0;
    dut->rstn = 0;
    dut->RXD = 1;  // idle UART line

    // reset for 16 cycles
    for (int i = 0; i < 16; i++) {
        tick(dut);
        if (tfp) tfp->dump(sim_time);
    }
    dut->rstn = 1;

    // run
    vluint64_t cyc = 0;
    uint8_t   last_txd = 1;
    uint8_t   last_dbg = 0;
    while (cyc < max_cycles) {
        tick(dut);
        if (tfp) tfp->dump(sim_time);

        if (dut->TXD != last_txd) {
            if (cyc % 10000 == 0 || dut->TXD == 0)
                printf("[t=%llu] TXD %d->%d\n",
                       (unsigned long long)sim_time, last_txd, dut->TXD);
            last_txd = dut->TXD;
        }
        if (dut->debug != last_dbg) {
            printf("[t=%llu cyc=%llu] debug=%02x\n",
                   (unsigned long long)sim_time,
                   (unsigned long long)cyc, dut->debug);
            last_dbg = dut->debug;
        }
        cyc++;

        if (Verilated::gotFinish()) break;
    }

    printf("Simulation finished after %llu cycles (%llu ns)\n",
           (unsigned long long)cyc, (unsigned long long)sim_time);

    if (tfp) { tfp->dump(sim_time); tfp->close(); }
    dut->final();
    delete dut;
    return 0;
}
