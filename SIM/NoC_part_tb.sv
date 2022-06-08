import my_pkg::*;

module NoC_part_tb #(
    parameter string INS_PATH = "/users/students/r0875167/Dataset/sweep_feature/FEAT_40/imem_partitioned/",
    parameter string DATA_PATH = "/users/students/r0875167/Dataset/sweep_feature/FEAT_40/dmem_partitioned/",
    parameter string REF_FILE = "/users/students/r0875167/Dataset/sweep_feature/FEAT_40/reference_partitioned.txt",
    parameter string REPORT_FILE = "/users/students/r0875167/GNN-on-server/GNN-accelerator/generated_reports/SIM/FEAT_40.txt"
)
    ();

    logic arst_n, clk;

    NoC
    DUT(
        .arst_n(arst_n),
        .clk(clk)
    );

    //logic [VECTOR_LENGTH-1:0] reference [0 : NODE_NO-1];
    //logic [VECTOR_LENGTH-1:0] mem_content [0 : PE_NUMBER*MEM_HEIGHT-1];
    //logic [VECTOR_LENGTH-1:0] results [0 : NODE_NO-1];
    
    logic [0:PE_NUMBER-1] pe_stall;
    logic [0:PE_NUMBER-1] conflicts;
    logic done_signal [1:MESH_SIZE][1:MESH_SIZE];

    int index;

    //initial $readmemb(REF_FILE, reference);

    //assign results vector:
    genvar x,y,i;
	/*
    generate
        for(y=1; y<=MESH_SIZE; y++) begin
            for(x=1; x<=MESH_SIZE; x++) begin
                for(i=0; i<MEM_HEIGHT; i++) begin
                    localparam index = i + MEM_HEIGHT*(x-1) + MESH_SIZE*MEM_HEIGHT*(y-1);
                    assign mem_content[index] = DUT.genblk1[y].genblk1[x].PE.memory_2.data[i];
                    //initial $display("index=%d, x=%d, y=%d", index, x, y);
                end
            end
        end
    endgenerate
	*/
    
    generate
        for(y=1; y<=MESH_SIZE; y++) begin
            for(x=1; x<=MESH_SIZE; x++) begin
                assign done_signal[x][y] = DUT.done[x][y];
                localparam index = x-1 + MESH_SIZE*(y-1);
                assign pe_stall[index] = DUT.genblk1[y].genblk1[x].PE.pc_stall;
                assign conflicts[index] = DUT.genblk1[y].genblk1[x].router.router_conflict;
            end
        end
    endgenerate
    
    //populate data memories:
    generate
        for(y=1; y<=MESH_SIZE; y++) begin
            for(x=1; x<=MESH_SIZE; x++) begin
                string DATA_FILE, INS_FILE;
                
                initial begin
                    string x_str = "";
                    string y_str = "";
                    x_str.itoa(x-1);
                    y_str.itoa(y-1);
                    DATA_FILE = {DATA_PATH, "PE_", x_str, "_", y_str, ".txt"};
                    INS_FILE = {INS_PATH, "PE_", x_str, "_", y_str, ".txt"};
                end
                
                initial begin
                    $readmemb(DATA_FILE, DUT.genblk1[y].genblk1[x].PE.memory_1.data);
                    $readmemb(INS_FILE, DUT.genblk1[y].genblk1[x].PE.instruction_mem.data);
                end
            end
        end
    endgenerate

    int cycles_no = 0;
    real stall_perc [0:PE_NUMBER-1] = '{PE_NUMBER{0}};
    int stall_cc [0:PE_NUMBER-1] = '{PE_NUMBER{0}};
    int conflicts_cc [0:PE_NUMBER-1] = '{PE_NUMBER{0}};
    int errors = 0;

    initial begin
        clk = 1;
        wait_and_check();
        generate_reports();
        $finish;
    end

    initial begin
        arst_n = 0;
        #3
        arst_n = 1;
    end

    int exec_finished[1:MESH_SIZE][1:MESH_SIZE];
    always begin
        #5
        clk = !clk;
        cycles_no++;
        foreach(pe_stall[i]) begin
            if(pe_stall[i]) begin
                stall_cc[i] = stall_cc[i] + 1;
            end
        end
        foreach(conflicts[i]) begin
            if(conflicts[i]) begin
                conflicts_cc[i] = conflicts_cc[i] + 1;
            end
        end
        for(int y=1; y<=MESH_SIZE; y++) begin
            for(int x=1; x<=MESH_SIZE; x++) begin
                if(done_signal[x][y]==1'b1 && exec_finished[x][y]==0) begin
                    exec_finished[x][y] = cycles_no;
                end
            end
        end
    end
    
    

    task wait_and_check();
        int index = 0;
        int j = 0;
        begin
            wait(DUT.layer_finished);
            
            for(int y=1; y<=MESH_SIZE; y++) begin
                for(int x=1; x<=MESH_SIZE; x++) begin
                    if(exec_finished[x][y]==0) begin
                        exec_finished[x][y] = cycles_no;
                    end
                end
            end
            
            foreach(stall_perc[i]) begin
                stall_perc[i] = real'(stall_cc[i])/real'(cycles_no);
            end
		    /*
            foreach(mem_content[index]) begin
                if(mem_content[index] !== 'x) begin
                   results[j] = mem_content[index];
                   j++;
                   //$display("index %d",index);
                   //$display("j %d", j);
                end
            end
            
            for(int i=0; i<NODE_NO; i++) begin
                if(reference[i] !== results[i] || results[i] === 'x) begin
                    //$display("Error at PE[%d][%d], address %d", x, y, i);
                    errors = errors + 1;
                end
            end
		    */
            $display("Layer finished in %d cycles", cycles_no);
            $display("%d errors found", errors);
        end
    endtask

    task generate_reports();
        int fd;
        begin
            fd = $fopen(REPORT_FILE, "a");
            $fdisplay(fd, "----------------------------------------------------------------------------------------");
            $fdisplay(fd, "PARAMETERS:\nNODE_NO = %6d\nFEATURE_SIZE = %3d\nMESH = %3d X%3d\nPARTITIONED", NODE_NO, FEATURES, MESH_SIZE, MESH_SIZE);
            $fdisplay(fd, "Error #: %d", errors);
            $fdisplay(fd, "Execution CC #: %d", cycles_no);
            $fdisplay(fd, "Stall perc. for each PE:");
            for(int y = 0; y < MESH_SIZE; y++) begin
                for(int x = 0; x < MESH_SIZE; x++) begin
                    $fdisplay(fd, "[%2d][%2d]: %.3f", x, y, stall_perc[x+MESH_SIZE*y]);
                end
            end
            $fdisplay(fd, "\nConflicts for each router:");
            for(int y = 0; y < MESH_SIZE; y++) begin
                for(int x = 0; x < MESH_SIZE; x++) begin
                    $fdisplay(fd, "[%2d][%2d]: %d", x, y, conflicts_cc[x+MESH_SIZE*y]);
                end
            end
            $fdisplay(fd, "\nExecution cycles:");
            for(int y = 1; y <= MESH_SIZE; y++) begin
                for(int x = 1; x <= MESH_SIZE; x++) begin
                    $fdisplay(fd, "[%2d][%2d]: %d", x, y, exec_finished[x][y]);
                end
            end
            $fclose(fd);
        end
    endtask
    

endmodule
