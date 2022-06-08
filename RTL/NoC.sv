import my_pkg::*;

module NoC
    (
    input logic arst_n, clk,
    input logic dummy_sel, //synth only
    input logic [VECTOR_LENGTH-1:0] dummy_in, //for synth. purp.
    output [PACKET_LENGTH-1 : 0] dummy_out, //for synthesis purposes
    output [PACKET_LENGTH-1:0] dummy_mem_out,
    output logic done_out
    );
    
    logic signed [PACKET_LENGTH-1:0] router_in [1 : MESH_SIZE][1 : MESH_SIZE];
    logic signed [PACKET_LENGTH-1:0] router_out [1 : MESH_SIZE][1 : MESH_SIZE];
    //logic [OPCODE_LENGTH + ADDR_LENGTH - 1 :0] instruction [1 : MESH_SIZE][1 : MESH_SIZE];
    logic router_valid [1 : MESH_SIZE][1 : MESH_SIZE];
    logic reading [1 : MESH_SIZE][1 : MESH_SIZE];
    logic read [0 : (MESH_SIZE + 1)][0 : (MESH_SIZE + 1)][0:4];
    logic signed [PACKET_LENGTH-1:0] mac_in [1 : MESH_SIZE][1 : MESH_SIZE];
    logic signed [PACKET_LENGTH-1:0] downstream[0 : (MESH_SIZE + 1)][0 : (MESH_SIZE + 1)][0:4];
    logic local_reading[1 : MESH_SIZE][1 : MESH_SIZE];

    logic packet_valid [0 : (MESH_SIZE + 1)][0 : (MESH_SIZE + 1)][0:4];
    logic valid_out [1 : MESH_SIZE][1 : MESH_SIZE][0:4];
    logic [1 : MESH_SIZE][1 : MESH_SIZE] done;
    logic layer_finished;
    
    assign layer_finished = &done; //if all the done signals are asserted
    assign done_out = layer_finished;
    
    assign dummy_out = router_in[1][1];

    genvar x,y;
    generate
        for(y=1; y <= MESH_SIZE; y++) begin
            for(x=1; x <= MESH_SIZE; x++) begin
            
            localparam  bit [4:0] ACTIVE_PORTS  = get_active_ports(y-1, x-1);

			router #(
			         .X_COORD(x-1),
			         .Y_COORD(y-1)
			)
			router(
			         .clk(clk),
			         .arst_n(arst_n),
			         .packet_valid(packet_valid[x][y]), //input
			         .n_reading(read[x][y+1][SOUTH]),
			         .e_reading(read[x+1][y][WEST]),
			         .w_reading(read[x-1][y][EAST]),
			         .s_reading(read[x][y-1][NORTH]),
			         .local_reading(reading[x][y]),
			         .is_read(read[x][y]), //input
			         .n_valid_out(packet_valid[x][y+1][SOUTH]),
			         .e_valid_out(packet_valid[x+1][y][WEST]),
			         .s_valid_out(packet_valid[x][y-1][NORTH]),
			         .w_valid_out(packet_valid[x-1][y][EAST]),
			         .local_valid_out(router_valid[x][y]),
			         .downstream(downstream[x][y]), //input
			         
			         .n_up(downstream[x][y+1][SOUTH]),
			         .e_up(downstream[x+1][y][WEST]),
			         .s_up(downstream[x][y-1][NORTH]),
			         .w_up(downstream[x-1][y][EAST]),
			         .local_up(router_out[x][y])
			);
			
			assign downstream[x][y][LOCAL] = router_in[x][y];
			
			if (!ACTIVE_PORTS[EAST]) begin
                dummy_node
                dummy(
                    .w_up(downstream[x][y][EAST]),
                    .w_valid_out(packet_valid[x][y][EAST]),
                    .is_reading_w(read[x][y][EAST])
                );
            end

            if (!ACTIVE_PORTS[NORTH]) begin 
                dummy_node
                dummy(
                    .s_up(downstream[x][y][NORTH]),
                    .s_valid_out(packet_valid[x][y][NORTH]),
                    .is_reading_s(read[x][y][NORTH])
                );
            end

            if (!ACTIVE_PORTS[WEST]) begin
                dummy_node
                dummy(
                    .e_up(downstream[x][y][WEST]),
                    .e_valid_out(packet_valid[x][y][WEST]),
                    .is_reading_e(read[x][y][WEST])
                );
            end

            if (!ACTIVE_PORTS[SOUTH]) begin
                dummy_node
                dummy(
                    .n_up(downstream[x][y][SOUTH]),
                    .n_valid_out(packet_valid[x][y][SOUTH]),
                    .is_reading_n(read[x][y][SOUTH])
                );
            end
			

			
			PE #(  .X_COORD(x-1),
                   .Y_COORD(y-1)
                   )
            PE(
                    .clk(clk),
                    .arst_n(arst_n),
                    .read(reading[x][y]),
                    .dummy_sel(dummy_sel),
                    .dummy_in(dummy_in),
                    .dummy_out(dummy_mem_out),
                    .reading(read[x][y][LOCAL]),
                    .vld_in(router_valid[x][y]),
                    .vld_out(packet_valid[x][y][LOCAL]),
                    .din(router_out[x][y]),
                    .dout(router_in[x][y]),
                    .done(done[x][y])
    				);
            end
        end
    
    endgenerate
    
    function bit [4:0] get_active_ports(int y, int x);
        bit [4:0] active_ports;
        active_ports[LOCAL] = 1;
        active_ports[EAST]  = (x < MESH_SIZE-1) ? 1 : 0;
        active_ports[NORTH] = (y < MESH_SIZE-1) ? 1 : 0;
        active_ports[WEST]  = (x > 0          ) ? 1 : 0;
        active_ports[SOUTH] = (y > 0          ) ? 1 : 0;
        return active_ports;
  endfunction
    
endmodule
