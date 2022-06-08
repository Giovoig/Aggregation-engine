import my_pkg::*;

//could probably use less logic

module fetch_unit #(
    parameter int X_COORD = 1,
    parameter int Y_COORD = 1
    )
    (
    input logic clk,
    input logic read,
    input logic arst_n,
    input logic [COORD_LENGTH-1 : 0] x1, y1,
    input logic [COORD_LENGTH-1 : 0] x2, y2,
    input logic [$clog2(MEM_HEIGHT)-1 : 0] add1, add2,
    input logic vld_in_1, vld_in_2,
  
    output logic vld_out, stall_out,
    output logic [PACKET_LENGTH-1 : 0] packet
    );
    
    logic vld1_b, vld2_b;
    assign vld_out = vld1_b || vld2_b;
    assign stall_out = vld_out;
//    
//    logic [COORD_LENGTH-1 : 0] x1_q, y1_q;
//    logic [COORD_LENGTH-1 : 0] x2_q, y2_q;
    
    logic [COORD_LENGTH-1 : 0] source_coord [0:1] = {X_COORD, Y_COORD};
    
    logic [PACKET_LENGTH-1 : 0] packet_1, packet_2, packet_out;
    assign packet = packet_out;
    
    //packets definition:
    logic [DATA_WIDTH-2*COORD_LENGTH-1 : 0]add1_padded;
    always @(posedge clk) begin
        
        if(vld_in_1)
            if(DATA_WIDTH < ADDR_LENGTH)
                packet_1 = {1'b1, x1, y1, source_coord[0], source_coord[1], add1};
            else begin
//                for(int p = 0; p < (DATA_WIDTH-ADDR_LENGHT); p++) begin
//                
//                end
                add1_padded = {0, add1};
                packet_1 = {1'b1, x1, y1, source_coord[0], source_coord[1], add1_padded};
            end
        
        if(vld_in_2)
            if(DATA_WIDTH < ADDR_LENGTH)
                packet_2 = {1'b1, x2, y2, source_coord[0], source_coord[1], add2};
            else
                packet_2 = {};
    end
    
    
    always @(posedge clk or negedge arst_n) begin
        if(!arst_n) begin
            vld1_b = 0;
            vld2_b = 0;
        end else begin
                   
        //handshake:
        if(read && vld1_b) begin
            vld1_b = 0;
        end
        
        if(read && vld2_b) begin
            vld2_b = 0;
        end
        
        if(vld_in_1) begin
            vld1_b = 1;
        end
            
        if(vld_in_2) begin
            vld2_b = 1;
        end
        end
    end
    
    //always @(vld1_b or vld2_b or packet_1 or packet_2) begin 
    always @(posedge clk) begin   
        //load to router:
        if(vld1_b)
            packet_out = packet_1;
        else if(vld2_b)
            packet_out = packet_2;
    end

    
endmodule
