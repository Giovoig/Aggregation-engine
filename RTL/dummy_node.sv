import my_pkg::*;

module dummy_node 
    (
    output signed [PACKET_LENGTH - 1:0] n_up,
    output signed [PACKET_LENGTH - 1:0] s_up,
    output signed [PACKET_LENGTH - 1:0] w_up,
    output signed [PACKET_LENGTH - 1:0] e_up,
    
    output logic n_valid_out, w_valid_out, s_valid_out, e_valid_out,
    output logic is_reading_e, is_reading_n, is_reading_w, is_reading_s
    );
   
   assign {n_up, s_up, w_up, e_up} = {0, 0, 0, 0};
   assign {n_valid_out, s_valid_out, w_valid_out, e_valid_out} = { 0, 0, 0, 0};
   assign {is_reading_e, is_reading_n, is_reading_w, is_reading_s} = {0, 0, 0, 0};
   
endmodule