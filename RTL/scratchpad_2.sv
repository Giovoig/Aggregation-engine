module scratchpad_2 #(
    parameter int WIDTH = 8,
    parameter int PARALLELISM = 1,
    parameter int HEIGHT = 128
    )
    (
    input logic clk, CS,

    //0 cycle read port(s)
    input logic unsigned[$clog2(HEIGHT)-1:0] read_addr_1, read_addr_2,
    input logic read_en_1, read_en_2,
    output signed[(PARALLELISM*WIDTH)-1:0] qout_1, qout_2,

    //write port
    input logic unsigned[$clog2(HEIGHT)-1:0] write_addr,
    input logic write_en,
    input signed[(PARALLELISM*WIDTH)-1:0] din
    );

    logic signed [(PARALLELISM*WIDTH)-1:0] data [0:HEIGHT-1];
    logic signed [(PARALLELISM*WIDTH)-1:0] mem_out_1, mem_out_2;
    logic signed [(PARALLELISM*WIDTH)-1:0] qout_1_d, qout_1_q, qout_2_d, qout_2_q;

    always @(posedge clk) begin
        if(write_en && CS) begin
            data[write_addr] <= din;
        end
    end

    always_comb begin
        if(CS) begin
            qout_1_d = data[read_addr_1];
            qout_2_d = data[read_addr_2];
        end 
        else 
            {qout_1_d, qout_2_d} = {0, 0};
    end
    
    always @(posedge clk) begin
        if(read_en_1) qout_1_q = qout_1_d;
        if(read_en_2) qout_2_q = qout_2_d;
    end

    assign qout_1 = read_en_1 ? qout_1_d : qout_1_q;
    assign qout_2 = read_en_2 ? qout_2_d : qout_2_q;


    endmodule