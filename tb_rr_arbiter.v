// tb_rr_arbiter.v
// Testbench for rr_arbiter.v
`timescale 1ns/1ps
module tb_rr_arbiter;
 
    reg        clk;
    reg        rst_n;
    reg  [3:0] req;
    wire [3:0] grant;
 
    // instantiate with small timeslice so simulation is fast
    parameter TB_TIMESLICE = 5;
 
    rr_arbiter #(.TIME_SLICE(TB_TIMESLICE)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .req(req),
        .grant(grant)
    );
 
    // clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100 MHz style -> 10ns period
    end
 
    // stimulus sequence
    initial begin
        // waveform dump (for GTKWave or other simulators)
        $dumpfile("rr_arbiter_tb.vcd");
        $dumpvars(0, tb_rr_arbiter);
 
        // initial reset
        rst_n = 0;
        req   = 4'b0000;
        #20;
        rst_n = 1;
 
        // CASE 1: single requester 0 holds for long time -> should keep grant
        $display("Time %0t: single req[0]", $time);
        req = 4'b0001;
        #200;
 
        // CASE 2: all request simultaneously -> round-robin rotation
        // should happen every TIME_SLICE
        $display("Time %0t: all reqs asserted", $time);
        req = 4'b1111;
        #(TB_TIMESLICE * 10 * 10);  // wait many cycles to observe rotations
 
        // CASE 3: a requester releases early
        $display("Time %0t: req[2] and req[3] only", $time);
        req = 4'b1100;
        #(TB_TIMESLICE * 8 * 10);
 
        // CASE 4: none requested
        $display("Time %0t: no requests", $time);
        req = 4'b0000;
        #100;
 
        // CASE 5: new burst of requests with different timings
        $display("Time %0t: burst pattern", $time);
        req = 4'b0010;  // only req[1]
        #60;
        req = 4'b0110;  // req[1] and req[2]
        #80;
        req = 4'b1001;  // req[3] and req[0]
        #120;
 
        // finish
        $display("Time %0t: end simulation", $time);
        #50;
        $finish;
    end
 
    // optional monitor
    always @(posedge clk) begin
        $display("t=%0t req=%b grant=%b", $time, req, grant);
    end
endmodule
