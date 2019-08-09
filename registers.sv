`ifndef _registers_sv_
`define _registers_sv_

`default_nettype none

`include "z80.vh"

// registers stores the A, B, C, D, E, H, L, IX, IY, SP, and Flags
// registers. You can read any two registers or register pairs
// at a time, and write one of them. Flags are always output.
module registers(
    input logic reset,
    input logic clk,

    // What to write. Writes on the next positive edge of the clock.
    input logic write_en,
    input logic `reg_select dest,
    input logic [15:0] in,

    // What to read (2 busses)
    input logic `reg_select src1,
    output logic [15:0] out1,

    input logic `reg_select src2,
    output logic [15:0] out2,

    // Flags are always output, and may be
    // written to. This is ignored if writing
    // to AF.
    output logic [7:0] reg_f,
    input logic [7:0] f_in,
    input logic f_wr,

    // DE <- DE + 1, HL <- HL + 1, BC <- BC - 1
    // overrides any other write, except block_dec.
    input logic block_inc,

    // DE <- DE - 1, HL <- HL - 1, BC <- BC - 1
    // overrides any other write, including block_inc.
    input logic block_dec

`ifdef Z80_FORMAL
    ,
    `Z80_REGS_OUTPUTS
`endif
);

logic [15:0] _af;
logic [15:0] _bc;
logic [15:0] _de;
logic [15:0] _hl;

logic [15:0] _af2;
logic [15:0] _bc2;
logic [15:0] _de2;
logic [15:0] _hl2;

logic [15:0] _ix;
logic [15:0] _iy;
logic [15:0] _sp;

logic [15:0] next_af;
logic [15:0] next_bc;
logic [15:0] next_de;
logic [15:0] next_hl;

logic [15:0] next_af2;
logic [15:0] next_bc2;
logic [15:0] next_de2;
logic [15:0] next_hl2;

logic [15:0] next_ix;
logic [15:0] next_iy;
logic [15:0] next_sp;


`ifdef Z80_FORMAL
  assign z80_reg_a = _af[15:8];
  assign z80_reg_f = _af[7:0];
  assign z80_reg_b = _bc[15:8];
  assign z80_reg_c = _bc[7:0];
  assign z80_reg_d = _de[15:8];
  assign z80_reg_e = _de[7:0];
  assign z80_reg_h = _hl[15:8];
  assign z80_reg_l = _hl[7:0];
  assign z80_reg_a2 = _af2[15:8];
  assign z80_reg_f2 = _af2[7:0];
  assign z80_reg_b2 = _bc2[15:8];
  assign z80_reg_c2 = _bc2[7:0];
  assign z80_reg_d2 = _de2[15:8];
  assign z80_reg_e2 = _de2[7:0];
  assign z80_reg_h2 = _hl2[15:8];
  assign z80_reg_l2 = _hl2[7:0];
  assign z80_reg_ix = _ix;
  assign z80_reg_iy = _iy;
  assign z80_reg_sp = _sp;
`endif // Z80_FORMAL

logic f_wr2;
assign f_wr2 = f_wr && !block_inc && !block_dec;
assign reg_f = _af[7:0];

logic write_en2;
assign write_en2 = write_en && !block_inc && !block_dec;

always @(*) begin
    out1[15:0] = 0;
    out2[15:0] = 0;
    case (src1)
      `REG_A: out1[7:0] = _af[15:8];
      `REG_B: out1[7:0] = _bc[15:8];
      `REG_C: out1[7:0] = _bc[7:0];
      `REG_D: out1[7:0] = _de[15:8];
      `REG_E: out1[7:0] = _de[7:0];
      `REG_H: out1[7:0] = _hl[15:8];
      `REG_L: out1[7:0] = _hl[7:0];
      `REG_BC: out1[15:0] = _bc;
      `REG_DE: out1[15:0] = _de;
      `REG_HL: out1[15:0] = _hl;
      `REG_IX: out1[15:0] = _ix;
      `REG_IY: out1[15:0] = _iy;
      `REG_SP: out1[15:0] = _sp;
    endcase
    case (src2)
      `REG_A: out2[7:0] = _af[15:8];
      `REG_B: out2[7:0] = _bc[15:8];
      `REG_C: out2[7:0] = _bc[7:0];
      `REG_D: out2[7:0] = _de[15:8];
      `REG_E: out2[7:0] = _de[7:0];
      `REG_H: out2[7:0] = _hl[15:8];
      `REG_L: out2[7:0] = _hl[7:0];
      `REG_BC: out2[15:0] = _bc;
      `REG_DE: out2[15:0] = _de;
      `REG_HL: out2[15:0] = _hl;
      `REG_IX: out2[15:0] = _ix;
      `REG_IY: out2[15:0] = _iy;
      `REG_SP: out2[15:0] = _sp;
    endcase
end

