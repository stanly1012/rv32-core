/**********change has made**********
1. always load in that amount of instruction, but if it reach the end. 
set the insruction as invalid

2. observe that there is one clock period time delay in the output num_is_free,
// output num_is_free_next
**********************/

//`timescale 1ns/100ps
// `include "../sys_defs.svh"
module RS_Line(
    input                                       clock,
    input                                       reset,

    input [`WAYS-1:0] [`XLEN-1:0]               CDB_Data,
    input [`WAYS-1:0] [$clog2(`PRF)-1:0]        CDB_PRF_idx,
    input [`WAYS-1:0]                           CDB_valid,

    input                                       opa_valid_in, // indicate whether it is data or PRN, 1: data 0: PRN
    input                                       opb_valid_in, // assuming opx_valid_in is 0 when en == 0

    input                                       load_in, // high when dispatch
<<<<<<< HEAD
    input                                       inst_valid_in,
    input [`OLEN-1:0]                           offset_in,
    input [`PCLEN-1:0]                          PC_in,
    input ALU_FUNC                              Operation_in,

=======
    input ID_EX_PACKET                          id_rs_packet_in,
>>>>>>> final_project

    output ID_EX_PACKET                         rs_packet_out,
    output logic                                ready,
    // RS entry
<<<<<<< HEAD
    output logic [`XLEN-1:0]                    opa_out,
    output logic [`XLEN-1:0]                    opb_out,
    output logic [$clog2(`PRF)-1:0]             dest_PRF_idx_out,
    output logic [$clog2(`ROB)-1:0]             rob_idx_out,
    output logic                                is_free,

    output logic [`PCLEN-1:0]                   PC_out,
    output ALU_FUNC                             Operation_out,
    output logic [`OLEN-1:0]                    offset_out,
    output logic                                rd_mem_out,                        
    output logic                                wr_mem_out                         
=======
    output logic                                is_free

`ifdef VISUAL_DEBUGGER
    ,
    output reg                                  opa_valid_reg,
    output reg                                  opb_valid_reg
`endif
>>>>>>> final_project
);

    logic [`WAYS-1:0]                           opa_reg_is_from_CDB;
    logic [`WAYS-1:0]                           opb_reg_is_from_CDB;
`ifndef VISUAL_DEBUGGER
    reg                                         opa_valid_reg;
    reg                                         opb_valid_reg;
`endif

    reg [`XLEN-1:0]                             opa_reg_feed;
    reg [`XLEN-1:0]                             opb_reg_feed;
    logic                                       opa_valid_reg_feed;
    logic                                       opb_valid_reg_feed;

    assign ready = opa_valid_reg & opb_valid_reg;

    // watching CDB for broadcasting!!!
    generate
        for (genvar i = 0; i < `WAYS; i = i + 1) begin
            assign opa_reg_is_from_CDB[i] = ~opa_valid_reg && CDB_valid[i] && CDB_PRF_idx[i] == rs_packet_out.rs1_value;
            assign opb_reg_is_from_CDB[i] = ~opb_valid_reg && CDB_valid[i] && CDB_PRF_idx[i] == rs_packet_out.rs2_value;
        end
    endgenerate

    always_comb begin
        opa_reg_feed = rs_packet_out.rs1_value;
        opb_reg_feed = rs_packet_out.rs2_value;
        opa_valid_reg_feed = opa_valid_reg;
        opb_valid_reg_feed = opb_valid_reg;
        if (~is_free) begin
            for (int i = 0; i < `WAYS; i = i + 1) begin
                if (opa_reg_is_from_CDB[i]) begin
                    opa_reg_feed = CDB_Data[i];
                    opa_valid_reg_feed = 1'b1;
                end
                if (opb_reg_is_from_CDB[i]) begin
                    opb_reg_feed = CDB_Data[i];
                    opb_valid_reg_feed = 1'b1;
                end
            end
        end
    end
    
    always_ff @ (posedge clock) begin
<<<<<<< HEAD
//    $display("in small module, load_in: %b inst_valid_in: %b",load_in,inst_valid_in);
        if (reset | (~inst_valid_in & load_in)) begin
            is_free <= 1;
            opa_valid_reg <= 0;
            opb_valid_reg <= 0;
            opa_out <= 0;
            opb_out <= 0;
        end
        else if (load_in & inst_valid_in) begin
            is_free <= 0;
            opa_valid_reg <= opa_valid_in;
            opb_valid_reg <= opb_valid_in;
            opa_out <= opa_in;
            opb_out <= opb_in;
        end
        else begin
            opa_valid_reg <=  opa_valid_reg_feed;
            opb_valid_reg <=  opb_valid_reg_feed;
            opa_out <=  opa_reg_feed;
            opb_out <=  opb_reg_feed;
=======
        if(load_in & id_rs_packet_in.valid)begin
            is_free <= `SD 0;
            opa_valid_reg <= `SD opa_valid_in;
            opb_valid_reg <= `SD opb_valid_in;
        end
        else if (reset | (~id_rs_packet_in.valid & load_in)) begin
            is_free <= `SD 1;
            opa_valid_reg <= `SD 0;
            opb_valid_reg <= `SD 0;
        end
        else begin
            opa_valid_reg <= `SD  opa_valid_reg_feed;
            opb_valid_reg <= `SD  opb_valid_reg_feed;
>>>>>>> final_project
        end
    end

    always_ff @ (posedge clock) begin
<<<<<<< HEAD
        if (reset | (~inst_valid_in & load_in)) begin
            PC_out <=  0;
            Operation_out <=  ALU_ADD;
            offset_out <=  0;
            rd_mem_out <=  0;                          
            wr_mem_out <=  0; 
            dest_PRF_idx_out <=  0;
            rob_idx_out <=  0;
        end
        else if (load_in & inst_valid_in) begin
            PC_out <=  PC_in;
            Operation_out <=  Operation_in;
            offset_out <=  offset_in;
            rd_mem_out <=  rd_mem_in;                          
            wr_mem_out <=  wr_mem_in; 
            dest_PRF_idx_out <=  dest_PRF_idx_in;
            rob_idx_out <=  rob_idx_in;
=======
        if (load_in & id_rs_packet_in.valid) begin
            rs_packet_out <= `SD id_rs_packet_in;
        end 
        else if (reset | (~id_rs_packet_in.valid & load_in)) begin
            rs_packet_out <= `SD 0;
        end 
        else begin
            rs_packet_out.rs1_value <= `SD  opa_reg_feed;
            rs_packet_out.rs2_value <= `SD  opb_reg_feed;
>>>>>>> final_project
        end
    end
    
endmodule





module RS(
    input                                       clock,
    input                                       reset,

    input [`WAYS-1:0] [`XLEN-1:0]               CDB_Data,
    input [`WAYS-1:0] [$clog2(`PRF)-1:0]        CDB_PRF_idx,
    input [`WAYS-1:0]                           CDB_valid,   // always start from LSB, like 1, 11, 111, 1111

    input [`WAYS-1:0]                           opa_valid_in, // indicate whether it is data or PRN, 1: data 0: PRN
    input [`WAYS-1:0]                           opb_valid_in,

    input ID_EX_PACKET [`WAYS-1:0]              id_rs_packet_in,
    input                                       load_in, // ***high when dispatch***
<<<<<<< HEAD
    input [`WAYS-1:0]                           inst_valid_in,
    input [`WAYS-1:0] [`OLEN-1:0]               offset_in,
    input [`WAYS-1:0] [`PCLEN-1:0]              PC_in,
    input ALU_FUNC [`WAYS-1:0]                  Operation_in,

=======
>>>>>>> final_project

    input [`WAYS-1:0]                           ALU_occupied,
    output ID_EX_PACKET [`WAYS-1:0]             rs_packet_out,

<<<<<<< HEAD
    output logic [`WAYS-1:0] [`PCLEN-1:0]       PC_out,
    output ALU_FUNC [`WAYS-1:0]                 Operation_out ,
    output logic [`WAYS-1:0] [`OLEN-1:0]        offset_out,
=======
>>>>>>> final_project
    output logic [$clog2(`RS):0]                num_is_free,
    output logic [$clog2(`RS):0]                num_is_free_next,
// for debugging
    output wor   [`RS-1:0]                      load_in_hub,
    output logic [`RS-1:0]                      is_free_hub,
    output logic [`RS-1:0]                      ready_hub


);

//debug
    logic [$clog2(`WAYS):0]              free_decrease;
    logic [$clog2(`WAYS):0]              free_increase;
    logic   [`RS-1:0]                      reset_hub;
    wor [`RS-1:0]                             reset_hub_tmp;

    // in hubs
<<<<<<< HEAD
//    wor   [`RS-1:0]                           reset_hub;
    logic [`RS-1:0] [`XLEN-1:0]                 opa_in_hub;
    logic [`RS-1:0] [`XLEN-1:0]                 opb_in_hub;
    logic [`RS-1:0]                             opa_valid_in_hub;
    logic [`RS-1:0]                             opb_valid_in_hub;
    logic [`RS-1:0]                             rd_mem_in_hub;
    logic [`RS-1:0]                             wr_mem_in_hub;                                
    logic [`RS-1:0] [$clog2(`PRF)-1:0]          dest_PRF_idx_in_hub;
    logic [`RS-1:0] [$clog2(`ROB)-1:0]          rob_idx_in_hub;
    wor   [`RS-1:0]                             load_in_hub;
    logic [`RS-1:0]                             inst_valid_in_hub;
    logic [`RS-1:0] [`OLEN-1:0]                 offset_in_hub;
    logic [`RS-1:0] [`PCLEN-1:0]                PC_in_hub;
    ALU_FUNC  [`RS-1:0]                         Operation_in_hub ;
    
    // out hubs
//    logic [`RS-1:0]                             ready_hub;
    logic [`RS-1:0] [`XLEN-1:0]                 opa_out_hub;
    logic [`RS-1:0] [`XLEN-1:0]                 opb_out_hub;
    logic [`RS-1:0] [$clog2(`PRF)-1:0]          dest_PRF_idx_out_hub;
    logic [`RS-1:0] [$clog2(`ROB)-1:0]          rob_idx_out_hub;
