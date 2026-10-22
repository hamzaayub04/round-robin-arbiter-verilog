module rr_arbiter #
(
    parameter TIME_SLICE = 16  // number of clock cycles allotted per grant
)
(
    input  wire       clk,
    input  wire       rst_n,   // active-low reset
    input  wire [3:0] req,     // request lines: req[0] .. req[3]
    output reg  [3:0] grant    // one-hot grant output: grant[i] = 1 means req[i] granted
);
 
    // internal index of currently granted requester (0..3).
    // If no grant, current_idx is last pointer
    reg [1:0]  current_idx;
    reg [31:0] slice_cnt;      // wide enough counter for TIME_SLICE
 
    // combinational: find the next request index starting from (current_idx + 1)
    // If there is no request at all -> next_found = 0 and next_idx ignored.
    reg       next_found;
    reg [1:0] next_idx;
    integer   i;
    reg [1:0] start_idx;
    reg       any_req;
 
    // moved declarations to module scope (fixes the Verilog-2001 error)
    reg [1:0] cand;            // used inside combinational loop
    reg [1:0] gidx;            // used inside sequential logic
 
    // detect if any request exists
    always @* begin
        any_req = |req;
    end
 
    // compute next_idx by scanning forward from current_idx+1 (wrap-around)
    always @* begin
        next_found = 1'b0;
        next_idx   = 2'b00;
        start_idx  = current_idx + 1;   // wrap naturally due to 2-bit
        for (i = 0; i < 4; i = i + 1) begin
            // compute candidate index with wrapping
            cand = (start_idx + i) & 2'b11;
            if (!next_found && req[cand]) begin
                next_found = 1'b1;
                next_idx   = cand;
            end
        end
    end
 
    // main sequential logic: manage grant and time slice counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant       <= 4'b0000;
            current_idx <= 2'b00;
            slice_cnt   <= 0;
        end else begin
            // if currently no grant and requests exist,
            // pick next starting from current_idx+1
            if (grant == 4'b0000) begin
                if (any_req) begin
                    // pick the next requesting index
                    if (next_found) begin
                        current_idx <= next_idx;
                        grant       <= (4'b0001 << next_idx);
                        slice_cnt   <= 1;  // start counting from 1 (or 0 depending on
                            convention)
                    end else begin
                        // shouldn't happen because any_req true implies next_found true
                        grant     <= 4'b0000;
                        slice_cnt <= 0;
                    end
                end else begin
                    // no requests
                    grant     <= 4'b0000;
                    slice_cnt <= 0;
                end
            end else begin
                // There is a current grant. Determine the index of the current grant
                gidx = 2'b00;
                if      (grant[0]) gidx = 2'b00;
                else if (grant[1]) gidx = 2'b01;
                else if (grant[2]) gidx = 2'b10;
                else if (grant[3]) gidx = 2'b11;
 
                // If the currently granted requester has released its request
                // -> find next immediately
                if (!req[gidx]) begin
                    // choose next requester (starting from gidx+1)
                    current_idx <= gidx;  // store last granted position so next scan begins
                        from gidx+1
                    if (next_found) begin
                        current_idx <= next_idx;
                        grant       <= (4'b0001 << next_idx);
                        slice_cnt   <= 1;
                    end else begin
                        // no other requests -> deassert grant
                        grant     <= 4'b0000;
                        slice_cnt <= 0;
                    end
                end else begin
                    // requester still holding request -> check timeslice
                    if (slice_cnt < (TIME_SLICE - 1)) begin
                        slice_cnt <= slice_cnt + 1;
                    end else begin
                        // timeslice expired -> move to next requester (if exists)
                        if (next_found) begin
                            current_idx <= next_idx;
                            grant       <= (4'b0001 << next_idx);
                            slice_cnt   <= 1;
                        end else begin
                            // no other requester, retain grant and restart counter
                            slice_cnt <= 1;
                        end
                    end
                end
            end
        end
    end
endmodule
