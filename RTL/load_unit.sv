import my_pkg::*;

module load_unit #(
    parameter int X_COORD = 1,
    parameter int Y_COORD = 1
    )
    (
    input logic req_vld,
    input logic [ADDR_LENGTH-1:0] addr1,
    input logic [ADDR_LENGTH-1:0] addr2,
    
    output logic [$clog2(MEM_HEIGHT)-1:0] addr1_out,
    output logic [$clog2(MEM_HEIGHT)-1:0] addr2_out,
    
    //memory interface
    output logic mem_vld1, mem_vld2,
    
    //fetch unit interface:
    output logic [COORD_LENGTH-1:0] x1, y1, x2, y2,
    output logic fetch_vld1, fetch_vld2
    );
    
    logic [ADDR_LENGTH-1:0] addr1_mem_b, addr2_mem_b;
    logic mem_vld1_b, mem_vld2_b;
    logic [COORD_LENGTH-1:0] x1_b, y1_b, x2_b, y2_b;
    logic fetch_vld1_b, fetch_vld2_b;
    
    assign mem_vld1 = mem_vld1_b;
    assign mem_vld2 = mem_vld2_b;
    assign fetch_vld1 = fetch_vld1_b;
    assign fetch_vld2 = fetch_vld2_b;
    
    logic [COORD_LENGTH-1:0] x1_req, y1_req, x2_req, y2_req;
    
    assign addr1_out = addr1[$clog2(MEM_HEIGHT)-1:0];
    assign addr2_out = addr2[$clog2(MEM_HEIGHT)-1:0];
    assign x1 = addr1[ADDR_LENGTH-1 : ADDR_LENGTH-COORD_LENGTH];
    assign y1 = addr1[ADDR_LENGTH-COORD_LENGTH-1 : ADDR_LENGTH-2*COORD_LENGTH];
    assign x2 = addr2[ADDR_LENGTH-1 : ADDR_LENGTH-COORD_LENGTH];
    assign y2 = addr2[ADDR_LENGTH-COORD_LENGTH-1 : ADDR_LENGTH-2*COORD_LENGTH];
    
    
    always_comb begin
        mem_vld1_b = 0;
        mem_vld2_b = 0;
        fetch_vld1_b = 0;
        fetch_vld2_b = 0;
        
        if(req_vld) begin
            
            if(x1 == X_COORD && y1 == Y_COORD) begin
                mem_vld1_b = 1;
            end else begin
                fetch_vld1_b = 1;
            end
            
            if(x2 == X_COORD && y2 == Y_COORD) begin
                mem_vld2_b = 1;
            end else begin
                fetch_vld2_b = 1;
            end
            
        end
    end
    
endmodule
