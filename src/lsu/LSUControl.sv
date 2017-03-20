/*******************************************************************************
#                        NORTH CAROLINA STATE UNIVERSITY
#
#                              AnyCore Project
# 
# AnyCore written by NCSU authors Rangeen Basu Roy Chowdhury and Eric Rotenberg.
# 
# AnyCore is based on FabScalar which was written by NCSU authors Niket K. 
# Choudhary, Brandon H. Dwiel, and Eric Rotenberg.
# 
# AnyCore also includes contributions by NCSU authors Elliott Forbes, Jayneel 
# Gandhi, Anil Kumar Kannepalli, Sungkwan Ku, Hiran Mayukh, Hashem Hashemi 
# Najaf-abadi, Sandeep Navada, Tanmay Shah, Ashlesha Shastri, Vinesh Srinivasan, 
# and Salil Wadhavkar.
# 
# AnyCore is distributed under the BSD license.
*******************************************************************************/


module LSUControl (
	input                                 clk,
	input                                 reset,
	input                                 recoverFlag_i,

`ifdef DYNAMIC_CONFIG
  input  [`STRUCT_PARTS_LSQ-1:0]        lsqPartitionActive_i,
`endif

`ifdef DATA_CACHE
  input                                 stallStCommit_i,
`endif

	input                                 backEndReady_i,

	input  [`COMMIT_WIDTH-1:0]            commitLoad_i,
	input  [`COMMIT_WIDTH-1:0]            commitStore_i,

	//interface with dispatch stage
	input  lsqPkt                         lsqPacket_i [0:`DISPATCH_WIDTH-1],

	output reg [`SIZE_LSQ_LOG-1:0]        lsqID_o [0:`DISPATCH_WIDTH-1],
	output [`SIZE_LSQ_LOG-1:0]            ldqID_o [0:`DISPATCH_WIDTH-1],
	output [`SIZE_LSQ_LOG-1:0]            stqID_o [0:`DISPATCH_WIDTH-1],

	output [`SIZE_LSQ_LOG:0]              ldqCount_o,
	output [`SIZE_LSQ_LOG:0]              stqCount_o,

	//interface with datapath
	output [`SIZE_LSQ_LOG-1:0]            ldqHead_o,
	output [`SIZE_LSQ_LOG-1:0]            ldqHead_t_o,
	output [`SIZE_LSQ_LOG-1:0]            ldqHeadPlusOne_o,
	output [`SIZE_LSQ_LOG-1:0]            ldqTail_o,

	output [`SIZE_LSQ_LOG-1:0]            stqHead_o,
	output [`SIZE_LSQ_LOG-1:0]            stqTail_o,
	
	output reg [`COMMIT_WIDTH_LOG:0]      commitLdCount_o,

	output                                commitSt_o,

	output reg [`SIZE_LSQ_LOG-1:0]        commitLdIndex_o [0:`COMMIT_WIDTH-1],
	output [`SIZE_LSQ_LOG-1:0]            lastStIndex_o   [0:`DISPATCH_WIDTH-1],

	output [`SIZE_LSQ_LOG-1:0]            nextLdIndex_o   [0:`DISPATCH_WIDTH-1],

	output reg [`SIZE_LSQ-1:0]            stqAddrValid_on_recover
);

//outputs of modules
reg  [`SIZE_LSQ_LOG-1:0]                ldqID [0:`DISPATCH_WIDTH-1];
reg  [`SIZE_LSQ_LOG-1:0]                stqID [0:`DISPATCH_WIDTH-1];

reg  [`SIZE_LSQ_LOG-1:0]                newLdIndex    [0:`DISPATCH_WIDTH-1];
reg  [`SIZE_LSQ_LOG-1:0]                newStIndex    [0:`DISPATCH_WIDTH-1];
reg  [`SIZE_LSQ_LOG-1:0]                commitStIndex [0:`COMMIT_WIDTH-1];
reg  [`SIZE_LSQ-1:0]                    stqCommit;

wire [`SIZE_LSQ_LOG-1:0]                newLdCount;
wire [`SIZE_LSQ_LOG-1:0]                newStCount;
reg  [`COMMIT_WIDTH_LOG:0]              commitStCount;

//these pointers are evaluated here
reg [`SIZE_LSQ_LOG-1:0]                 ldqHead;
reg [`SIZE_LSQ_LOG-1:0]                 ldqHeadPlusOne;
reg [`SIZE_LSQ_LOG-1:0]                 ldqHead_t;
reg [`SIZE_LSQ_LOG-1:0]                 ldqHeadPlusOne_t;
reg [`SIZE_LSQ_LOG-1:0]                 ldqTail;
reg [`SIZE_LSQ_LOG-1:0]                 ldqTail_t;
reg [`SIZE_LSQ_LOG:0]                   ldqCount;
reg [`SIZE_LSQ_LOG:0]                   ldqCount_t;

