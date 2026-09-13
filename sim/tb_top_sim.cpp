//==========================================================================
//  tb_top_sim.cpp  --  Verilator C++ testbench for TOP_SYS_sim
//
//  Generates a 100 MHz clock, holds the CPU in reset for a short time,
//  then releases it and lets the platform run for --cycles cycles
//  (default 200000). Prints EIP milestones, the v586 debug[4:0] port and
//  UART TXD transitions so you can watch the boot progress.
//
//  Options:
//    --cycles N   run for N cycles
//    --trace     enable VCD tracing (waves/top_sim.vcd)
//    --verbose   per-cycle EIP/instruction trace (very chatty)
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
    bool       verbose = false;
    const char* trace_file = "waves/top_sim.vcd";

    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--cycles") && i + 1 < argc) {
            max_cycles = strtoull(argv[++i], nullptr, 10);
        } else if (!strcmp(argv[i], "--trace")) {
            trace = true;
        } else if (!strcmp(argv[i], "--verbose")) {
            verbose = true;
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

    dut->clk = 0;
    dut->rstn = 0;
    dut->RXD = 1;  // idle UART line

    for (int i = 0; i < 16; i++) {
        tick(dut);
        if (tfp) tfp->dump(sim_time);
    }
    dut->rstn = 1;

    vluint64_t cyc = 0;
    uint8_t   last_txd = 1;
    uint8_t   last_dbg = 0;
    uint32_t  last_eip = 0xffffffff;
    uint32_t  eip_changes = 0;
    uint32_t  high_seen = 0;          // reached 0xc0000000+ (paging on)
    vluint64_t stuck_from = 0;        // cycle EIP last changed
    while (cyc < max_cycles) {
        tick(dut);
        if (tfp) tfp->dump(sim_time);

        if (dut->TXD != last_txd) {
            printf("[t=%llu cyc=%llu] TXD %d->%d\n",
                   (unsigned long long)sim_time, (unsigned long long)cyc,
                   last_txd, dut->TXD);
            last_txd = dut->TXD;
        }
        if (dut->debug != last_dbg) {
            printf("[t=%llu cyc=%llu] debug=%02x  eip=%08x fetch=%08x\n",
                   (unsigned long long)sim_time, (unsigned long long)cyc,
                   dut->debug, dut->dbg_eip, dut->dbg_fetch_addr);
            last_dbg = dut->debug;
        }
        if (dut->dbg_eip != last_eip) {
            eip_changes++;
            stuck_from = cyc;
            if (dut->dbg_eip >= 0xc0000000) high_seen = 1;
            if (verbose || eip_changes <= 60 || (eip_changes % 50000 == 0)) {
                printf("[cyc=%llu #%u] EIP %08x -> %08x  ecx=%08x daddr=%08x pgf=%d\n",
                       (unsigned long long)cyc, eip_changes, last_eip,
                       dut->dbg_eip, dut->dbg_ecx, dut->dbg_Daddr,
                       dut->dbg_pg_fault);
            }
            last_eip = dut->dbg_eip;
        }

        cyc++;
        if (Verilated::gotFinish()) break;
    }

    printf("Simulation finished after %llu cycles (%llu ns)\n",
           (unsigned long long)cyc, (unsigned long long)sim_time);
    printf("Boot progress: %u EIP transitions, %s reached high kernel (0xc0000000+)\n",
           eip_changes, high_seen ? "DID" : "did NOT");
    printf("Final EIP=%08x (last moved at cyc=%llu, stuck for %llu cycles)\n",
           dut->dbg_eip, (unsigned long long)stuck_from,
           (unsigned long long)(cyc - stuck_from));

    if (tfp) { tfp->dump(sim_time); tfp->close(); }
    dut->final();
    delete dut;
    return 0;
}
