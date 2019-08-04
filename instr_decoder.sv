`ifndef _instr_decoder_vh_
`define _instr_decoder_vh_

`default_nettype none
`timescale 1us/100 ns

`include "z80.vh"

module instr_decoder(
    input logic [15:0] instr,
    input logic [1:0] instr_len,
    output logic [7:0] group
);

always @(*) begin
    if (instr_len == 0) group <= `INSN_GROUP_NEED_MORE_BYTES;
    else if (instr_len == 1) begin
        case (instr[7:0])
            8'h01, 8'h11, 8'h21, 8'h31:
                group <= `INSN_GROUP_LD_DD_IMMED;
            8'h02, 8'h12:
                group <= `INSN_GROUP_LD_BCDE_A;
            8'h0A, 8'h1A:
                group <= `INSN_GROUP_LD_A_BCDE;
            8'h06, 8'h0E, 8'h16, 8'h1E, 8'h26, 8'h2E, 8'h3E:
                group <= `INSN_GROUP_LD_REG_IMMED;
            8'h22:
                group <= `INSN_GROUP_LD_EXTADDR_HL;
            8'h2A:
                group <= `INSN_GROUP_LD_HL_EXTADDR;
            8'h36:
                group <= `INSN_GROUP_LD_HL_IMMED;
            8'h7F, 8'h78, 8'h79, 8'h7A, 8'h7B, 8'h7C, 8'h7D,
            8'h47, 8'h40, 8'h41, 8'h42, 8'h43, 8'h44, 8'h45,
            8'h4F, 8'h48, 8'h49, 8'h4A, 8'h4B, 8'h4C, 8'h4D,
            8'h57, 8'h50, 8'h51, 8'h52, 8'h53, 8'h54, 8'h55,
            8'h5F, 8'h58, 8'h59, 8'h5A, 8'h5B, 8'h5C, 8'h5D,
            8'h67, 8'h60, 8'h61, 8'h62, 8'h63, 8'h64, 8'h65,
            8'h6F, 8'h68, 8'h69, 8'h6A, 8'h6B, 8'h6C, 8'h6D:
                group <= `INSN_GROUP_LD_REG_REG;
            8'h32:
                group <= `INSN_GROUP_LD_EXTADDR_A;
            8'h3A:
                group <= `INSN_GROUP_LD_A_EXTADDR;
            8'h70, 8'h71, 8'h72, 8'h73, 8'h74, 8'h75, 8'h77:
                group <= `INSN_GROUP_LD_HL_REG;
            8'hCB, 8'hDD, 8'hED, 8'hFD:
                group <= `INSN_GROUP_NEED_MORE_BYTES;
            default:
                group <= `INSN_GROUP_ILLEGAL_INSTR;
        endcase
    end else begin
        case (instr[15:0])
            16'h4BED, 16'h5BED, 16'h6BED, 16'h7BED:
                group <= `INSN_GROUP_LD_DD_EXTADDR;
            16'h43ED, 16'h53ED, 16'h63ED, 16'h73ED:
                group <= `INSN_GROUP_LD_EXTADDR_DD;
            16'h46DD, 16'h4EDD, 16'h56DD, 16'h5EDD,
            16'h66DD, 16'h6EDD, 16'h7EDD,
            16'h46FD, 16'h4EFD, 16'h56FD, 16'h5EFD,
            16'h66FD, 16'h6EFD, 16'h7EFD:
                group <= `INSN_GROUP_LD_REG_IXIY;
            16'h70DD, 16'h71DD, 16'h72DD, 16'h73DD,
            16'h74DD, 16'h75DD, 16'h77DD,
            16'h70FD, 16'h71FD, 16'h72FD, 16'h73FD,
            16'h74FD, 16'h75FD, 16'h77FD:
                group <= `INSN_GROUP_LD_IXIY_REG;
            16'h21DD, 16'h21FD:
                group <= `INSN_GROUP_LD_IXIY_NN;
            16'h2ADD, 16'h2AFD:
                group <= `INSN_GROUP_LD_IXIY_MM;
            16'h36DD, 16'h36FD:
                group <= `INSN_GROUP_LD_IXIY_IMMED;
            16'h22DD, 16'h22FD:
                group <= `INSN_GROUP_LD_EXTADDR_IXIY;
            16'h47ED:
                group <= `INSN_GROUP_LD_I_A;
            16'h57ED:
                group <= `INSN_GROUP_LD_A_I;
            16'h5FED:
                group <= `INSN_GROUP_LD_A_R;
            default:
                group <= `INSN_GROUP_ILLEGAL_INSTR;
        endcase
    end
end

endmodule

`endif // _instr_decoder_vh_
