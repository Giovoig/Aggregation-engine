 import my_pkg::*;
 
 module PE #(
    parameter int X_COORD = 1,
    parameter int Y_COORD = 1
    )
    (
    input logic clk,
    input logic arst_n,
    
    input logic signed [PACKET_LENGTH-1:0] din,
    input logic read, vld_in,
    input logic dummy_sel, //synth only
    input logic [VECTOR_LENGTH-1:0] dummy_in, //only for synth purposes
    output logic [VECTOR_LENGTH-1:0] dummy_out, //synth only
    output logic reading, vld_out,
    output logic signed [PACKET_LENGTH-1:0] dout,
    output done
    );
    
    logic done_d, done_q;
    assign done = done_q;

    logic read_en, write_en, input_sel, mem_sel, CS1, CS2;
    logic [ADDR_LENGTH-1:0] read_addr;
    logic [$clog2(MEM_HEIGHT)-1:0] read_addr_1;
    logic [$clog2(MEM_HEIGHT)-1:0] write_addr;
     
    logic [COORD_LENGTH-1 : 0] x_coord, y_coord;
    logic [$clog2(MEM_HEIGHT)-1 : 0] ld_addr_out, fr_addr_out;
    logic ld_unit_re, fr_unit_re;
    logic fetch_vld;
    
    logic signed[(VECTOR_LENGTH)-1:0] mem_to_mac, mem_to_fetch;
    logic signed[(VECTOR_LENGTH)-1:0] mem_to_mac_1;
    logic signed[(VECTOR_LENGTH)-1:0] mem_to_fetch_1;
    logic signed[(VECTOR_LENGTH)-1:0] mem_1_in;
    logic signed[(VECTOR_LENGTH)-1:0] mem_to_mac_2;
    logic signed[(VECTOR_LENGTH)-1:0] mem_to_fetch_2;
    logic signed[(VECTOR_LENGTH)-1:0] mem_a;
    logic signed[(VECTOR_LENGTH)-1:0] mem_b;
    logic signed[(VECTOR_LENGTH)-1:0] mem_in;
    logic signed[(VECTOR_LENGTH)-1:0] mac_out;
    
    logic [$clog2(MEM_HEIGHT)-1:0] addr_fetch, addr_to_mem;
    
    logic [VECTOR_LENGTH-1 : 0] mac_in;
    logic [OPCODE_LENGTH + ADDR_LENGTH - 1 : 0] instruction, instruction_flow, nop_instr;
    assign nop_instr = 0;

    logic write_en_1, write_en_2;
    assign mem_to_mac = mem_sel ? mem_to_mac_1 : mem_to_mac_2;
    assign mem_to_fetch = mem_sel ? mem_to_fetch_1 : mem_to_fetch_2;
    
    //assign mem_sel = 1'b1; //for sim
    assign mem_sel = dummy_sel; //for synth
    
    assign write_en_1 = mem_sel ? 1'b0 : write_en;
    assign write_en_2 = mem_sel ? write_en : 1'b0;
    assign dummy_mem_out = mem_to_mac;
    
    assign CS1 = 1'b1;
    assign CS2 = 1'b1;

    assign mem_in = mac_out || dummy_in; //for synth
    //assign mem_in = mac_out; //for sim
    
    //assign dout = mem_out;
    //assign dout = mac_out;

    always @(posedge clk or negedge arst_n) begin
        if(!arst_n)
            done_q = 0;
        else if(done_d)
            done_q = 1;
    end

    //scratchpad memories
    scratchpad_2 #(.WIDTH(DATA_WIDTH), .HEIGHT(MEM_HEIGHT), .PARALLELISM(FEATURES))
    memory_1( .clk(clk),
            .read_addr_1(ld_addr_out),
            .read_addr_2(fr_addr_out),
            .CS(CS1),
            .read_en_1(ld_unit_re),
            .read_en_2(fr_unit_re),
            .write_addr(write_addr),
            .write_en(write_en_1),
            .din(mem_in),
            .qout_1(mem_to_mac_1),
            .qout_2(mem_to_fetch_1)
            );
    
    scratchpad_2 #(.WIDTH(DATA_WIDTH), .HEIGHT(MEM_HEIGHT), .PARALLELISM(FEATURES))
    memory_2( .clk(clk),
            .read_addr_1(ld_addr_out),
            .read_addr_2(fr_addr_out),
            .CS(CS2),
            .read_en_1(ld_unit_re),
            .read_en_2(fr_unit_re),
            .write_addr(write_addr),
            .write_en(write_en_2),
            .din(mem_in),
            .qout_1(mem_to_mac_2),
            .qout_2(mem_to_fetch_2)
            );
            
    logic pc_stall, vector_valid, pc_stall_d, pc_stall_q;
    `REG($clog2(INSTR_MEM_HEIGHT), program_counter);
    assign program_counter_we = !pc_stall && !done;
    assign program_counter_next = program_counter + 1;
     
    //latch for stalling the program counter
    always @(vector_valid or arst_n or vld_out_req) begin
        if(vector_valid || !arst_n)
            pc_stall <= 1'b0;
        else
            if(vld_out_req)
                pc_stall <= 1'b1;
    end
    
//    always @(posedge clk or negedge arst_n) begin
//        if(!arst_n) pc_stall_q = 1'b0; else begin
//            pc_stall_q = pc_stall_d;
//        end
//    end
//    
//    assign pc_stall = (vld_out_req || vector_valid) ? pc_stall_d : pc_stall_q;
    
    assign instruction = pc_stall ? nop_instr : instruction_flow;
            
    scratchpad #(.WIDTH(INSTRUCTION_LENGTH), .HEIGHT(INSTR_MEM_HEIGHT), .PARALLELISM(1))
    instruction_mem( 
            .clk(clk),
            .read_addr(program_counter),
            .CS(1'b1),
            .read_en(1'b1),
            .write_addr(0),
            //.write_en(1'b0), //for sim
            .write_en(dummy_sel), //for synth
            .din(dummy_in),
            .qout(instruction_flow)
            );

    logic input_valid;
    logic accumulate_internal;
    logic signed[2*DATA_WIDTH-1:0] partial_sum_in;
    assign partial_sum_in = 0;

    //MACs
    genvar i;
    generate
        for(i=0; i<FEATURES; i=i+1) begin
            mac #(  
                .A_WIDTH(DATA_WIDTH),
                .B_WIDTH(DATA_WIDTH),
                .ACCUMULATOR_WIDTH(2*DATA_WIDTH),
                .OUTPUT_WIDTH(DATA_WIDTH),
                .OUTPUT_SCALE(OUT_SCALE))
            mac(
                .clk(clk),
                .arst_n(arst_n),
                .input_valid(input_valid),
                .accumulate_internal(accumulate_internal),
                .partial_sum_in(partial_sum_in),
                .a(mac_in[i*DATA_WIDTH +: DATA_WIDTH]),
                //.b(mem_b[i*DATA_WIDTH +: DATA_WIDTH]),
                .b(1),
                .out(mac_out[i*DATA_WIDTH +: DATA_WIDTH])
					);
        end
    endgenerate

    logic ld_rqst;
    //instruction decoder
        decoder
        decoder(    
            .clk(clk),
            .instruction(instruction),
            .write_en(write_en),
            .input_sel(input_sel),
            .accumulate_internal(accumulate_internal),
            .input_valid(input_valid),
            .wr_addr(write_addr),
            .req_vld(ld_rqst),
            .rd_addr(read_addr),
            .done(done_d)
                );
    
    assign read_en = ld_unit_re | fr_unit_re;
    assign addr_to_mem = ld_unit_re ? ld_addr_out : fr_addr_out;
     
        //load unit
        load_unit #(.X_COORD(X_COORD), .Y_COORD(Y_COORD))
        ld_unit(
            .req_vld(ld_rqst),
            .addr1(read_addr),
            .addr2(0),
            .addr1_out(ld_addr_out),
            .mem_vld1(ld_unit_re),
            .x1(x_coord),
            .y1(y_coord),
            .fetch_vld1(fetch_vld)
        );
        
        logic resp_stall;
        logic fetch_unit_read, f_r_unit_read;
        logic [PACKET_LENGTH-1 : 0] f_issue_out, f_resp_out;
        
        assign fetch_unit_read = resp_stall ? read : 0;
        assign f_r_unit_read = resp_stall ? 0 : read;
        //fetch request unit
        fetch_unit #(.X_COORD(X_COORD), .Y_COORD(Y_COORD))
        fetch_unit(
            .clk(clk),
            .read(fetch_unit_read),
            .arst_n(arst_n),
            .x1(x_coord),
            .y1(y_coord),
            .x2(0),
            .y2(0),
            .vld_out(vld_out_req),
            .add1(ld_addr_out),
            .add2(0),
            .stall_out(resp_stall),
            .vld_in_1(fetch_vld),
            .vld_in_2(1'b0),
            .packet(f_issue_out)
        );
        

        //fetch response unit        
        logic reading_fetch;
        fetch_response_unit #(.X_COORD(X_COORD), .Y_COORD(Y_COORD))
        fetch_resp_unit
        (
            .clk(clk),
            .arst_n(arst_n),
            .stall(resp_stall),
            .read(f_r_unit_read), 
            .vld_in(vld_in),
            .from_router(din),
            .reading(reading_fetch), 
            .vld_out(vld_out_resp),
            .to_router(f_resp_out),
            .from_mem(mem_to_fetch),
            .mem_addr(fr_addr_out),
            .mem_re(fr_unit_re)
        );
        
        //vectorization unit
        logic reading_vect;
        logic [VECTOR_LENGTH-1 : 0] vector_fetched;
        vectorization_unit
        vect_unit
        (
            .clk(clk),
            .arst_n(arst_n),
            .vld_in(vld_in),
            .din(din),
            .reading(reading_vect),
            .vld_out(vector_valid),
            .dout(vector_fetched)
        );
        
    assign mac_in = vector_valid ? vector_fetched : mem_to_mac;
    assign dout = resp_stall ? f_issue_out : f_resp_out;
    assign vld_out = vld_out_req || vld_out_resp;
    assign reading = reading_fetch || reading_vect;

endmodule
