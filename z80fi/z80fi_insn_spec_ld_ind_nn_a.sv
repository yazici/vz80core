// LD (nn), A
//
// This must read register A and write its value to
// memory location nn. nn is ordered little-endian.

`default_nettype none

`include "z80.vh"
`include "z80fi.vh"

module z80fi_insn_spec_ld_ind_nn_a(
    `Z80FI_INSN_SPEC_IO
);

wire [15:0] addr = z80fi_insn[23:8];

assign spec_valid = z80fi_valid &&
    z80fi_insn_len == 3 &&
    z80fi_insn[7:0] == 8'b00110010;

`Z80FI_SPEC_SIGNALS
assign spec_signals = `SPEC_REG_IP | `SPEC_MEM_WR;

assign spec_bus_waddr = addr;
assign spec_bus_wdata = z80fi_reg_a_in;

assign spec_reg_ip_out = z80fi_reg_ip_in + 3;

assign spec_mcycle_type1 = `CYCLE_M1;
assign spec_mcycle_type2 = `CYCLE_RDWR_MEM;
assign spec_mcycle_type3 = `CYCLE_RDWR_MEM;
assign spec_mcycle_type4 = `CYCLE_RDWR_MEM;
assign spec_mcycle_type5 = `CYCLE_NONE;

assign spec_tcycles1 = 4;
assign spec_tcycles2 = 3;
assign spec_tcycles3 = 3;
assign spec_tcycles4 = 3;

endmodule