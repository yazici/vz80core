// INC/DEC (IX/IY + d)
//
// Increments or decrements the byte at the memory location in IX/IY + d.

`default_nettype none

`include "z80.vh"
`include "z80fi.vh"

module z80fi_insn_spec_inc_dec_idx_ixiy(
    `Z80FI_INSN_SPEC_IO
);

wire [15:0] d          = { {8{z80fi_insn[23]}}, z80fi_insn[23:16]};
wire [6:0] insn_fixed1 = z80fi_insn[15:9];
wire       inc         = z80fi_insn[8];
wire [1:0] insn_fixed2 = z80fi_insn[7:6];
wire       iy          = z80fi_insn[5];
wire [4:0] insn_fixed3 = z80fi_insn[4:0];

assign spec_valid = z80fi_valid &&
    z80fi_insn_len == 3 &&
    insn_fixed1 == 7'b0011010 &&
    insn_fixed2 == 2'b11 &&
    insn_fixed3 == 5'b11101;

`Z80FI_SPEC_SIGNALS
assign spec_signals = `SPEC_REG_IP | `SPEC_REG_F | `SPEC_MEM_RD | `SPEC_MEM_WR;

wire [7:0] operand = z80fi_mem_rdata;
wire [7:0] result = inc ? (operand + 8'b1) : (operand - 8'b1);

wire flag_s = result[7];
wire flag_z = (result == 8'b0);
wire flag_5 = (z80fi_reg_f_in & `FLAG_5_BIT) != 0;
wire flag_h = halfcarry8(operand, inc ? 8'b1 : ~8'b1, !inc);
wire flag_3 = (z80fi_reg_f_in & `FLAG_3_BIT) != 0;
wire flag_v = overflow8(operand, inc ? 8'b1 : ~8'b1, !inc);
wire flag_n = !inc;
wire flag_c = (z80fi_reg_f_in & `FLAG_C_BIT) != 0;

assign spec_mem_raddr = (iy ? z80fi_reg_iy_in : z80fi_reg_ix_in) + d;
assign spec_mem_waddr = (iy ? z80fi_reg_iy_in : z80fi_reg_ix_in) + d;
assign spec_mem_wdata = result;
assign spec_reg_f_out =
    {flag_s, flag_z, flag_5, flag_h, flag_3, flag_v, flag_n, flag_c};

assign spec_reg_ip_out = z80fi_reg_ip_in + 3;

endmodule