reg [`SIZE_LSQ_LOG-1:0]                 stqHead;
reg [`SIZE_LSQ_LOG-1:0]                 stqHead_t;
reg [`SIZE_LSQ_LOG-1:0]                 stqTail;
reg [`SIZE_LSQ_LOG-1:0]                 stqTail_t;
reg [`SIZE_LSQ_LOG:0]                   stqCount;
reg [`SIZE_LSQ_LOG:0]                   stqCount_t;
reg [`SIZE_LSQ_LOG-1:0]                 stqCommitPtr;
reg [`SIZE_LSQ_LOG-1:0]                 stqCommitPtr_t;

reg [`SIZE_LSQ-1:0]                     stqValid;
reg [`SIZE_LSQ-1:0]                     ldqValid;


reg [`SIZE_LSQ_LOG:0] lsqSize;
localparam LSQ_PARTITION_SIZE = `SIZE_LSQ/`STRUCT_PARTS_LSQ;
always_comb
begin
`ifdef DYNAMIC_CONFIG_AND_SIZE
  case(lsqPartitionActive_i)
    4'b1111:lsqSize =  LSQ_PARTITION_SIZE*4;
    4'b0111:lsqSize =  LSQ_PARTITION_SIZE*3;
    4'b0011:lsqSize =  LSQ_PARTITION_SIZE*2;
    4'b0001:lsqSize =  LSQ_PARTITION_SIZE*1;
    default:lsqSize =  `SIZE_LSQ;
  endcase
`else
  lsqSize = `SIZE_LSQ;
`endif
end

assign ldqID_o      = ldqID;
assign stqID_o      = stqID;

assign ldqHead_o    = ldqHead;
assign ldqHead_t_o  = ldqHead_t;
assign ldqHeadPlusOne_o    = ldqHeadPlusOne;
assign ldqTail_o    = ldqTail;

assign ldqCount_o   = ldqCount;

assign stqHead_o    = stqHead;
assign stqTail_o    = stqTail;
assign stqCount_o   = stqCount;

/* Generates the final instruction count in the LD queue.
 * Add new loads and subtract committed stores
 * NOTE: Pointers have implicit wrap around
 */
always_comb
begin:GENERATE_LD_CNT
	ldqHead_t              = ldqHead + commitLdCount_o;
  if(ldqHead_t >= lsqSize)
    ldqHead_t = ldqHead_t - lsqSize;

	ldqHeadPlusOne_t       = ldqHead + commitLdCount_o + 1'b1;
  if(ldqHeadPlusOne_t >= lsqSize)
    ldqHeadPlusOne_t = ldqHeadPlusOne_t - lsqSize;


	ldqTail_t              = ldqTail + newLdCount;
  if(ldqTail_t >= lsqSize)
    ldqTail_t = ldqTail_t - lsqSize;

	ldqCount_t             = ldqCount + newLdCount - commitLdCount_o;
end


/* Indicates to write the store at the head of STQ to data cache */
`ifdef DATA_CACHE
  assign commitSt_o         = stqValid[stqHead] & stqCommit[stqHead] & ~stallStCommit_i;// & ~recoverFlag_i;
`else  
  assign commitSt_o         = stqValid[stqHead] & stqCommit[stqHead];// & ~recoverFlag_i;
`endif  

/* Generates the final instruction count in the ST queue.
 * Add new stores and subtract committed stores 
 * NOTE: Pointers have implicit wrap around
 */ 
always_comb
begin:GENERATE_ST_CNT
	stqHead_t              = stqHead + commitSt_o;
  if(stqHead_t >= lsqSize)
    stqHead_t = stqHead_t - lsqSize;

	stqTail_t              = stqTail + newStCount;
  if(stqTail_t >= lsqSize)
    stqTail_t = stqTail_t - lsqSize;

	stqCount_t             = stqCount + newStCount - commitSt_o;
end


/* Determines if the instruction in each of the packets is load/store
 * and determines its lsqID. LsqID is the index of this
 * Load/Store into the Load queue/Store queue. It is assigned a value
 * during dispatch of the instruction and flows down the pipe with the
 * instruction 
 */
// LANE: Per lane logic
always_comb
begin
	int i;

	for (i = 0; i < `DISPATCH_WIDTH; i++)
	begin
		lsqID_o[i]     = 0;

		if (backEndReady_i)
		begin
			if (lsqPacket_i[i].isLoad)
			begin
				lsqID_o[i] = ldqID[i];
			end

			else if (lsqPacket_i[i].isStore)
			begin
				lsqID_o[i] = stqID[i];
			end
		end
	end
