import my_pkg::*;

module PISO#(
  parameter int WIDTH = 8,
  parameter int DEPTH = 16
  )
  (
    input  logic              clk,
    input  logic              arst_n, 
    //write port
    input  logic [(WIDTH*DEPTH)-1:0]  din,
    input  logic              we, //write enable

    output logic [WIDTH-1:0]  qout,
    output logic              empty, full,
    input  logic              re  //read enable
  );

    logic [WIDTH-1:0] data [0:DEPTH-1];
    logic [WIDTH-1:0] qout_b;
    logic read_effective;
    
    assign qout = qout_b;
    assign read_effective = !empty && re;
    
    `REG($clog2(DEPTH)+1, read_addr);
    assign read_addr_we = read_effective;
    assign read_addr_next = (read_addr + 1) % FEATURES;
    
    always @ (posedge clk or negedge arst_n) begin
        if(arst_n == 0) begin
            foreach (data[i]) begin
                data[i] = 0;
                //qout_b = 0;
            end
            empty = 1;
            full = 0;  
        end else begin
            if(we) begin
                {>>DEPTH{data}} = din;
                empty = 0;
                full = 1;
            end
            if(read_effective) begin
                full = 0;
                if(read_addr_next == 0)
                empty = 1;
            end
        end
    end
    
    always_comb begin
        if(read_effective)
            qout_b = data[read_addr];
        else
            qout_b = 0;
    end

endmodule