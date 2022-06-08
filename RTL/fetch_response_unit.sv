`ifndef SLICES
`define SLICES
    `define LOC_SLICE "ADDR_LENGTH-2*$clog2(MESH_SIZE)-1 : 0"
    `define Y_LOC "ADDR_LENGTH-$clog2(MESH_SIZE)-1 : ADDR_LENGTH-2*$clog2(MESH_SIZE)"
    `define X_LOC "ADDR_LENGTH-1 : ADDR_LENGTH-$clog2(MESH_SIZE)"
`endif

import my_pkg::*;

module fetch_response_unit #(
    parameter int X_COORD = 1,
    parameter int Y_COORD = 1
    )
    (
    input logic clk, arst_n,
    
    //fetch unit interf.:
    input logic stall,
    
    //router interf.:
    input logic read, vld_in,
    input logic [PACKET_LENGTH-1 : 0] from_router,
    output logic reading, vld_out,
    output logic [PACKET_LENGTH-1 : 0] to_router,
    
    //memory interf.:
    input logic [(FEATURES*DATA_WIDTH)-1 : 0] from_mem,
    output logic [$clog2(MEM_HEIGHT)-1 : 0] mem_addr,
    output logic mem_re
    );
    
    logic piso_we, piso_empty, piso_full, piso_re;
    logic load, req_valid;
    logic [DATA_WIDTH-1:0] piso_out;
    
    PISO #(.WIDTH(DATA_WIDTH), .DEPTH(FEATURES))
    vector_piso (
        .clk(clk),
        .arst_n(arst_n),
        .din(from_mem),
        .we(piso_we),
        .qout(piso_out),
        .empty(piso_empty),
        .full(piso_full),
        .re(piso_re)
    );
    
    logic [$clog2(MEM_HEIGHT)-1 : 0] address;
    logic [COORD_LENGTH-1 : 0] x_coord, y_coord;
    logic re_internal, reading_internal, vld_out_internal;
    assign {mem_re, reading, vld_out} = {re_internal, reading_internal, vld_out_internal};
    assign mem_addr = address;
    
    always @(posedge clk) begin
    if(req_valid && reading) begin
        address = from_router[ADDR_LENGTH-2*COORD_LENGTH-1 : 0];
        x_coord = from_router[PACKET_LENGTH-1-2*COORD_LENGTH-1 : PACKET_LENGTH-1-3*COORD_LENGTH];
        y_coord = from_router[PACKET_LENGTH-1-3*COORD_LENGTH-1 : PACKET_LENGTH-1-4*COORD_LENGTH];
    
    end
    end
    
    logic [PACKET_LENGTH-2*COORD_LENGTH-2 : 0] payload;
    assign payload = {{PACKET_LENGTH-2*COORD_LENGTH-2-DATA_WIDTH{1'b0}}, piso_out};
    assign to_router = {>>{1'b0, x_coord, y_coord, payload}};
   
    assign reading_internal = load && !piso_we;
    assign load = req_valid && !stall && piso_empty;
    assign req_valid = vld_in && from_router[PACKET_LENGTH-1]; //= vld_in && MSB(from_router)
    
    initial
        piso_we = 0;
    
    always @(posedge clk) begin
        re_internal = 0;
        if(load) begin
            re_internal = 1;
            piso_we = 1;
        end
        
        if(piso_full) begin
            piso_we = 0;
        end    
    end
    
    assign vld_out_internal = !piso_empty;
    assign piso_re = !piso_empty && !stall && read;
    //assign vld_out_internal = piso_re;

    
    
endmodule
