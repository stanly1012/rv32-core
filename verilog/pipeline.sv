/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  pipeline.v                                          //
//                                                                     //
//  Description :  Top-level module of the verisimple pipeline;        //
//                 This instantiates and connects the 5 stages of the  //
//                 Verisimple pipeline togeather.                      //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`ifndef __PIPELINE_V__
`define __PIPELINE_V__

`timescale 1ns/100ps

module pipeline (

	input         clock,                    // System clock
	input         reset,                    // System reset

	input [3:0]   mem2proc_response,        // Tag from memory about current request
	input [63:0]  mem2proc_data,            // Data coming back from memory
	input [3:0]   mem2proc_tag,              // Tag from memory about current reply
	
	output logic [1:0]  			proc2mem_command,    // command sent to memory
	output logic [`XLEN-1:0] 		proc2mem_addr,      // Address sent to memory

	output logic [63:0] 	proc2mem_data,      // Data sent to memory
	output MEM_SIZE 		proc2mem_size,          // data size sent to memory
	

	output logic [3:0]  pipeline_completed_insts,
	output EXCEPTION_CODE   pipeline_error_status,
	output logic [4:0]  pipeline_commit_wr_idx,
	output logic [`XLEN-1:0] pipeline_commit_wr_data,
	output logic        pipeline_commit_wr_en,
	output logic [`XLEN-1:0] pipeline_commit_NPC
	

	
);


    // between processor and icache controller
    // TODO: connect these ports
    logic [`WAYS-1:0] [63:0] 	icache_to_proc_data;
    logic [`WAYS-1:0] 				icache_to_proc_data_valid;
    logic [`WAYS-1:0] [31:0] 	proc_to_icache_addr;
    logic [`WAYS-1:0] 				proc_to_icache_en;


    // between icache controller and icache mem
    logic [4:0] 						icache_to_cachemem_index;
    logic [7:0] 						icache_to_cachemem_tag;
    logic 									icache_to_cachemem_en;
    logic [`WAYS-1:0] [4:0] icache_to_cachemem_rd_idx;
    logic [`WAYS-1:0] [7:0] icache_to_cachemem_rd_tag;
    logic [`WAYS-1:0][63:0] cachemem_to_icache_data;
    logic [`WAYS-1:0] 			cachemem_to_icache_valid;

    // between icache controller and mem
    logic [1:0] 				icache_to_mem_command;
    logic [`XLEN-1:0] 			icache_to_mem_addr;    // should be output of the pipeline
    logic [3:0] 				mem_to_icache_response;
    logic [3:0] 				mem_to_icache_tag;

    // between icache mem and mem
    logic [63:0] mem_to_cachemem_data; // should be input of the pipeline



		// Pipeline register enables
		logic   if_id_enable, id_ex_enable, ex_mem_enable, mem_wb_enable;

		// Outputs from IF-Stage

		IF_ID_PACKET[`WAYS-1 : 0] if_packet;

	// Outputs from IF/ID Pipeline Register
	IF_ID_PACKET[`WAYS-1 : 0] if_id_packet;

	// Outputs from ID stage
	ID_EX_PACKET [`WAYS-1 : 0] id_packet;


	logic [`WAYS-1:0]	opa_valid;
	logic [`WAYS-1:0]	opb_valid;


	// Outputs from ID/Rob&RS Pipeline Register
	ID_EX_PACKET[`WAYS-1 : 0] id_ex_packet;
	logic rob_is_full;
	logic rs_is_full;
	
  	logic [`WAYS-1:0] [4:0]        				  	dest_ARN;
  	logic [`WAYS-1:0] [$clog2(`PRF)-1:0]            dest_PRN;
  	logic [`WAYS-1:0]                               reg_write;
  	logic [`WAYS-1:0]                               is_branch;
  	logic [`WAYS-1:0]                               valid;
  	logic [`WAYS-1:0]                               illegal;
  	logic [`WAYS-1:0]                               halt;
  	logic [`WAYS-1:0] [`XLEN-1:0]                   PC;
  	logic [`WAYS-1:0] [`XLEN-1:0]                   target;
  	logic [`WAYS-1:0]                               branch_direction;

 	ID_EX_PACKET [`WAYS-1 : 0] 					 	id_packet_tmp;
	logic [`WAYS-1:0]								opa_valid_tmp;
	logic [`WAYS-1:0]								opb_valid_tmp;
	logic [`WAYS-1:0]								reg_write_tmp;
	
    
    // Wires for Branch Predictor
    logic [`XLEN-1:0]                       next_PC;
    logic [`WAYS-1:0]                       predictions;


  // Outputs from Rob-Stage
  	logic [$clog2(`ROB)-1:0]                  next_tail;
  	logic [`WAYS-1:0] [4:0] 				  dest_ARN_out;
  	logic [`WAYS-1:0] [$clog2(`PRF)-1:0]      dest_PRN_out;

  	logic [`WAYS-1:0]                         valid_out;
  	logic [`WAYS-1:0]                         direction_out;
  	logic [`WAYS-1:0]                         target_out;

  	logic [$clog2(`ROB):0]                    next_num_free;
  	logic                                     except;
  	logic [`XLEN-1:0]                         except_next_PC;

  	logic [`WAYS-1:0] [`XLEN-1:0]             PC_out;
  	logic [`WAYS-1:0]                         direction_out;
  	logic [`WAYS-1:0] [`XLEN-1:0]             target_out;
  	logic [`WAYS-1:0]                         valid_update;
	logic [$clog2(`WAYS):0]                   num_committed;


	// Outputs from Rs-Stage
  ID_EX_PACKET [`WAYS-1:0]             rs_packet_out;

  logic [$clog2(`RS):0]                num_is_free;


	// Outputs from EX-Stage
	EX_MEM_PACKET[`WAYS-1 : 0]      ex_packet;
	logic [`WAYS-1:0] 							ALU_occupied;




	
  
//--------------CDB--------------------
 
  	logic [`WAYS-1:0] [`XLEN-1:0]               CDB_Data;
  	logic [`WAYS-1:0] [$clog2(`PRF)-1:0]        CDB_PRF_idx;
  	logic [`WAYS-1:0]                           CDB_valid;
	logic [`WAYS-1:0] [$clog2(`ROB)-1:0]        CDB_ROB_idx;
  	logic [`WAYS-1:0]                           CDB_direction;
  	logic [`WAYS-1:0] [`XLEN-1:0]               CDB_target;

  	generate
      	for(genvar i = 0; i < `WAYS; i = i + 1) begin
			assign CDB_Data[i]      = ex_packet[i].alu_result;
			assign CDB_PRF_idx[i]   = ex_packet[i].dest_PRF_idx;
			assign CDB_valid[i]     = ex_packet[i].valid;
			assign CDB_ROB_idx[i]   = ex_packet[i].rob_idx;
			assign CDB_direction[i] = ex_packet[i].take_branch;
			assign CDB_target[i]    = ex_packet[i].take_branch ? ex_packet[i].alu_result: ex_packet[i].NPC ;   			
		end
	endgenerate

//-----------------------for milestone2 input-----------------------------
	assign mem_to_icache_response = mem2proc_response;
	assign mem2proc_data		  = mem_to_cachemem_data;
	assign mem_to_icache_tag 	  = mem2proc_tag;

//-----------------------for milestone2 input-----------------------------
	
//-----------------------for milestone2 output----------------------------
	assign proc2mem_command = icache_to_mem_command;
	assign proc2mem_addr = icache_to_mem_addr;
	//if it's an instruction, then load a double word (64 bits)

	assign proc2mem_data = MEM_SIZE'b0;
	assign proc2mem_size = DOUBLE;
//-------------------------------------------------------------
	assign pipeline_completed_insts = {{(4-$clog2(`WAYS)){1'b0}},num_committed};
	assign pipeline_error_status =  illegal_out             ? ILLEGAL_INST :
	                                halt_out                ? HALTED_ON_WFI :
	                                (mem2proc_response==4'h0)  ? LOAD_ACCESS_FAULT :
	                                NO_ERROR;
	
//	assign pipeline_commit_wr_idx = wb_reg_wr_idx_out;
//	assign pipeline_commit_wr_data = wb_reg_wr_data_out;
//	assign pipeline_commit_wr_en = wb_reg_wr_en_out;
//	assign pipeline_commit_NPC = mem_wb_NPC;




//-----------------------for milestone2 output--------------------------------

	assign proc_to_icache_en = {`WAYS{1'b1}};

    icache icache_0(
        .clock(clock),
        .reset(reset),

        .Imem2proc_response(mem_to_icache_response),
        .Imem2proc_tag(mem_to_icache_tag),

        .proc2Icache_addr(proc_to_icache_addr),
        .proc2Icache_en(proc_to_icache_en),
        .cachemem_data(cachemem_to_icache_data), // read an instruction when it's not in a cache put it inside a cache
        .cachemem_valid(cachemem_to_icache_valid),

// output
        .proc2Imem_command(icache_to_mem_command), 
        .proc2Imem_addr(icache_to_mem_addr),

        .Icache_data_out(icache_to_proc_data), // value is memory[proc2Icache_addr]
        .Icache_valid_out(icache_to_proc_data_valid),      // when this is high

        .rd_idx(icache_to_cachemem_rd_idx),
        .rd_tag(icache_to_cachemem_rd_tag),

        .current_index(icache_to_cachemem_index),
        .current_tag(icache_to_cachemem_tag),
        .data_write_enable(icache_to_cachemem_en)
    );

    cache cache_0(
        .clock(clock),
        .reset(reset), 

        .wr_en(icache_to_cachemem_en),
        .wr_idx(icache_to_cachemem_index),
        .wr_tag(icache_to_cachemem_tag),
        .wr_data(mem_to_cachemem_data), 

        .rd_idx(icache_to_cachemem_rd_idx),
        .rd_tag(icache_to_cachemem_rd_tag),

        .rd_data(cachemem_to_icache_data),
        .rd_valid(cachemem_to_icache_valid)
    );





//////////////////////////////////////////////////
//                                              //
//                  IF-Stage                    //
//                                              //
//////////////////////////////////////////////////

	//these are debug signals that are now included in the packet,
	//breaking them out to support the legacy debug modes
//	assign if_NPC_out        = if_packet.NPC;
//	assign if_IR_out         = if_packet.inst;
//	assign if_valid_inst_out = if_packet.valid;

	if_stage if_stage_0 (
		// Inputs
		.clock (clock),
		.reset (reset),
		.stall(rob_is_full),

		.pc_predicted(next_PC),
		.ex_mem_take_branch(except),
		.ex_mem_target_pc_with_predicted(except_next_PC),

		.Icache2proc_data(icache_to_proc_data),
        .Icache2proc_valid(icache_to_proc_data_valid),
		
		// Outputs
		.proc2Imem_addr(proc_to_icache_addr),
		.if_packet_out(if_packet)
	);

    branch_pred #(.SIZE(128)) predictor (
        .clock,
        .reset,

        .PC(if_packet[0].PC),

        .PC_update(PC_out),
        .direction_update(direction_out),
        .target_update(target_out),
        .valid_update,
//output
        .next_PC,
        .predictions
    );



   
//////////////////////////////////////////////////
//                                              //
//                  ID-Stage                    //
//                                              //
//////////////////////////////////////////////////
	
	id_stage id_stage_0 (// Inputs
		.clock(clock),
		.reset(reset),

		.reg_idx_wr_CDB(CDB_PRF_idx),
		.wr_en_CDB(CDB_valid),
		.wr_dat_CDB(CDB_Data),

        .RRAT_ARF_idx,
        .RRAT_idx_valid,
        .RRAT_ARF_idx,
        .except,
		.predictions, // newly-added

		.if_id_packet_in(if_packet),
		.predictions,

		// Outputs
		.id_packet_out(id_packet),
		.opa_valid,
		.opb_valid,
		.dest_arn_valid(reg_write)

	);


//////////////////////////////////////////////////
//                                              //
//       ID/ROB & RS Pipeline Register          //
//                                              //
//////////////////////////////////////////////////

//	assign id_ex_NPC        = id_ex_packet.NPC;
//	assign id_ex_IR         = id_ex_packet.inst;
//	assign id_ex_valid_inst = id_ex_packet.valid;
assign rob_is_full = next_num_free < `WAYS;
assign rs_is_full  = num_is_free < `WAYS;
always_ff@(posedge clock) begin
	if(rob_is_full | rs_is_full) begin
		id_packet_tmp 				<= `SD id_packet | id_packet_tmp;
		opa_valid_tmp				<= `SD opa_valid | opa_valid_tmp;
		opb_valid_tmp				<= `SD opb_valid | opb_valid_tmp;
		reg_write_tmp				<= `SD reg_write | reg_write_tmp;
	end else begin
		id_packet_tmp <= `SD 0;
		opa_valid_tmp <= `SD 0;
		opb_valid_tmp <= `SD 0;
		reg_write_tmp <= `SD 0;
	end
end



	assign id_ex_enable = ~rob_is_full & ~rs_is_full;
	// synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		if (reset | rob_is_full) begin
			id_ex_packet <= `SD 0;
		end else begin // if (reset)
			if (id_ex_enable) begin
				id_ex_packet <= `SD id_packet_tmp| id_packet;
			end
		end // else: !if(reset)
	end // always


//////////////////////////////////////////////////
//                                              //
//                   ROB-Stage                  //
//                                              //
//////////////////////////////////////////////////
generate
  for(genvar i = 0; i < `WAYS; i = i + 1) begin
		assign dest_ARN[i]          = id_ex_packet[i].inst.r.rd;
		assign dest_PRN[i]          = id_ex_packet[i].dest_PRF_idx;
		assign is_branch[i]         = id_ex_packet[i].cond_branch | id_ex_packet[i].uncond_branch;
		assign valid[i]             = id_ex_packet[i].valid;
		assign illegal[i]			= id_ex_packet[i].illegal;
		assign halt[i]				= id_ex_packet[i].halt;
		assign PC[i]				= id_ex_packet[i].PC;
		assign target[i]		    = next_PC;
		assign branch_direction[i]  = predictions[i];		
	end
endgenerate



  rob Rob(
    .clock,
    .reset,

    // wire declarations for rob inputs/outputs
    .CDB_ROB_idx,
    .CDB_valid,
    .CDB_direction,
    .CDB_target,

    .dest_ARN,
    .dest_PRN,
    .reg_write,
    .is_branch,
    .valid,
		
    .PC,
    .target,
    .branch_direction,

	.illegal,
	.halt,

// output
    .next_tail,
    .dest_ARN_out,
    .dest_PRN_out,
    .valid_out,

    .next_num_free,
	.proc_nuke(except),
    .next_pc(except_next_PC),

    .PC_out,
    .direction_out,
    .target_out,
	.num_committed
);
//////////////////////////////////////////////////
//                                              //
//                   RS-Stage                   //
//                                              //
//////////////////////////////////////////////////

 RS Rs (
        // inputs
        .clock,
        .reset,
        .CDB_Data,
        .CDB_PRF_idx,
        .CDB_valid,
        .opa_valid_in(opa_valid),
        .opb_valid_in(opb_valid),
        .id_rs_packet_in(id_ex_packet),                            
        .load_in(1),
        .ALU_occupied,

        // output
        .rs_packet_out,

        .num_is_free

    );






//////////////////////////////////////////////////
//                                              //
//                  EX-Stage                    //
//                                              //
//////////////////////////////////////////////////
	ex_stage ex_stage_0 (
		// Inputs
		.clock(clock),
		.reset(reset),
		.id_ex_packet_in(id_ex_packet),
		// Outputs
		.ex_packet_out(ex_packet)
		.occupied_hub(ALU_occupied)
	);

endmodule  // module verisimple
`endif // __PIPELINE_V__
