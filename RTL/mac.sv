import my_pkg::*;

`ifndef REGISTER
`define REGISTER
    `define REG(r_width, r_name) \
    logic [r_width-1:0] ``r_name``_next, r_name;\
    logic ``r_name``_we;\
    register #(.WIDTH(r_width)) ``r_name``_r(.clk(clk), .arst_n(arst_n), .din(``r_name``_next), .qout(``r_name``), .we(``r_name``_we))
`endif

module mac #(
    parameter int A_WIDTH = 8,
    parameter int B_WIDTH = 8,
    parameter int ACCUMULATOR_WIDTH = 16,
    parameter int OUTPUT_WIDTH = 8,
    parameter int OUTPUT_SCALE = 0
    )
    (
    input logic clk,
    input logic arst_n,

    input logic input_valid,
    input logic accumulate_internal,

    input logic signed [ACCUMULATOR_WIDTH-1:0] partial_sum_in,
    input logic signed [A_WIDTH-1:0] a,
    input logic signed [B_WIDTH-1:0] b,

    output logic signed [OUTPUT_WIDTH-1:0] out
    );

    //multiplier
    logic signed [ACCUMULATOR_WIDTH-1:0] product;
    assign product = a*b;

    //accumulation register
    `REG(ACCUMULATOR_WIDTH, accumulator_value);
    assign accumulator_value_we = input_valid;
    logic signed [ACCUMULATOR_WIDTH-1:0] sum;
    assign accumulator_value_next = sum;

    //2-mux
    logic signed[ACCUMULATOR_WIDTH-1:0] adder_b;
    assign adder_b = accumulate_internal ? accumulator_value : partial_sum_in;

    //adder
    assign sum = product + adder_b;

    assign out = accumulator_value; //>>> OUTPUT_SCALE;
endmodule


//macro to instantiate a mac with A_WIDTH = B_WIDTH = OUTPUT_WIDTH
`define MAC(width, scale, name) \
logic ``name``_input_valid;\
logic ``name``_accumulate_internal;\
logic ``name``_partial_sum_in;\
logic ``name``_a;\
logic ``name``_b;\
logic ``name``_out;\
mac #(  .A_WIDTH(width), .B_WIDHT(width), .ACCUMULATOR_WIDTH(2*width), .OUTPUT_WIDTH(width), .OUTPUT_SCALE(scale)) ``name``(.clk(clk),.arst_n(arst_n),.input_valid(``name``_input_valid),accumulate_internal(``name``_accumulate_internal), .partial_sum_in(``name``_partial_sum_in), .a(``name``_a), .b(``name``_b), .out(``name``_out));
