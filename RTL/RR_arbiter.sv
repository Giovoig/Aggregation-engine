import my_pkg::*;

module RR_arbiter
    (
        input logic clk, arst_n,
        //input update_priority,
        input logic [4:0] requests,
        input logic req_satisfied,
        output logic [4:0] grant,
        output logic conflict //only to gather metrics via TB
    );
    
    logic[2:0] pointer_next = 0;
    logic[4:0] req_shifted;
    logic[4:0] grant_shifted;
    logic[9:0] req_shifted_double, gr_shifted_double;
    logic conflict_q;
    assign conflict = conflict_q;
        
    always_comb begin
        case (requests)
            5'b00000: conflict_q = 1'b0;
            5'b00001: conflict_q = 1'b0;
            5'b00010: conflict_q = 1'b0;
            5'b00100: conflict_q = 1'b0;
            5'b01000: conflict_q = 1'b0;
            5'b10000: conflict_q = 1'b0;
            default: conflict_q = 1'b1;
        endcase
    end
    
    always @(posedge clk or negedge arst_n) begin
        if(arst_n == 0 || pointer_next >= 5)
            pointer_next = 0;
        else if(grant != {1'b0, 1'b0, 1'b0, 1'b0, 1'b0} /*&& req_satisfied == 1*/) begin
            if(grant == 5'b00001) pointer_next = 3'b001;
            if(grant == 5'b00010) pointer_next = 3'b010;
            if(grant == 5'b00100) pointer_next = 3'b011;
            if(grant == 5'b01000) pointer_next = 3'b100;
            if(grant == 5'b10000) pointer_next = 3'b000;
            end
                
    end
    
    //rotating the requesters:
    assign req_shifted_double = {requests, requests} >> pointer_next;
    assign req_shifted = req_shifted_double[4:0];
    
    //assigning the grant:
    assign grant_shifted[0] = req_shifted[0];
    assign grant_shifted[1] = ~req_shifted[0] & req_shifted [1];
    assign grant_shifted[2] = ~req_shifted[0] & ~req_shifted[1] & req_shifted[2];
    assign grant_shifted[3] = ~req_shifted[0] & ~req_shifted[1] & ~req_shifted[2] & req_shifted[3];
    assign grant_shifted[4] = ~req_shifted[0] & ~req_shifted[1] & ~req_shifted[2] & ~req_shifted[3] & req_shifted[4];
    
    assign gr_shifted_double = {grant_shifted, grant_shifted} << pointer_next;
    assign grant = gr_shifted_double[9:5];
    
endmodule
