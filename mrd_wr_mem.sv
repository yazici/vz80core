`ifndef _mrd_wr_mem_sv_
`define _mrd_wr_mem_sv_

`default_nettype none

`include "z80.vh"
`include "edgelord.sv"

// mrd_wr_mem handles signal control for non-M1 memory read and write cycles.
module mrd_wr_mem(
    input logic clk,
    input logic reset,
    input logic activate,
    input logic [15:0] pc,
    input logic [7:0] D_in,
    input logic [7:0] wdata,
    input logic rd,
    input logic wr,
    input logic nWAIT,
    input logic extend_cycle,

    output logic [15:0] A,
    output logic nMREQ,
    output logic nRD,
    output logic nWR,
    output logic [7:0] D_out,
    output logic data_out_en,
    output logic [7:0] rdata,
    output logic [2:0] tcycle,
    output logic extra_tcycle,
    output logic waitstated,
    output logic done
);

assign A = pc;
assign D_out = wdata;

// Clones the clk without exposing clk to combinatorial logic.
logic clk_state;
edgelord edgelord(
    .clk(clk),
    .reset(reset),
    .clk_state(clk_state)
);

logic do_rd;
logic do_wr;

assign extra_tcycle = extend_cycle && (tcycle == 3 || tcycle == 4);

logic latched_nwait;
assign waitstated = (tcycle == 2 || tcycle == 7) && !latched_nwait;

always @(posedge clk) begin
    if (reset) begin
        tcycle <= 0;  // inactive
        do_rd <= 0;
        do_wr <= 0;
    end else begin
        case (tcycle)
            0: tcycle <= activate ? 1 : 0;
            1: tcycle <= 2;
            2: tcycle <= !latched_nwait ? 7 : 3; // 7 is Twait.
            7: tcycle <= !latched_nwait ? 7 : 3;
            default: tcycle <= extend_cycle ? 4 : (activate ? 1 : 0);
        endcase

        if (activate && (tcycle == 0 || tcycle == 3 || tcycle == 4)) begin
            do_rd <= rd;
            do_wr <= wr;
        end
    end
end

always @(negedge clk) begin
    if (reset) begin
        latched_nwait <= 1;
        rdata <= D_in;
    end else begin
        if (tcycle == 2 || tcycle == 7) latched_nwait <= nWAIT;
        if (tcycle == 3) rdata <= D_in;
    end
end

always @(*) begin
    case (tcycle)
        1: begin  // T1
            nMREQ = clk_state;
            nRD = do_rd ? clk_state : 1;
            nWR = 1;
            data_out_en = do_wr ? !clk_state : 0;
            done = 0;
        end
        2: begin  // T2
            nMREQ = 0;
            nRD = !do_rd;
            nWR = do_wr ? clk_state : 1;
            data_out_en = do_wr;
            done = 0;
        end
        3: begin  // T3
            nMREQ = !clk_state;
            nRD = do_rd ? !clk_state : 1;
            nWR = do_wr ? !clk_state : 1;
            data_out_en = do_wr ? clk_state : 0;
            done = ~clk_state;
        end
        4: begin  // any extended cycles
            nMREQ = 1;
            nRD = 1;
            nWR = 1;
            data_out_en = 0;
            done = 1;
        end
        7: begin  // Twait
            nMREQ = 0;
            nRD = !do_rd;
            nWR = !do_wr;
            data_out_en = do_wr;
            done = 0;
        end
        default: begin
            nMREQ = 1;
            nRD = 1;
            nWR = 1;
            data_out_en = 0;
            done = 0;
        end
    endcase

    if (reset) begin
        nMREQ = 1;
        nRD = 1;
        nWR = 1;
        data_out_en = 0;
        done = 0;
    end
end

`ifdef MCYCLE_FORMAL

reg do_reset;

`ifdef YOSYS
	assume property (do_reset == $initstate);
`endif

reg [7:0] cycle_reg = 0;
wire [7:0] cycle = do_reset ? 0 : cycle_reg;
// (* gclk *) reg formal_timestep;

// always @(posedge formal_timestep)
//     assume (clk == !$past(clk));

always @(posedge clk) begin
    cycle_reg <= do_reset ? 1 : cycle_reg + (cycle_reg != 255);
end

reg did_read = 0;
reg did_write = 0;

always @(posedge clk) begin
    if (!nRD) did_read <= 1;
    if (!nWR) did_write <= 1;
end

always @(*) begin
    assume(reset == cycle < 4);
    assume(activate == (cycle == 5 && !clk));
    assume(!(rd && wr)); // rd and wr should be mutually exclusive
    if (activate) assume(rd || wr); // We want to test either read or write cycle.

    assert(!(!nRD && data_out_en)); // We cannot have nRD=0 with data_out_en=1.
    assert(!(!nRD && !nWR)); // We cannot have nRD=0 with nWR=0.
    if (!nWR || !nRD) assert(!nMREQ);
    if (nMREQ) assert(nWR && nRD);
    if (!nWR) assert(data_out_en);
    if (data_out_en) assert(D_out == wdata);

    // Ensure nWAIT for read and write works
    cover(cycle == 20 && done && did_read);
    cover(cycle == 20 && done && did_write);
end

`endif // MCYCLE_FORMAL

endmodule

`endif // _mrd_wr_mem_sv_