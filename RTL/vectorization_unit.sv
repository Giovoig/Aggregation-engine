import my_pkg::*;

`ifndef REGISTER
`define REGISTER
    `define REG(r_width, r_name) \
    logic [r_width-1:0] ``r_name``_next, r_name;\
    logic ``r_name``_we;\
    register #(.WIDTH(r_width)) ``r_name``_r(.clk(clk), .arst_n(arst_n), .din(``r_name``_next), .qout(``r_name``), .we(``r_name``_we))
`endif

module vectorization_unit(
    
    input logic clk, arst_n,
    //router interf.:
    input logic vld_in,
    input logic [PACKET_LENGTH-1 : 0] din,
    output logic reading, vld_out,
    output logic [VECTOR_LENGTH-1 : 0] dout
    );
    
    logic sipo_we, sipo_re, sipo_full, sipo_emtpy;
    logic [DATA_WIDTH-1 : 0] feat;
    assign feat = din[DATA_WIDTH-1 : 0];
    
    SIPO #(.DEPTH(FEATURES))
    sipo_vect
    (
        .clk(clk),
        .arst_n(arst_n),
        .din(feat),
        .we(sipo_we),
        .qout(dout),
        .full(sipo_full),
        //.empty(sipo_empty),
        .re(sipo_re)
    );
    

    
    
    //always @ (posedge clk) begin
    always_comb begin
    reading = 0;
    sipo_re = 0;
    sipo_we = 0;

    if(din[PACKET_LENGTH-1] == 0) begin
        
        if(vld_in && !sipo_full) begin
            reading = 1;
            sipo_we = 1;
        end
    end
    
    if(sipo_full) begin
        sipo_re = 1;
    end
    
    end
    
    assign vld_out = sipo_full;
    
endmodule