always @(posedge clk or posedge reset) begin
  if (reset) begin
    _af <= 0;
    _bc <= 0;
    _de <= 0;
    _hl <= 0;
    _af2 <= 0;
    _bc2 <= 0;
    _de2 <= 0;
    _hl2 <= 0;
    _ix <= 0;
    _iy <= 0;
    _sp <= 0;
  end else begin
    if (f_wr2) begin
      _af[7:0] <= f_in;
    end
    if (write_en2) begin
      case (dest)
        `REG_A: _af[15:8] <= in[7:0];
        `REG_B: _bc[15:8] <= in[7:0];
        `REG_C: _bc[7:0] <= in[7:0];
        `REG_D: _de[15:8] <= in[7:0];
        `REG_E: _de[7:0] <= in[7:0];
        `REG_H: _hl[15:8] <= in[7:0];
        `REG_L: _hl[7:0] <= in[7:0];
        `REG_BC: _bc <= in;
        `REG_DE: _de <= in;
        `REG_HL: _hl <= in;
        `REG_IX: _ix <= in;
        `REG_IY: _iy <= in;
        `REG_SP: _sp <= in;
      endcase
    end else if (block_inc) begin
      _de <= _de + 16'b1;
      _hl <= _hl + 16'b1;
      _bc <= _bc - 16'b1;
      _af[7:0] <= (_af[7:0] & `FLAG_H_MASK & `FLAG_N_MASK & `FLAG_PV_MASK) |
        (_bc - 16'b1 == 16'b0 ? 0 : `FLAG_PV_BIT);
    end else if (block_dec) begin
      _de <= _de - 16'b1;
      _hl <= _hl - 16'b1;
      _bc <= _bc - 16'b1;
      _af[7:0] <= (_af[7:0] & `FLAG_H_MASK & `FLAG_N_MASK & `FLAG_PV_MASK) |
        (_bc - 16'b1 == 16'b0 ? 0 : `FLAG_PV_BIT);
    end
  end
end

`ifdef REGISTERS_FORMAL
initial assume(reset);

logic past_valid;
initial	past_valid = 0;
always @(posedge clk) past_valid <= 1;

function is_8bit(input `reg_select x);
  is_8bit = (x <= 7 && x != 6);
endfunction

function is_16bit(input `reg_select x);
  is_16bit = (x >= `REG_FIRST16 && x <= `REG_LAST16);
endfunction

always @(posedge clk) begin
  // Don't do any checking unless we have 3 cycles.
  if (past_valid && $past(past_valid)) begin
    // Ensure the past 2 cycles had no reset.
    assume(!reset && $past(!reset));

    // Check 8-bit register writes and reads from src1 and src2.
    if ($past(write_en2) && $past(dest) == src1 && is_8bit(src1))
      assert(out1[7:0] == $past(in[7:0]));
    if ($past(write_en2) && $past(dest) == src2 && is_8bit(src2))
      assert(out2[7:0] == $past(in[7:0]));

    // Check 16-bit register writes and reads from src1 and src2.
    if ($past(write_en2) && $past(dest) == src1 && is_16bit(src1))
      assert(out1[15:0] == $past(in[15:0]));
    if ($past(write_en2) && $past(dest) == src2 && is_16bit(src2))
      assert(out2[15:0] == $past(in[15:0]));

    // Check writing flags.
    if ($past(f_wr2))
      assert(reg_f == $past(f_in));

    // Check block increment
    if (!write_en && !f_wr && !block_dec && $past(!write_en && !f_wr && !block_dec) && $fell(block_inc)) begin
      assert(_de == $past(_de) + 16'b1);
      assert(_hl == $past(_hl) + 16'b1);
      assert(_bc == $past(_bc) - 16'b1);
      assert($stable(reg_f & `FLAG_S_BIT));
      assert($stable(reg_f & `FLAG_Z_BIT));
      assert($stable(reg_f & `FLAG_5_BIT));
      assert((reg_f & `FLAG_H_BIT) == 0);
      assert($stable(reg_f & `FLAG_3_BIT));
      assert((reg_f & `FLAG_PV_BIT) == (_bc == 16'b0 ? 0 : `FLAG_PV_BIT));
      assert((reg_f & `FLAG_N_BIT) == 0);
      assert($stable(reg_f & `FLAG_C_BIT));
    end

    // Check block decrement
    if (!write_en && !f_wr && !block_inc && $past(!write_en && !f_wr && !block_inc) && $fell(block_dec)) begin
      assert(_de == $past(_de) - 16'b1);
      assert(_hl == $past(_hl) - 16'b1);
      assert(_bc == $past(_bc) - 16'b1);
      assert($stable(reg_f & `FLAG_S_BIT));
      assert($stable(reg_f & `FLAG_Z_BIT));
      assert($stable(reg_f & `FLAG_5_BIT));
      assert((reg_f & `FLAG_H_BIT) == 0);
      assert($stable(reg_f & `FLAG_3_BIT));
      assert((reg_f & `FLAG_PV_BIT) == (_bc == 16'b0 ? 0 : `FLAG_PV_BIT));
      assert((reg_f & `FLAG_N_BIT) == 0);
      assert($stable(reg_f & `FLAG_C_BIT));
    end

  end
  cover(_bc == 16'h1234 && _ix == 16'h1234 && out1[15:0] == 16'h5678 && out2[15:0] == 16'h0098);
  cover($past(_af) == 16'hFFFF && reg_f == 0 && $past(f_wr2));
end
`endif

endmodule

`endif  // _registers_sv_
