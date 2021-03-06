`ifndef _mcycle_sv_
`define _mcycle_sv_

`default_nettype none

`include "z80.vh"
`include "m1.sv"
`include "mrd_wr_mem.sv"
`include "mrd_wr_io.sv"

// mcycle outputs signals for whichever cycle is currently active. It
// also starts up the given cycle when the previous cycle is complete.
module mcycle(
    input logic clk,
    input logic reset,
    input logic [15:0] pc,
    input logic [15:0] refresh_addr,
    input logic [7:0] D_in,
    input logic [7:0] wdata,
    input logic rd,
    input logic wr,
    input logic nWAIT,
    input logic [2:0] cycle,
    // Before the cycle is done, if extend_cycle is high, add a
    // tcycle.
    input logic extend_cycle,

    output logic [15:0] A,
    output logic nMREQ,
    output logic nIORQ,
    output logic nRD,
    output logic nWR,
    output logic nM1,
    output logic nRFSH,
    output logic [7:0] D_out,
    output logic data_out_en,
    output logic [7:0] rdata,
    output logic [2:0] _mcycle,
    output logic [2:0] tcycle,
    // if the mcycle would have been done, but the sequencer requested
    // the cycle to be extended, this signal goes high at what would have
    // been the end of the mcycle.
    output logic extra_tcycle,
    // This goes high when a memory or I/O access has been waitstated by
    // nWAIT. It's only used during formal verification to inhibit counting
    // of tcycles.
    output logic waitstated,
    output logic done
);

logic m1_active;
assign m1_active = tcycle_m1 != 0;

logic mrd_wr_mem_active;
assign mrd_wr_mem_active = tcycle_mrd_wr_mem != 0;

logic mrd_wr_io_active;
assign mrd_wr_io_active = tcycle_mrd_wr_io != 0;

logic [2:0] tcycle_internal;
logic done_internal;
logic minternal_active;
assign minternal_active = tcycle_internal != 0;
logic [2:0] minternal_tcycles;

logic [2:0] tcycle_extended;
logic done_extended;
logic mextended_active;
assign mextended_active = tcycle_extended != 0;

assign _mcycle = m1_active ? `CYCLE_M1 :
            mrd_wr_mem_active ? `CYCLE_RDWR_MEM :
            mrd_wr_io_active ? `CYCLE_RDWR_IO :
            minternal_active ? `CYCLE_INTERNAL :
            mextended_active ? `CYCLE_EXTENDED :
                `CYCLE_NONE;

assign A = m1_active ? A_m1 :
            mrd_wr_mem_active ? A_mrd_wr_mem :
            mrd_wr_io_active ? A_mrd_wr_io :
            0;

assign nMREQ = m1_active ? nMREQ_m1 :
                mrd_wr_mem_active ? nMREQ_mrd_wr_mem :
                mrd_wr_io_active ? 1 :
                1;

assign nIORQ = m1_active ? 1 :
                mrd_wr_mem_active ? 1 :
                mrd_wr_io_active ? nIORQ_mrd_wr_io :
                1;

assign nRD = m1_active ? nRD_m1 :
                mrd_wr_mem_active ? nRD_mrd_wr_mem :
                mrd_wr_io_active ? nRD_mrd_wr_io :
                1;

assign nWR = m1_active ? 1 :
                mrd_wr_mem_active ? nWR_mrd_wr_mem :
                mrd_wr_io_active ? nWR_mrd_wr_io :
                1;

assign nM1 = m1_active ? nM1_m1 :
                mrd_wr_mem_active ? 1 :
                mrd_wr_io_active ? 1 :
                1;

assign nRFSH = m1_active ? nRFSH_m1 :
                mrd_wr_mem_active ? 1 :
                mrd_wr_io_active ? 1 :
                1;

assign D_out = m1_active ? 0 :
                mrd_wr_mem_active ? D_out_mrd_wr_mem :
                mrd_wr_io_active ? D_out_mrd_wr_io :
                0;

assign data_out_en = m1_active ? 0 :
                mrd_wr_mem_active ? data_out_en_mrd_wr_mem :
                mrd_wr_io_active ? data_out_en_mrd_wr_io :
                0;

assign rdata = m1_active ? rdata_m1 :
                mrd_wr_mem_active ? rdata_mrd_wr_mem :
                mrd_wr_io_active ? rdata_mrd_wr_io :
                0;

assign tcycle = m1_active ? tcycle_m1 :
                mrd_wr_mem_active ? tcycle_mrd_wr_mem :
                mrd_wr_io_active ? tcycle_mrd_wr_io :
                minternal_active ? tcycle_internal :
                mextended_active ? tcycle_extended :
                0;

assign extra_tcycle = m1_active ? extra_tcycle_m1 :
                mrd_wr_mem_active ? extra_tcycle_mrd_wr_mem :
                minternal_active ? extra_tcycle_internal :
                0;

assign waitstated = m1_active ? waitstated_m1 :
                mrd_wr_mem_active ? waitstated_mrd_wr_mem :
                mrd_wr_io_active ? waitstated_mrd_wr_io :
                0;

assign done = !extend_cycle && (m1_active ? done_m1 :
                mrd_wr_mem_active ? done_mrd_wr_mem :
                mrd_wr_io_active ? done_mrd_wr_io :
                minternal_active ? done_internal :
                mextended_active ? done_extended :
                1);

logic activate_internal;
assign activate_internal = done && (cycle == `CYCLE_INTERNAL);
logic extra_tcycle_internal;
assign extra_tcycle_internal = extend_cycle;