//    logic [`RS-1:0]                             is_free_hub;
    logic [`RS-1:0] [`PCLEN-1:0]                PC_out_hub;
    ALU_FUNC  [`RS-1:0]                                  Operation_out_hub ;
    logic [`RS-1:0] [`OLEN-1:0]                 offset_out_hub;
    logic [`RS-1:0]                             rd_mem_out_hub;                         
    logic [`RS-1:0]                             wr_mem_out_hub;

    // other internals
//    reg   [$clog2(`RS):0]                       num_is_free;
//    logic [$clog2(`RS):0]                       num_is_free_next;
//    logic [$clog2(`WAYS):0]                     free_decrease;
//    logic [$clog2(`WAYS):0]                     free_increase;
=======
    logic [$clog2(`WAYS):0]                     ALU_idx;
    logic [`RS-1:0]                             opa_valid_in_hub;
    logic [`RS-1:0]                             opb_valid_in_hub;
    ID_EX_PACKET [`RS-1:0]                      id_rs_packet_in_hub;
    ID_EX_PACKET [`RS-1:0]                      rs_packet_out_hub;

    
    // out hubs
>>>>>>> final_project
    logic [`WAYS-1:0] [`XLEN-1:0]               opa_in_processed;
    logic [`WAYS-1:0] [`XLEN-1:0]               opb_in_processed;
    logic [`WAYS-1:0] [`WAYS-1:0]               opa_is_from_CDB;
    logic [`WAYS-1:0] [`WAYS-1:0]               opb_is_from_CDB; 
    logic [`WAYS-1:0]                           opa_valid_in_processed;
    logic [`WAYS-1:0]                           opb_valid_in_processed;


// for input selector
    logic [`RS*`WAYS-1:0]   in_gnt_bus;
    logic [`RS*`WAYS-1:0]   out_gnt_bus;
    logic                   has_match;

`ifdef VISUAL_DEBUGGER
    reg [`RS-1:0] opa_valid_reg;
    reg [`RS-1:0] opb_valid_reg;
`endif



    assign num_is_free_next = (num_is_free - free_decrease + free_increase);

    // watching CDB for night ship!!!
    generate
        for (genvar i = 0; i < `WAYS; i = i + 1) begin
            assign load_in_hub = in_gnt_bus[(i+1)*`RS-1 -: `RS];
            assign reset_hub_tmp = out_gnt_bus[(i+1)*`RS-1 -: `RS];
            for (genvar j = 0; j < `WAYS; j = j + 1) begin
                assign opa_is_from_CDB[i][j] = ~opa_valid_in[i] && CDB_valid[j] && CDB_PRF_idx[j] == id_rs_packet_in[i].rs1_value;
                assign opb_is_from_CDB[i][j] = ~opb_valid_in[i] && CDB_valid[j] && CDB_PRF_idx[j] == id_rs_packet_in[i].rs2_value;
            end
        end
    endgenerate


    always_comb begin
        for (int i = 0; i < `WAYS; i = i + 1) begin
            opa_in_processed[i] = id_rs_packet_in[i].rs1_value;
            opb_in_processed[i] = id_rs_packet_in[i].rs2_value;
            opa_valid_in_processed[i] = opa_valid_in[i];
            opb_valid_in_processed[i] = opb_valid_in[i];
            for (int j = 0; j < `WAYS; j = j + 1) begin
                if (opa_is_from_CDB[i][j]) begin
                    opa_in_processed[i] = CDB_Data[j];
                    opa_valid_in_processed[i] = 1'b1;
                end
                if (opb_is_from_CDB[i][j]) begin
                    opb_in_processed[i] = CDB_Data[j];
                    opb_valid_in_processed[i] = 1'b1;
                end
            end
        end
    end

    rs_psel_gen #(`WAYS,`RS) input_selector(.en(load_in),.reset(1'b0),.req(is_free_hub | reset_hub), .gnt_bus(in_gnt_bus));

    
    // input selector
    // selecting `WAYS RS Entries to load_in
    always_comb begin
        id_rs_packet_in_hub = 0;
        opa_valid_in_hub = 0;
        opb_valid_in_hub = 0;
<<<<<<< HEAD
        rd_mem_in_hub = 0;
        wr_mem_in_hub = 0;
        dest_PRF_idx_in_hub = 0;
        rob_idx_in_hub = 0;
        offset_in_hub = 0;
        PC_in_hub = 0;
        Operation_in_hub = '{`RS{ALU_ADD}};
=======
>>>>>>> final_project
        free_decrease = 0;
        inst_valid_in_hub = 0;
        for (int i = 0; i < `RS; i = i + 1) begin
            if(load_in_hub[i]) begin
                if(free_decrease < `WAYS) begin
<<<<<<< HEAD
                    inst_valid_in_hub[i] = inst_valid_in[free_decrease];
                    opa_in_hub[i] = opa_in_processed[free_decrease];
                    opb_in_hub[i] = opb_in_processed[free_decrease];
                    opa_valid_in_hub[i] = opa_valid_in_processed[free_decrease];
                    opb_valid_in_hub[i] = opb_valid_in_processed[free_decrease];
                    // pipeline related
                    rd_mem_in_hub[i] = rd_mem_in[free_decrease];
                    wr_mem_in_hub[i] = wr_mem_in[free_decrease];
                    dest_PRF_idx_in_hub[i] = dest_PRF_idx_in[free_decrease];
                    rob_idx_in_hub[i] = rob_idx_in[free_decrease];
                    offset_in_hub[i] = offset_in[free_decrease];
                    PC_in_hub[i] = PC_in[free_decrease];
                    Operation_in_hub[i] = Operation_in[free_decrease];
                    if(inst_valid_in[free_decrease]) free_decrease = free_decrease + 1;
=======
                    id_rs_packet_in_hub[i]           = id_rs_packet_in[free_decrease];
                    id_rs_packet_in_hub[i].rs1_value = opa_in_processed[free_decrease];
                    id_rs_packet_in_hub[i].rs2_value = opb_in_processed[free_decrease];
                    opa_valid_in_hub[i]              = opa_valid_in_processed[free_decrease];
                    opb_valid_in_hub[i]              = opb_valid_in_processed[free_decrease];
                    // pipeline related
                    if(id_rs_packet_in[free_decrease].valid) free_decrease = free_decrease + 1;
>>>>>>> final_project
                end else break;
            end
        end
    end

    always_ff @ (posedge clock) begin
    // watch CDB
<<<<<<< HEAD
//        $display("opa_is_from_CDB = %b",opa_is_from_CDB);
//        $display("opb_is_from_CDB = %b",opb_is_from_CDB);
    // processing
//        $display("in rs.sv, opa_in[0]: %h opb_in[0]: %h",opa_in,opb_in);
//        $display("opa_in_processed[1]: %h opb_in_processed[1]: %h",opa_in_processed[1],opb_in_processed[1]);
//        $display("opa_valid_in_processed: %b opb_valid_in_processed: %b",opa_valid_in_processed, opb_valid_in_processed);
//        $display("opa_in_hub[0]: %h opb_in_hub[0]: %h",opa_in_hub[0],opb_in_hub[0]);
//        $display("opa_valid_in_hub[0]: %b opb_valid_in_hub[0]: %b",opa_valid_in_hub[0],opb_valid_in_hub[0]);
//        $display("load_in_hub: %h",load_in_hub);
//        $display("free_decrease: %d free_increase: %d",free_decrease,free_increase); 
//        $display("opa_out_hub[0]: %h opb_out_hub[0]: %h",opa_out_hub[0],opb_out_hub[0]);
//        $display("load_in: %b is_free_hub: %b load_in_hub: %b ready_hub:%b inst_out_valid:%b inst_valid_in:%b",load_in,is_free_hub, load_in_hub,ready_hub,inst_out_valid,inst_valid_in); 
//        $display("reset_hub: %b",reset_hub);
        if (reset) begin
            num_is_free <= `RS;
        end
        else begin
            num_is_free <= num_is_free_next;
=======

        if (reset) begin
            num_is_free <= `SD `RS;
        end
        else begin
            num_is_free <= `SD num_is_free_next;
>>>>>>> final_project
        end

    end

RS_Line lines [`RS-1:0] (
        // inputs
        .clock(clock),
        .reset(reset_hub),
        .CDB_Data(CDB_Data),
        .CDB_PRF_idx(CDB_PRF_idx),
        .CDB_valid(CDB_valid),
        
        .opa_valid_in(opa_valid_in_hub),
        .opb_valid_in(opb_valid_in_hub),
        .load_in(load_in_hub),
<<<<<<< HEAD
        .inst_valid_in(inst_valid_in_hub), // when load_in = 1, it does represent whether the inst is valid or not, when load_in = 0, it should make no difference
        .offset_in(offset_in_hub),
        .PC_in(PC_in_hub),
        .Operation_in(Operation_in_hub),
=======
        .id_rs_packet_in(id_rs_packet_in_hub),
>>>>>>> final_project

        // outputs
        .rs_packet_out(rs_packet_out_hub),
        .ready(ready_hub),
<<<<<<< HEAD
        .opa_out(opa_out_hub),
        .opb_out(opb_out_hub),
        .dest_PRF_idx_out(dest_PRF_idx_out_hub),
        .rob_idx_out(rob_idx_out_hub),
        .is_free(is_free_hub),
        .PC_out(PC_out_hub),
        .Operation_out(Operation_out_hub),
        .offset_out(offset_out_hub),
        .rd_mem_out(rd_mem_out_hub),
        .wr_mem_out(wr_mem_out_hub)           
=======
        .is_free(is_free_hub)
`ifdef VISUAL_DEBUGGER
        ,
        .opa_valid_reg,
        .opb_valid_reg
`endif
>>>>>>> final_project
    );

    rs_psel_gen #(`WAYS,`RS) output_selector(.en(1'b1),.reset(reset),.req(ready_hub),.gnt_bus(out_gnt_bus));


// output selector
    always_comb begin
        free_increase = 0;
<<<<<<< HEAD
        opa_out = 0;
        opb_out = 0;
        dest_PRF_idx_out = 0;
        rob_idx_out = 0;
        PC_out = 0;
        Operation_out = '{`WAYS{ALU_ADD}};
        offset_out = 0;
        rd_mem_out = 0;
        wr_mem_out = 0;
        inst_out_valid = 0;
        if(~reset) begin            
            for (int i = 0; i < `RS; i = i + 1) begin
//            $display("i:%d free_increase: %d num_is_free_next: %d",i, free_increase,num_is_free_next);
                if (reset_hub[i]) begin
                    inst_out_valid[free_increase] = 1;
                    opa_out[free_increase] = opa_out_hub[i];
                    opb_out[free_increase] = opb_out_hub[i];
                    dest_PRF_idx_out[free_increase] = dest_PRF_idx_out_hub[i];
                    rob_idx_out[free_increase] = rob_idx_out_hub[i];
                    PC_out[free_increase] = PC_out_hub[i];
                    Operation_out[free_increase] = Operation_out_hub[i];
                    offset_out[free_increase] = offset_out_hub[i];
                    rd_mem_out[free_increase] = rd_mem_out_hub[i];        
                    wr_mem_out[free_increase] = wr_mem_out_hub[i];
                    free_increase = free_increase + 1;
=======
        rs_packet_out = 0;
        reset_hub = reset_hub_tmp;
        ALU_idx = 0;
        has_match = 0;
        if(~reset) begin            
            for (int i = 0; i < `RS; i = i + 1) begin
                if (reset_hub_tmp[i]) begin
                    has_match = 0;
                    if((ALU_idx < `WAYS)) begin
                        for(int j = 0; j < `WAYS; j = j + 1) begin
                            // to be changed (delete j <`WAYS)
                            if((j>= ALU_idx) && ~ALU_occupied[j]) begin
                                rs_packet_out[j] = rs_packet_out_hub[i];
                                free_increase = free_increase + 1;
                                ALU_idx = j + 1;
                                has_match = 1;
                                break;
                            end 
                        end
                        if(~has_match) begin
                            reset_hub[i] = 0;                    
                        end
                    end else begin
                        reset_hub[i] = 0;                    
                    end
>>>>>>> final_project
                end
            end
        end
    end




endmodule