end


// LANE: Per lane logic
/* Update counters and structures related to Load instructions. */
always_ff @(posedge clk or posedge reset)
begin:LDQ_UPDATE
	if (reset)
	begin
		ldqHead                 <= 0;
		ldqHeadPlusOne          <= 'h1;
		ldqTail                 <= 0;
		ldqValid                <= 0;
	end

	else if (recoverFlag_i)
	begin
		ldqHead                 <= 0;
		ldqHeadPlusOne          <= 'h1;
		ldqTail                 <= 0;
		ldqValid                <= 0;
	end
	else
	begin
		ldqTail  <= ldqTail_t;
		ldqHead  <= ldqHead_t;
		ldqHeadPlusOne  <= ldqHeadPlusOne_t;

		/* Update ldq quqeue structure at Dispatch
		 * The indexes are precomputed and are an input to this module
		 */
		if (backEndReady_i)
		begin
			if (lsqPacket_i[0].isLoad)
			begin
				ldqValid[ldqID[0]]         <= 1'b1;
			end

`ifdef DISPATCH_TWO_WIDE
			if (lsqPacket_i[1].isLoad)
			begin
				ldqValid[ldqID[1]]         <= 1'b1;
			end
`endif

`ifdef DISPATCH_THREE_WIDE
			if (lsqPacket_i[2].isLoad)
			begin
				ldqValid[ldqID[2]]         <= 1'b1;
			end
`endif

`ifdef DISPATCH_FOUR_WIDE
			if (lsqPacket_i[3].isLoad)
			begin
				ldqValid[ldqID[3]]         <= 1'b1;
			end
`endif

`ifdef DISPATCH_FIVE_WIDE
			if (lsqPacket_i[4].isLoad)
			begin
				ldqValid[ldqID[4]]         <= 1'b1;
			end
`endif

`ifdef DISPATCH_SIX_WIDE
			if (lsqPacket_i[5].isLoad)
			begin
				ldqValid[ldqID[5]]         <= 1'b1;
			end
`endif

`ifdef DISPATCH_SEVEN_WIDE
			if (lsqPacket_i[6].isLoad)
			begin
				ldqValid[ldqID[6]]         <= 1'b1;
			end
`endif

`ifdef DISPATCH_EIGHT_WIDE
			if (lsqPacket_i[7].isLoad)
			begin
				ldqValid[ldqID[7]]         <= 1'b1;
			end
`endif

		end


		/* Update the ldqValid structure when loads retire
		 * indexes are precomputed and are input to this module
		 * commitLdCount_o : indicates how many loads are being commited this cycle
		 */
		case (commitLdCount_o)  //synopsys full_case
			3'd1:
			begin
				ldqValid[commitLdIndex_o[0]]           <= 1'b0;
			end

`ifdef COMMIT_TWO_WIDE      
			3'd2:
			begin
				ldqValid[commitLdIndex_o[0]]           <= 1'b0;
				ldqValid[commitLdIndex_o[1]]           <= 1'b0;
			end
`endif      

`ifdef COMMIT_THREE_WIDE
			3'd3:
			begin
				ldqValid[commitLdIndex_o[0]]           <= 1'b0;
				ldqValid[commitLdIndex_o[1]]           <= 1'b0;
				ldqValid[commitLdIndex_o[2]]           <= 1'b0;
			end
`endif

`ifdef COMMIT_FOUR_WIDE
			3'd4:
			begin
				ldqValid[commitLdIndex_o[0]]           <= 1'b0;
				ldqValid[commitLdIndex_o[1]]           <= 1'b0;
				ldqValid[commitLdIndex_o[2]]           <= 1'b0;
				ldqValid[commitLdIndex_o[3]]           <= 1'b0;
			end
`endif      
      default:
      begin
      end
		endcase
	end
end


always_ff @ (posedge clk or posedge reset)
begin:UPDATE_LDQ_COUNT
	if (reset)
	begin
		ldqCount     <= 0;
	end
	else if (recoverFlag_i)
	begin
		ldqCount     <= 0;
	end
	else
	begin
		ldqCount     <= ldqCount_t;
	end
end


