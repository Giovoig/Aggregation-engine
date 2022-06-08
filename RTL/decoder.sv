/* 10-bit IS:
	000[w_addr] -> NOP
	001[w_addr] -> store internal
	010[r_addr] -> load
	100[X] -> accumulate 0
	110[X] -> accumulate internal
	111[X] -> stop layer
*/

import my_pkg::*;
    
module decoder
	(
	input logic clk,
	input logic [INSTRUCTION_LENGTH-1:0] instruction,
	
	//load unit interface:
	output logic req_vld,
	output logic [ADDR_LENGTH-1 : 0] rd_addr,
    
	output logic write_en, accumulate_internal, input_valid, input_sel, done, 
	//output logic mem_sel,
	output logic unsigned [$clog2(MEM_HEIGHT)-1:0] wr_addr
	);

	logic [2:0] opcode;
	logic [ADDR_LENGTH-1:0] operand;
	logic [ADDR_LENGTH-1:0] rd_addr_buf;
	logic [$clog2(MEM_HEIGHT)-1:0] wr_addr_buf;
	logic req_vld_b;
	
	assign opcode = instruction[OPCODE_LENGTH+ADDR_LENGTH-1:ADDR_LENGTH];
	assign operand = instruction[ADDR_LENGTH-1:0];
	assign wr_addr = wr_addr_buf;
	assign rd_addr = rd_addr_buf;
	assign req_vld = req_vld_b;
	always_comb begin
					
	   write_en = 0;
	   input_sel = 0;
	   req_vld_b = 0;
	   wr_addr_buf = 0;
	   rd_addr_buf = 0;
	   input_valid = 0;
       accumulate_internal = 0;
       done = 0;
       
		case(opcode)
			3'b001: begin //store
				write_en = 1;
				wr_addr_buf = operand[$clog2(MEM_HEIGHT)-1:0];
			end
			3'b010: begin //load
			    rd_addr_buf = operand;
				req_vld_b = 1;
			end
			3'b100: begin //acc. 0
				input_valid = 1;
		    end
			3'b110: begin //acc. internal
				input_valid = 1;
				accumulate_internal = 1;
		    end
		    3'b111: done = 1;
		    default: begin //NOP
		    	write_en = 0;
				input_sel = 0;
			    req_vld_b = 0;
				rd_addr_buf = 0;
				wr_addr_buf = 0;
				input_valid = 0;
				accumulate_internal = 0;
				done = 0;
		    end
		endcase
	end
	

endmodule

