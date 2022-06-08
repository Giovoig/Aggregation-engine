import my_pkg::*;
`define REG(r_width, r_name) \
    logic [r_width-1:0] ``r_name``_next, r_name;\
    logic ``r_name``_we;\
    register #(.WIDTH(r_width)) ``r_name``_r(.clk(clk), .arst_n(arst_n), .din(``r_name``_next), .qout(``r_name``), .we(``r_name``_we))


module SIPO#(
  parameter int DEPTH = 16
  )
  (
    input  logic              clk,
    input  logic              arst_n, 
    //write port
    input  logic [DATA_WIDTH-1 : 0]  din,
    input  logic              we, //write enable

    output logic [VECTOR_LENGTH-1 : 0]  qout,
    output logic              full,
    //output logic              empty, 
    input  logic              re  //read enable
  );
  
  
  logic write_effective, write_rst;
  assign write_effective = (we && !full);
  
  logic read_effective;
  assign read_effective = re && full;

  `REG($clog2(DEPTH)+1, write_addr);
  assign write_addr_we = write_effective || write_rst;
  assign write_addr_next = (write_addr + 1) % (DEPTH+1) ;


  logic [$clog2(DEPTH):0] write_addr_limit;
  assign write_addr_limit = DEPTH;
  assign full = (write_addr == write_addr_limit);

  logic signed [DATA_WIDTH-1:0] data [0:DEPTH-1];
  logic signed [(VECTOR_LENGTH)-1:0] mem_out_q, mem_out_d;

    always @(posedge clk) begin
        if(write_effective == 1) begin
            data[write_addr] = din;
        end
    end

    assign mem_out_d = {>>{data}};
    always @(read_effective or mem_out_d) begin
    //always @(posedge clk) begin
       if(read_effective) begin
            mem_out_q = mem_out_d;
       end
    end
    
    always_comb begin
        write_rst = 0;
        if(read_effective)
            write_rst = 1;
    end

    assign qout = mem_out_q;

  
  
endmodule