/*******************************************************************************
 * On a recovery flush all the uncommitted STQ entries. Note: On a bad event
 * STQ could still hold good uncommitted stores. These stores might not have
 * left STQ because of number of Data Cache port constraint.
 ******************************************************************************/

reg [`SIZE_LSQ-1:0]     stqValid_on_recover;
reg [`SIZE_LSQ_LOG:0]   stqCount_on_recover;

always_comb
begin:STQ_ON_RECOVER
	integer i;
	stqValid_on_recover     = stqValid;

	stqCount_on_recover     = stqCount;
	stqAddrValid_on_recover = 0;

	for (i = 0; i < `SIZE_LSQ; i = i + 1)
	begin
		if (~stqCommit[i] && stqValid[i])
		begin
			stqValid_on_recover[i]     = 1'h0;
			stqCount_on_recover        = stqCount_on_recover - 1'h1;
		end

		if (stqCommit[i] && stqValid[i])
		begin
			stqAddrValid_on_recover[i] = 1'h1;
		end
	end
end

always_comb
begin

		stqCommitPtr_t       = stqCommitPtr + commitStCount;
    // Explicit wrap around
    if(stqCommitPtr_t >= lsqSize)
      stqCommitPtr_t = stqCommitPtr_t - lsqSize;
end


/* update store queue counters(stqhead, stqtail, stqCommitPtr) and
 * structures (STQvALID) */
// NOTE: Synthesis messes up synchronous reset at times
// Chaning the pointers to asynchronous reset to avoid Xs.
always_ff @(posedge clk or posedge reset)
begin:STQ_PTR_UPDATE
	if (reset)
	begin
		stqHead                     <= 0;
		stqTail                     <= 0;
		stqCommitPtr                <= 0;
	end

	else if (recoverFlag_i)
	begin
		stqHead                     <= stqHead;
		stqTail                     <= stqCommitPtr;
		stqCommitPtr                <= stqCommitPtr;
	end

	else
	begin
		stqTail                     <= stqTail_t;
		stqHead                     <= stqHead_t;
		stqCommitPtr                <= stqCommitPtr_t;
  end
end

// RBRC: 07/08/2013 Separated stq valid update from pointer
// updates always block to avoid asynchronous resets
always_ff @(posedge clk or posedge reset)
begin:STQ_VLD_VEC_UPDATE
	if (reset)
	begin
		stqValid                    <= 0;
	end

	else if (recoverFlag_i)
	begin
		stqValid                    <= stqValid_on_recover;
	end

	else
	begin
   
		/* invalidate stqvalid when the store is written to data cache */
		if (commitSt_o)
		begin
			stqValid[stqHead]         <= 1'b0;
		end


		/* update stqvalid on dispatch
		 * indexes are inputs to this module aand are pre computed */
		if (backEndReady_i)
		begin

			if (lsqPacket_i[0].isStore)
			begin
				stqValid[stqID[0]]      <= 1'b1;
			end

`ifdef DISPATCH_TWO_WIDE
			if (lsqPacket_i[1].isStore)
			begin
				stqValid[stqID[1]]      <= 1'b1;
			end
`endif

`ifdef DISPATCH_THREE_WIDE
			if (lsqPacket_i[2].isStore)
			begin
				stqValid[stqID[2]]      <= 1'b1;
			end
`endif

`ifdef DISPATCH_FOUR_WIDE
			if (lsqPacket_i[3].isStore)
			begin
				stqValid[stqID[3]]      <= 1'b1;
			end
`endif

`ifdef DISPATCH_FIVE_WIDE
			if (lsqPacket_i[4].isStore)
			begin
				stqValid[stqID[4]]      <= 1'b1;
			end
`endif

`ifdef DISPATCH_SIX_WIDE
			if (lsqPacket_i[5].isStore)
			begin
				stqValid[stqID[5]]      <= 1'b1;
			end
`endif

`ifdef DISPATCH_SEVEN_WIDE
			if (lsqPacket_i[6].isStore)
			begin
				stqValid[stqID[6]]      <= 1'b1;
			end
`endif

`ifdef DISPATCH_EIGHT_WIDE
			if (lsqPacket_i[7].isStore)
			begin
				stqValid[stqID[7]]      <= 1'b1;
			end
`endif

		end
	end
end


/* update structure stqCommit when stores retire from Active List
 * This vector keeps track of Valid stores that are are retired from   
 * active list are but have not yet been written to the data cache */
always_ff @(posedge clk or posedge reset)
begin:STQ_COMMIT_VEC_UPDATE
	if (reset)
	begin
		stqCommit          <= 0;
	end

	/* TODO: The recoverFlag_i check can be removed. Logic elsewhere will need to
	 * be modified too, though */
	else if (~recoverFlag_i)
	begin
		if (commitSt_o)
		begin
			stqCommit[stqHead] <= 1'b0;
		end

    // The number of store commits in a cycle determines
    // how many consecutive stores in the LSQ are ready 
    // to commit, starting the first uncommitted store
		case (commitStCount) //synopsys full_case
			3'd1:
			begin
				stqCommit[commitStIndex[0]]      <= 1'b1;
			end

`ifdef COMMIT_TWO_WIDE      
			3'd2:
			begin
				stqCommit[commitStIndex[0]]      <= 1'b1;
				stqCommit[commitStIndex[1]]      <= 1'b1;
			end
`endif      

`ifdef COMMIT_THREE_WIDE
			3'd3:
			begin
				stqCommit[commitStIndex[0]]      <= 1'b1;
				stqCommit[commitStIndex[1]]      <= 1'b1;
				stqCommit[commitStIndex[2]]      <= 1'b1;
			end
`endif      

`ifdef COMMIT_FOUR_WIDE
			3'd4:
			begin
				stqCommit[commitStIndex[0]]      <= 1'b1;
				stqCommit[commitStIndex[1]]      <= 1'b1;
				stqCommit[commitStIndex[2]]      <= 1'b1;
				stqCommit[commitStIndex[3]]      <= 1'b1;
			end
`endif      

      default:
      begin
      end
		endcase
	end
end


always_ff @(posedge clk or posedge reset)
begin:UPDATE_STQ_COUNT
	if (reset)
	begin
		stqCount     <= 0;
	end

	else if (recoverFlag_i)
	begin
		stqCount     <= stqCount_on_recover;
	end

	else
	begin
		stqCount     <= stqCount_t;
	end
end


// TODO: Can be partitioned into per lane logic
/* Generate indexes for new load instructions */
DispatchedLoad disLoad   (
	.backEndReady_i                      (backEndReady_i),
	.lsqPacket_i                         (lsqPacket_i),
                                      
	/* The LDQ IDs available to the new load instructions */
	.newLdIndex_o                        (newLdIndex),
                                      
	/* LDQ IDs of the new load instructions */
	.ldqID_o                             (ldqID),
                                      
	/* Each non-load's index to the next-youngest load */
	.nextLdIndex_o                       (nextLdIndex_o),
                                      
	.ldqHead_i                           (ldqHead),
	.ldqTail_i                           (ldqTail),
  .lsqSize_i                           (lsqSize),
                                      
	/* Count of new load instructions */
	.newLdCount_o                        (newLdCount)
);


// TODO: Can be partitioned into per lane logic
/* Generate indexes for new store instructions */
DispatchedStore disStore   (
	.backEndReady_i                      (backEndReady_i),
	.lsqPacket_i                         (lsqPacket_i),
                                                             
	.stqTail_i                           (stqTail),
	.stqHead_i                           (stqHead_t),
	.stqCount_i                          (stqCount),
  .lsqSize_i                           (lsqSize),
	                                     
	/* Count of new store instructions */
	.newStCount_o                        (newStCount),
                                       
	/* The STQ IDs available to the new store instructions */
	.newStIndex_o                        (newStIndex),
                                       
	/* Each non-store's index to the previous store */
	.lastStIndex_o                       (lastStIndex_o),
                                       
	/* STQ IDs of the new store instructions */
	.stqID_o                             (stqID)
);



/* Following combinational logic counts the number of LD commitructions in the
 * incoming retiring commitructions. */
always_comb
begin
  int i;
  commitLdCount_o   = 0;
  for(i=0;i<`COMMIT_WIDTH;i++)
  begin
  	commitLdCount_o  = commitLdCount_o + commitLoad_i[i];
	  commitLdIndex_o[i] = ldqHead + i;
    // Explicit wrap around
    if(commitLdIndex_o[i] >= lsqSize)
      commitLdIndex_o[i] = commitLdIndex_o[i] - lsqSize;
  end
end

/* Following combinational logic counts the number of LD commitructions in the
 * incoming retiring commitructions. */
always_comb
begin
  int i;
	commitStCount    = 0;
  for(i=0;i<`COMMIT_WIDTH;i++)
  begin
	  commitStCount  = commitStCount  + commitStore_i[i];
	  commitStIndex[i] = stqCommitPtr + i;
    // Explicit wrap around
    if(commitStIndex[i] >= lsqSize)
      commitStIndex[i] = commitStIndex[i] - lsqSize;
  end
end


endmodule
