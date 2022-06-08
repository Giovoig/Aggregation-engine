 module register #(
  parameter integer WIDTH     = 20,
  parameter integer RESET_VAL = 'b0
   )(
  input  logic              clk,
  input  logic              arst_n,

  input  logic [WIDTH-1:0]  din,
  input  logic we,
  output logic [WIDTH-1:0]  qout
);

logic [WIDTH-1:0] r;

always_ff @(posedge clk, negedge arst_n) begin
   if(arst_n==0)begin
      r <= RESET_VAL;
   end else begin
      if(we)
        r <= din;
   end
end

assign qout = r;

endmodule