always @(posedge clk) begin
    if (reset) begin
        tcycle_internal <= 0;  // inactive

    end else begin
      if (tcycle_internal == 0) begin
        if (activate_internal) tcycle_internal <= 1;

      end else begin
        if (extend_cycle) tcycle_internal <= tcycle_internal + 1;
        else if (activate_internal) tcycle_internal <= 1;
        else tcycle_internal <= 0;
      end
    end
end

always @(*) begin
    if (reset) done_internal = 0;
    else done_internal = (tcycle_internal != 0 && !extend_cycle);
end

logic activate_extended;
assign activate_extended = done && cycle == `CYCLE_EXTENDED;

always @(posedge clk) begin
    if (reset) begin
        tcycle_extended <= 0;  // inactive
    end else begin
        case (tcycle_extended)
            0: tcycle_extended <= activate_extended ? 1 : 0;
            1: tcycle_extended <= activate_extended ? 1 : 0;
            default: tcycle_extended <= 0;
        endcase
    end
end

always @(*) begin
    if (reset) done_extended = 0;
    else done_extended = (tcycle == 1);
end

logic [15:0] A_m1;
logic nMREQ_m1;
logic nRD_m1;
logic nM1_m1;
logic nRFSH_m1;
logic [7:0] rdata_m1;
logic [2:0] tcycle_m1;
logic extra_tcycle_m1;
logic waitstated_m1;
logic done_m1;

m1 m1(
    .clk(clk),
    .reset(reset),
    .activate(done && cycle == `CYCLE_M1),
    .pc(pc),
    .refresh_addr(refresh_addr),
    .D(D_in),
    .nWAIT(nWAIT),
    .extend_cycle(extend_cycle),

    .A(A_m1),
    .nMREQ(nMREQ_m1),
    .nRD(nRD_m1),
    .nM1(nM1_m1),
    .nRFSH(nRFSH_m1),
    .rdata(rdata_m1),
    .tcycle(tcycle_m1),
    .extra_tcycle(extra_tcycle_m1),
    .waitstated(waitstated_m1),
    .done(done_m1)
);

logic [15:0] A_mrd_wr_mem;
logic nMREQ_mrd_wr_mem;
logic nRD_mrd_wr_mem;
logic nWR_mrd_wr_mem;
logic [7:0] D_out_mrd_wr_mem;
logic data_out_en_mrd_wr_mem;
logic [7:0] rdata_mrd_wr_mem;
logic [2:0] tcycle_mrd_wr_mem;
logic extra_tcycle_mrd_wr_mem;
logic waitstated_mrd_wr_mem;
logic done_mrd_wr_mem;

mrd_wr_mem mrd_wr_mem(
    .clk(clk),
    .reset(reset),
    .activate(done && cycle == `CYCLE_RDWR_MEM),
    .pc(pc),
    .D_in(D_in),
    .wdata(wdata),
    .rd(rd),
    .wr(wr),
    .nWAIT(nWAIT),
    .extend_cycle(extend_cycle),

    .A(A_mrd_wr_mem),
    .nMREQ(nMREQ_mrd_wr_mem),
    .nRD(nRD_mrd_wr_mem),
    .nWR(nWR_mrd_wr_mem),
    .D_out(D_out_mrd_wr_mem),
    .data_out_en(data_out_en_mrd_wr_mem),
    .rdata(rdata_mrd_wr_mem),
    .tcycle(tcycle_mrd_wr_mem),
    .done(done_mrd_wr_mem),
    .extra_tcycle(extra_tcycle_mrd_wr_mem),
    .waitstated(waitstated_mrd_wr_mem)
);

logic [15:0] A_mrd_wr_io;
logic nIORQ_mrd_wr_io;
logic nRD_mrd_wr_io;
logic nWR_mrd_wr_io;
logic [7:0] D_out_mrd_wr_io;
logic data_out_en_mrd_wr_io;
logic [7:0] rdata_mrd_wr_io;
logic [2:0] tcycle_mrd_wr_io;
logic waitstated_mrd_wr_io;
logic done_mrd_wr_io;

mrd_wr_io mrd_wr_io(
    .clk(clk),
    .reset(reset),
    .activate(done && cycle == `CYCLE_RDWR_IO),
    .pc(pc),
    .D_in(D_in),
    .wdata(wdata),
    .rd(rd),
    .wr(wr),
    .nWAIT(nWAIT),

    .A(A_mrd_wr_io),
    .nIORQ(nIORQ_mrd_wr_io),
    .nRD(nRD_mrd_wr_io),
    .nWR(nWR_mrd_wr_io),
    .D_out(D_out_mrd_wr_io),
    .data_out_en(data_out_en_mrd_wr_io),
    .rdata(rdata_mrd_wr_io),
    .tcycle(tcycle_mrd_wr_io),
    .waitstated(waitstated_mrd_wr_io),
    .done(done_mrd_wr_io)
);

endmodule

`endif // _mcycle_sv_