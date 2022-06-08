import my_pkg::*;

module router_input#(
       parameter int X_COORD = 0,
       parameter int Y_COORD = 0
    )
    (
        input logic clk, arst_n,
        input logic packet_valid,
        input logic signed [PACKET_LENGTH-1 : 0] down,
        input logic is_read,
        
        output logic is_reading, valid_out,
        output logic [0:4] port_request,
        output logic signed [PACKET_LENGTH-1 : 0] to_switch
    );
    
    logic fifo_full;
    logic fifo_we;
    logic fifo_re;
    logic fifo_empty;
    logic fifo_last;
    logic reading;
    logic vld_out_internal;
    logic [2:0] output_port;
    logic [4:0] port_req_out;
    logic [PACKET_LENGTH-1 : 0] fifo_qout;
    
    assign valid_out = vld_out_internal;
    assign is_reading = reading;

    FIFO #(.WIDTH(PACKET_LENGTH), .LOG2_OF_DEPTH(LOG2_FIFO_DEPTH)) down_fifo
    (   .clk(clk),
        .arst_n(arst_n),
        .din(down),
        .we(fifo_we),
        .re(fifo_re),
        .full(fifo_full),
        .last(fifo_last),
        .empty(fifo_empty),
        .qout(fifo_qout)
    );
    
    assign reading = packet_valid && !fifo_full;
    assign vld_out_internal = !fifo_empty;
    assign fifo_we = reading;
    assign fifo_re = is_read;
    
    logic unsigned [COORD_LENGTH-1:0] dest_x, dest_y;
    
    int xdiff, ydiff;
    //next direction evaluation:
    //always @(posedge clk) begin
    always_comb begin
        dest_x = fifo_qout[PACKET_LENGTH - 2 : PACKET_LENGTH - 1 - COORD_LENGTH];
        dest_y = fifo_qout[PACKET_LENGTH - 2 - COORD_LENGTH : PACKET_LENGTH - 1 - 2*COORD_LENGTH];
        xdiff = dest_x - X_COORD;
        ydiff = dest_y - Y_COORD;

        if (xdiff > 0)
            output_port <= EAST;
        else if (xdiff < 0)
            output_port <= WEST;
        else //xdiff = 0
            if(ydiff > 0)
                output_port <= NORTH;
            else if(ydiff < 0)
                output_port <= SOUTH;
            else //ydiff = 0
                output_port <= LOCAL;
    end
    
    
    always_comb begin
        if(valid_out == 1) begin
            case(output_port)
            LOCAL: port_req_out = 5'b00001;
            EAST: port_req_out = 5'b00010;
            NORTH: port_req_out = 5'b00100;
            WEST: port_req_out = 5'b01000;
            SOUTH: port_req_out = 5'b10000;
            default: port_req_out = 5'b00000;
            endcase
        end else
            port_req_out = 5'b00000;
    end
    
    assign port_request = port_req_out;
    assign to_switch = fifo_qout;
    
endmodule
