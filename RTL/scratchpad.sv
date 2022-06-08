module scratchpad #(
    parameter int WIDTH = 8,
    parameter int PARALLELISM = 1,
    parameter int HEIGHT = 128
    )
    (
    input logic clk, CS,

    //0 cycle read port(s)
    input logic unsigned[$clog2(HEIGHT)-1:0] read_addr,
    input logic read_en,
    output signed[(PARALLELISM*WIDTH)-1:0] qout,

    //write port
    input logic unsigned[$clog2(HEIGHT)-1:0] write_addr,
    input logic write_en,
    input signed[(PARALLELISM*WIDTH)-1:0] din
    );

    logic signed [(PARALLELISM*WIDTH)-1:0] data [0:HEIGHT-1];
    //reg data [0:HEIGHT-1];
    logic signed [(PARALLELISM*WIDTH)-1:0] mem_out;

    always @(posedge clk) begin
        if(write_en == 1 && CS == 1) begin
            data[write_addr] <= din;
        end
    end

    integer i;
    always_comb begin
        if(CS == 1 && read_en)
            mem_out = data[read_addr];
        else
            mem_out = 0;
    end

    assign qout = mem_out;


    endmodule
