//==========================================================================
//  notech_cells.v
//
//  Generic behavioural models of the "notech_*" standard-cell library used
//  by the gate-level netlist in old/v14.0/uart_16750.v. The original design
//  was synthesised against a vendor cell library whose Verilog models were
//  not checked in; these are functional equivalents sufficient for
//  simulation under Verilator / Icarus. Port names match the netlist
//  (.A/.B/.C/.D/.S/.S0/.S1/.D/.CP/.CD/.CI/.CO/.Z/.Q).
//
//  SIMULATION ONLY -- these are behavioural, not the real timing-accurate
//  cells.
//==========================================================================
`timescale 1ns / 1ps

// positive-edge D flip-flop with async active-low clear
module notech_reg (input D, input CP, input CD, output reg Q);
    always @(posedge CP or negedge CD) begin
        if (~CD) Q <= 1'b0;
        else     Q <= D;
    end
endmodule

// positive-edge D flip-flop with async active-low set
module notech_reg_set (input D, input CP, input SD, output reg Q);
    always @(posedge CP or negedge SD) begin
        if (~SD) Q <= 1'b1;
        else     Q <= D;
    end
endmodule

module notech_inv  (input A, output Z); assign Z = ~A; endmodule
module notech_and2 (input A, input B, output Z); assign Z = A & B; endmodule
module notech_and3 (input A, input B, input C, output Z); assign Z = A & B & C; endmodule
module notech_and4 (input A, input B, input C, input D, output Z); assign Z = A & B & C & D; endmodule
module notech_nand2(input A, input B, output Z); assign Z = ~(A & B); endmodule
module notech_nand3(input A, input B, input C, output Z); assign Z = ~(A & B & C); endmodule
module notech_or2  (input A, input B, output Z); assign Z = A | B; endmodule
module notech_or4  (input A, input B, input C, input D, output Z); assign Z = A | B | C | D; endmodule
module notech_nor2 (input A, input B, output Z); assign Z = ~(A | B); endmodule
module notech_nor4 (input A, input B, input C, input D, output Z); assign Z = ~(A | B | C | D); endmodule
module notech_xor2 (input A, input B, output Z); assign Z = A ^ B; endmodule

// 2:1 mux: Z = S ? B : A
module notech_mux2 (input A, input B, input S, output Z); assign Z = S ? B : A; endmodule

// 4:1 mux: Z = S1 ? (S0 ? D : C) : (S0 ? B : A)
module notech_mux4 (input A, input B, input C, input D, input S0, input S1, output Z);
    assign Z = S1 ? (S0 ? D : C) : (S0 ? B : A);
endmodule

// AND-OR: ao3 Z = (A & B) | C
module notech_ao3  (input A, input B, input C, output Z); assign Z = (A & B) | C; endmodule
// AND-OR: ao4 Z = (A & B) | (C & D)
module notech_ao4  (input A, input B, input C, input D, output Z); assign Z = (A & B) | (C & D); endmodule

// AND-OR-INVERT: nao3 Z = ~((A & B) | C)
module notech_nao3 (input A, input B, input C, output Z); assign Z = ~((A & B) | C); endmodule
// AND-OR-INVERT: nao4 Z = ~((A & B) | (C & D))
module notech_nao4 (input A, input B, input C, input D, output Z); assign Z = ~((A & B) | (C & D)); endmodule

// half adder: Z = A ^ B (sum), CO = A & B (carry)
module notech_ha2  (input A, input B, output CO, output Z);
    assign Z  = A ^ B;
    assign CO = A & B;
endmodule

// full adder: Z = A ^ B ^ CI (sum), CO = carry out
module notech_fa2  (input A, input B, input CI, output CO, output Z);
    assign Z  = A ^ B ^ CI;
    assign CO = (A & B) | (CI & (A ^ B));
endmodule
