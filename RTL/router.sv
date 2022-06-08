import my_pkg::*;

module router #(
       parameter int X_COORD = 0,
       parameter int Y_COORD = 0
    )
    (
    input logic clk, arst_n,
    input logic is_read [0:4],
    input logic packet_valid [0:4],
    
    output signed [PACKET_LENGTH - 1:0] n_up,
    output signed [PACKET_LENGTH - 1:0] s_up,
    output signed [PACKET_LENGTH - 1:0] w_up,
    output signed [PACKET_LENGTH - 1:0] e_up,
    output signed [PACKET_LENGTH - 1:0] local_up,
    
    input signed [PACKET_LENGTH - 1:0] downstream [0:4],
    
    output logic n_valid_out, w_valid_out, s_valid_out, e_valid_out, local_valid_out,
    output logic n_reading, w_reading, s_reading, e_reading, local_reading
    );
  
    logic is_reading[0:4];
    assign local_reading = is_reading[LOCAL];
    assign e_reading = is_reading[EAST];
    assign n_reading = is_reading[NORTH];
    assign w_reading = is_reading[WEST];
    assign s_reading = is_reading[SOUTH];
    
    logic signed [PACKET_LENGTH - 1:0] n_out;
    logic signed [PACKET_LENGTH - 1:0] s_out;
    logic signed [PACKET_LENGTH - 1:0] w_out;
    logic signed [PACKET_LENGTH - 1:0] e_out;
    logic signed [PACKET_LENGTH - 1:0] local_out;
    
    logic valid_out [0:4];
    logic valid_input_block [0:4];
    logic is_read_reg [0:4];
    logic is_read_input_block [0:4];
    
    logic [4:0] req_source [0:4]; //requests of each input port
    logic [4:0] req_dest [0:4]; //requests to the arbiter of each output port
    logic [4:0] grant [0:4];
    logic arb_conflict [0:4];
    logic router_conflict;
    logic signed [PACKET_LENGTH - 1 : 0] to_switch [0:4];
    
    assign router_conflict = arb_conflict[0] || arb_conflict[1] || arb_conflict[2] || arb_conflict[3] || arb_conflict[4];

    router_input #(.X_COORD(X_COORD), .Y_COORD(Y_COORD))
    local_input(
        .clk(clk),
        .arst_n(arst_n),
        .to_switch(to_switch[LOCAL]),
        .packet_valid(packet_valid[LOCAL]),
        .is_reading(is_reading[LOCAL]),
        .is_read(is_read_input_block[LOCAL]),
        .valid_out(valid_input_block[LOCAL]),
        .down(downstream[LOCAL]),
        .port_request(req_source[LOCAL])
    );
    
    router_input #(.X_COORD(X_COORD), .Y_COORD(Y_COORD))
    north_input(
        .clk(clk),
        .arst_n(arst_n),
        .packet_valid(packet_valid[NORTH]),
        .is_reading(is_reading[NORTH]),
        .is_read(is_read_input_block[NORTH]),
        .to_switch(to_switch[NORTH]),
        .valid_out(valid_input_block[NORTH]),
        .down(downstream[NORTH]),
        .port_request(req_source[NORTH])
    );
    
    router_input #(.X_COORD(X_COORD), .Y_COORD(Y_COORD))
    west_input(
        .clk(clk),
        .arst_n(arst_n),
        .to_switch(to_switch[WEST]),
        .packet_valid(packet_valid[WEST]),
        .is_reading(is_reading[WEST]),
        .is_read(is_read_input_block[WEST]),
        .valid_out(valid_input_block[WEST]),
        .down(downstream[WEST]),
        .port_request(req_source[WEST])
    );
    
    router_input #(.X_COORD(X_COORD), .Y_COORD(Y_COORD))
    south_input(
        .clk(clk),
        .arst_n(arst_n),
        .to_switch(to_switch[SOUTH]),
        .packet_valid(packet_valid[SOUTH]),
        .is_reading(is_reading[SOUTH]),
        .is_read(is_read_input_block[SOUTH]),
        .valid_out(valid_input_block[SOUTH]),
        .down(downstream[SOUTH]),
        .port_request(req_source[SOUTH])
    );
    
    router_input #( .X_COORD(X_COORD), .Y_COORD(Y_COORD))
    east_input(
        .clk(clk),
        .arst_n(arst_n),
        .to_switch(to_switch[EAST]),
        .packet_valid(packet_valid[EAST]),
        .is_reading(is_reading[EAST]),
        .is_read(is_read_input_block[EAST]),
        .valid_out(valid_input_block[EAST]),
        .down(downstream[EAST]),
        .port_request(req_source[EAST])
    );

    always_comb begin
        for (integer i = 0; i < 5; i++) begin
            req_dest[i] = {req_source[SOUTH][i], req_source[WEST][i], req_source[NORTH][i], req_source[EAST][i], req_source[LOCAL][i]};
        end
    end
    
    RR_arbiter local_arb(
        .clk(clk),
        .arst_n(arst_n),
        .requests(req_dest[LOCAL]),
        .req_satisfied(is_read[LOCAL]),
        .conflict(arb_conflict[LOCAL]),
        .grant(grant[LOCAL]));
       
    RR_arbiter east_arb(
        .clk(clk),
        .arst_n(arst_n),
        .requests(req_dest[EAST]),
        .req_satisfied(is_read[EAST]),
        .conflict(arb_conflict[EAST]),
        .grant(grant[EAST])); 
        
    RR_arbiter north_arb(
        .clk(clk),
        .arst_n(arst_n),
        .requests(req_dest[NORTH]),
        .req_satisfied(is_read[NORTH]),
        .conflict(arb_conflict[NORTH]),
        .grant(grant[NORTH]));
        
    RR_arbiter south_arb(
        .clk(clk),
        .arst_n(arst_n),
        .requests(req_dest[SOUTH]),
        .req_satisfied(is_read[SOUTH]),
        .conflict(arb_conflict[SOUTH]),
        .grant(grant[SOUTH]));
        
    RR_arbiter west_arb(
        .clk(clk),
        .arst_n(arst_n),
        .requests(req_dest[WEST]),
        .req_satisfied(is_read[WEST]),
        .conflict(arb_conflict[WEST]),
        .grant(grant[WEST]));
    
    assign n_valid_out = valid_out[NORTH];
    assign s_valid_out = valid_out[SOUTH];
    assign w_valid_out = valid_out[WEST];
    assign e_valid_out = valid_out[EAST];
    assign local_valid_out = valid_out[LOCAL];

    
    
    always_comb begin
        is_read_input_block = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
        local_out = 0;
        n_out = 0;
        e_out = 0;
        w_out = 0;
        s_out = 0;
        valid_out = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
        
        //local output:
        case (grant[LOCAL])
        NORTH_REQ: begin
            local_out = to_switch[NORTH];
            valid_out[LOCAL] = valid_input_block[NORTH];
            is_read_input_block[NORTH] = is_read[LOCAL];
        end
        EAST_REQ: begin
            local_out = to_switch[EAST];
            valid_out[LOCAL] = valid_input_block[EAST];
            is_read_input_block[EAST] = is_read[LOCAL];
        end
        SOUTH_REQ: begin
            local_out = to_switch[SOUTH];
            valid_out[LOCAL] = valid_input_block[SOUTH];
            is_read_input_block[SOUTH] = is_read[LOCAL];
        end
        WEST_REQ: begin
            local_out = to_switch[WEST];
            valid_out[LOCAL] = valid_input_block[WEST];
            is_read_input_block[WEST] = is_read[LOCAL];
        end
        NO_REQ: begin
            valid_out[LOCAL] = 0;
        end
        endcase
        
        //north:
        case (grant[NORTH])
        LOCAL_REQ: begin
            n_out = to_switch[LOCAL];
            valid_out[NORTH] = valid_input_block[LOCAL];
            is_read_input_block[LOCAL] = is_read[NORTH];
        end
        EAST_REQ: begin
            n_out = to_switch[EAST];
            valid_out[NORTH] = valid_input_block[EAST];
            is_read_input_block[EAST] = is_read[NORTH];
        end
        SOUTH_REQ: begin
            n_out = to_switch[SOUTH];
            valid_out[NORTH] = valid_input_block[SOUTH];
            is_read_input_block[SOUTH] = is_read[NORTH];
        end
        WEST_REQ: begin
            n_out = to_switch[WEST];
            valid_out[NORTH] = valid_input_block[WEST];
            is_read_input_block[WEST] = is_read[NORTH];
        end
        NO_REQ: begin
            valid_out[NORTH] = 0;
        end
        endcase
        
        //east
        case (grant[EAST])
        LOCAL_REQ: begin
            e_out = to_switch[LOCAL];
            valid_out[EAST] = valid_input_block[LOCAL];
            is_read_input_block[LOCAL] = is_read[EAST];
            end
        NORTH_REQ: begin
            e_out = to_switch[NORTH];
            valid_out[EAST] = valid_input_block[NORTH];
            is_read_input_block[NORTH] = is_read[EAST];
            end
        SOUTH_REQ: begin
            e_out = to_switch[SOUTH];
            valid_out[EAST] = valid_input_block[SOUTH];
            is_read_input_block[SOUTH] = is_read[EAST];
            end
        WEST_REQ:  begin
            e_out = to_switch[WEST];
            valid_out[EAST] = valid_input_block[WEST];
            is_read_input_block[WEST] = is_read[EAST];
            end
        NO_REQ: begin
            valid_out[EAST] = 0;
            end
        endcase
        
        //south
        case (grant[SOUTH])
        LOCAL_REQ: begin
            s_out = to_switch[LOCAL];
            valid_out[SOUTH] = valid_input_block[LOCAL];
            is_read_input_block[LOCAL] = is_read[SOUTH];
            end
        NORTH_REQ: begin
            s_out = to_switch[NORTH];
            valid_out[SOUTH] = valid_input_block[NORTH];
            is_read_input_block[NORTH] = is_read[SOUTH];
            end
        EAST_REQ: begin
            s_out = to_switch[EAST];
            valid_out[SOUTH] = valid_input_block[EAST];
            is_read_input_block[EAST] = is_read[SOUTH];
            end
        WEST_REQ: begin
            s_out = to_switch[WEST];
            valid_out[SOUTH] = valid_input_block[WEST];
            is_read_input_block[WEST] = is_read[SOUTH];
            end
        NO_REQ: begin
            valid_out[SOUTH] = 0;
        end
        endcase
        
        //west
        case (grant[WEST])
        LOCAL_REQ: begin
            w_out = to_switch[LOCAL];
            valid_out[WEST] = valid_input_block[LOCAL];
            is_read_input_block[LOCAL] = is_read[WEST];
            end
        NORTH_REQ: begin
            w_out = to_switch[NORTH];
            valid_out[WEST] = valid_input_block[NORTH];
            is_read_input_block[NORTH] = is_read[WEST];
            end
        SOUTH_REQ: begin
            w_out = to_switch[SOUTH];
            valid_out[WEST] = valid_input_block[SOUTH];
            is_read_input_block[SOUTH] = is_read[WEST];
            end
        EAST_REQ: begin
            w_out = to_switch[EAST];
            valid_out[WEST] = valid_input_block[EAST];
            is_read_input_block[EAST] = is_read[WEST];
            end
        NO_REQ: begin
            valid_out[WEST] = 0;
        end
        endcase
    end

    assign local_up = local_out;
    assign n_up = n_out;
    assign e_up = e_out;
    assign w_up = w_out;
    assign s_up = s_out;
   // assign is_read_reg = is_read;
        
endmodule
