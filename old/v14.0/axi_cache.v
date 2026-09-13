//==========================================================================
//  axi_cache.v
//
//  Placeholder / hook for an AXI-side cache that was never wired up in the
//  v14.0 design. It is NOT instantiated anywhere in the SoC (the active
//  caches are the instruction cache in useq.v and the data-cache RAM
//  primitive "datacache" in biu32_axi.v). Kept here as a legal, synthesizable
//  empty module so it parses cleanly under Verilator / synthesis without
//  the "axi_cache (); endmodule" bare-identifier artefact.
//
//  If you later implement an AXI cache here, give it real ports and
//  instantiate it where needed.
//==========================================================================
module axi_cache (
    input  wire clk,
    input  wire rstn
);
    wire _unused = &{1'b0, clk, rstn};
endmodule
