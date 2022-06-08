`ifndef REGISTER
`define REGISTER
    `define REG(r_width, r_name) \
    logic [r_width-1:0] ``r_name``_next, r_name;\
    logic ``r_name``_we;\
    register #(.WIDTH(r_width)) ``r_name``_r(.clk(clk), .arst_n(arst_n), .din(``r_name``_next), .qout(``r_name``), .we(``r_name``_we))
`endif

package my_pkg;

    parameter int DATA_WIDTH = 8;
    parameter int MEM_HEIGHT = 16384; //2^14
    parameter int INSTR_MEM_HEIGHT = 32768; //2^15
    //parameter int MEM_HEIGHT = 1829;
    //parameter int INSTR_MEM_HEIGHT = 52183;
    parameter int OUT_SCALE = 0;
    parameter int FEATURES = 40;
    parameter int MESH_SIZE = 8;
    parameter int OPCODE_LENGTH = 3;
    parameter int LOG2_FIFO_DEPTH = 8;
    parameter int NODE_NO = 34546;


    parameter int COORD_LENGTH = MESH_SIZE == 1 ? 1 : $clog2(MESH_SIZE);
    parameter int ADDR_LENGTH = $clog2(MEM_HEIGHT)+2*COORD_LENGTH;
    parameter int INSTRUCTION_LENGTH = OPCODE_LENGTH+ADDR_LENGTH;
    parameter int VECTOR_LENGTH = DATA_WIDTH*FEATURES;
    parameter int PE_NUMBER = MESH_SIZE*MESH_SIZE;
    
    //  PACKET FORMAT:
    //  FR = fetch request
    // | 1 | X_DEST | Y_DEST | X_SRC | Y_SRC | LOC_ADDRESS | for fetch request
    // | 0 | X_DEST | Y_DEST | PAYLOAD | for fetch response
    // vvv
    // |1|LOG2(SIZEX)|LOG2(SIZEY)|LOG2(SIZEX)|LOG2(SIZEY)|DATA_WIDTH or log2(MEM_HEIGHT)|
    parameter int PACKET_LENGTH = (DATA_WIDTH > ADDR_LENGTH) ? 1 + 2*COORD_LENGTH + DATA_WIDTH : 1 + 2*COORD_LENGTH + ADDR_LENGTH; 
    
    //let LOC(address) = address[ADDR_LENGTH-2*$clog2(MESH_SIZE)-1 : 0];
    //let X(address) = address[ADDR_LENGTH-$clog2(MESH_SIZE)-1 : ADDR_LENGTH-2*$clog2(MESH_SIZE)];
    //let Y(address) = address[ADDR_LENGTH-1 : ADDR_LENGTH-$clog2(MESH_SIZE)]; 
    
    parameter LOCAL = 3'd0;  
    parameter EAST  = 3'd1; 
    parameter NORTH = 3'd2;  
    parameter WEST  = 3'd3;  
    parameter SOUTH = 3'd4;  
    
    parameter NO_REQ = 5'b00000;
    parameter LOCAL_REQ = 5'b00001;
    parameter EAST_REQ = 5'b00010;
    parameter NORTH_REQ = 5'b00100;
    parameter WEST_REQ = 5'b01000;
    parameter SOUTH_REQ = 5'b10000;

//two different clocks? -> synchronizers


endpackage
