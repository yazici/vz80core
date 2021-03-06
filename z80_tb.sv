// Run with:
//           iverilog -g2012 -Iz80fi -o z80_tb z80_tb.sv
//           vvp z80_tb
//           gtkwave z80_tb.vcd

`define Z80_FORMAL
`include "z80.sv"
`include "z80fi_insn_spec_ld_reg_idx_ixiy.sv"

`default_nettype none
`timescale 1us/1us

module z80_tb(
`ifdef Z80_FORMAL
  `Z80FI_OUTPUTS
`endif
);

logic nRESET;
logic CLK;
logic nWAIT;
logic nBUSRQ;
logic [7:0] READ_D;

logic nMREQ;
logic nIORQ;
logic nRD;
logic nWR;
logic nM1;
logic nRFSH;
logic nBUSAK;
logic [15:0] A;
logic [7:0] WRITE_D;

logic reset;
assign reset = !nRESET;

z80 z80(
    .nRESET(nRESET),
    .CLK(CLK),
    .nWAIT(nWAIT),
    .nBUSRQ(nBUSRQ),
    .READ_D(READ_D),

    .nMREQ(nMREQ),
    .nIORQ(nIORQ),
    .nRD(nRD),
    .nWR(nWR),
    .nM1(nM1),
    .nRFSH(nRFSH),
    .nBUSAK(nBUSAK),
    .A(A),
    .WRITE_D(WRITE_D)

`ifdef Z80_FORMAL
    ,
    `Z80FI_CONN
`endif
);

`ifdef Z80_FORMAL
`Z80FI_SPEC_WIRES

z80fi_insn_spec_ld_reg_idx_ixiy insn_spec(
    `Z80FI_SPEC_CONNS
);
`endif


always #1 CLK=~CLK;

always @(*) begin
    case (A)
        0: READ_D = 8'h00;   // NOP
        1: READ_D = 8'hDD;   // LD B, (IX+5F)
        2: READ_D = 8'h46;
        3: READ_D = 8'h5F;
        4: READ_D = 8'hED;   // LD A, R
        5: READ_D = 8'h5F;
        6: READ_D = 8'hF9;   // LD SP, HL
        7: READ_D = 8'hE3;   // EX (SP), HL
        8: READ_D = 8'h00;   // NOP
        9: READ_D = 8'hED;   // NEG
        10: READ_D = 8'h44;
        11: READ_D = 8'hED;  // IN C, (C)
        12: READ_D = 8'h48;
        13: READ_D = 8'h2A;  // LD HL, (0x1234)
        14: READ_D = 8'h34;
        15: READ_D = 8'h12;
        16: READ_D = 8'hC9;  // RET
        17: READ_D = 8'h00;  // NOP
        18: READ_D = 8'h00;  // NOP
        19: READ_D = 8'h00;  // NOP
        20: READ_D = 8'h00;  // NOP
        default: READ_D = 8'hFF;
    endcase
end

initial begin
    $dumpfile("z80_tb.vcd");
    $dumpvars;
    nRESET = 0;
    CLK = 0;
    nWAIT = 1;
    nBUSRQ = 1;

    #5
    nRESET = 1;

    #36
    nBUSRQ = 0;

    #10
    nBUSRQ = 1;

    #180
    $finish;
end

endmodule
