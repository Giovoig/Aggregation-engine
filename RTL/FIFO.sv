import my_pkg::*;

`ifndef REGISTER
`define REGISTER
    `define REG(r_width, r_name) \
    logic [r_width-1:0] ``r_name``_next, r_name;\
    logic ``r_name``_we;\
    register #(.WIDTH(r_width)) ``r_name``_r(.clk(clk), .arst_n(arst_n), .din(``r_name``_next), .qout(``r_name``), .we(``r_name``_we))
`endif

module FIFO#(
  parameter int WIDTH = 8,
  parameter int LOG2_OF_DEPTH = 4
  )
  (
    input  logic              clk,
    input  logic              arst_n, 
    //write port
    input  logic [WIDTH-1:0]  din,
    input  logic              we, //write enable
    output logic              full, // fifo full

    output logic [WIDTH-1:0]  qout,
    output logic              empty, // empty
    output logic              last, //fifo holds the last value
    input  logic              re  //read enable
  );

  logic write_effective;
  assign write_effective = we && !full;

  `REG(LOG2_OF_DEPTH+1, write_addr);
  assign write_addr_we = write_effective;
  assign write_addr_next = write_addr + 1;

  logic read_effective;
  assign read_effective = !empty && re;


  `REG(LOG2_OF_DEPTH+1, read_addr);
  assign read_addr_we = read_effective;
  assign read_addr_next = read_addr + 1;

 //if write_addr - read_addr = 2**LOG2_OF_DEPTH = depth, then the fifo is full
  //if write_addr = read_addr, the fifo is empty
  logic [LOG2_OF_DEPTH:0] write_addr_limit;
  assign write_addr_limit = read_addr + (1 << LOG2_OF_DEPTH);
  assign full = (write_addr == write_addr_limit);
  assign empty = (read_addr == write_addr);
  assign last = (read_addr == write_addr-1);


  //actual memory to store the data
  fifo_memory #(.WIDTH(WIDTH), .PARALLELISM(1), .HEIGHT(1<<LOG2_OF_DEPTH)) fifo_mem
    (.clk(clk), //sampling on the falling edge
     .read_addr(read_addr),
     .read_en(re),
     .qout(qout),

     .write_addr(write_addr),
     .write_en(write_effective),
     .din(din));

endmodule
