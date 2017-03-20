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

`timescale 1ns/100ps


module PhyRegFile (

	input                                 clk,
	input                                 reset,

`ifdef DYNAMIC_CONFIG  
  input [`EXEC_WIDTH-1:0]               execLaneActive_i,
  input [`NUM_PARTS_RF-1:0]             rfPartitionActive_i,
`endif  

	/* INPUTS COMING FROM THE R-R STAGE */
	input [`SIZE_PHYSICAL_LOG-1:0]        phySrc1_i [0:`ISSUE_WIDTH-1],
	input [`SIZE_PHYSICAL_LOG-1:0]        phySrc2_i [0:`ISSUE_WIDTH-1],

	/* INPUTS COMING FROM THE WRITEBACK STAGE */
	input  bypassPkt                      bypassPacket_i [0:`ISSUE_WIDTH-1],

	/* OUTPUTS GOING TO THE R-R STAGE */
	output reg [`SRAM_DATA_WIDTH-1:0]     src1Data_byte0_o [0:`ISSUE_WIDTH-1],
	output reg [`SRAM_DATA_WIDTH-1:0]     src1Data_byte1_o [0:`ISSUE_WIDTH-1],
	output reg [`SRAM_DATA_WIDTH-1:0]     src1Data_byte2_o [0:`ISSUE_WIDTH-1],
	output reg [`SRAM_DATA_WIDTH-1:0]     src1Data_byte3_o [0:`ISSUE_WIDTH-1],

	output reg [`SRAM_DATA_WIDTH-1:0]     src2Data_byte0_o [0:`ISSUE_WIDTH-1],
	output reg [`SRAM_DATA_WIDTH-1:0]     src2Data_byte1_o [0:`ISSUE_WIDTH-1],
	output reg [`SRAM_DATA_WIDTH-1:0]     src2Data_byte2_o [0:`ISSUE_WIDTH-1],
	output reg [`SRAM_DATA_WIDTH-1:0]     src2Data_byte3_o [0:`ISSUE_WIDTH-1],

	input  [`SIZE_PHYSICAL_LOG-1:0]       dbAddr_i,
	input  [`SIZE_DATA-1:0]               dbData_i,
	input                                 dbWe_i,
	
	input  [`SIZE_PHYSICAL_LOG+`SIZE_DATA_BYTE_OFFSET-1:0]       debugPRFAddr_i,
	input  [`SRAM_DATA_WIDTH-1:0]         debugPRFWrData_i,
	input                                 debugPRFWrEn_i,
	output [`SRAM_DATA_WIDTH-1:0]         debugPRFRdData_o
	);


reg  [`SRAM_DATA_WIDTH-1:0]                   bypassData_byte2    [0:`ISSUE_WIDTH-1];
reg  [`SRAM_DATA_WIDTH-1:0]                   bypassData_byte3    [0:`ISSUE_WIDTH-1];
reg  [`SRAM_DATA_WIDTH-1:0]                   bypassData_byte3_t0 [0:`ISSUE_WIDTH-1];

reg  [`SIZE_PHYSICAL_TABLE-1:0]         src1Addr_byte0   [0:`ISSUE_WIDTH-1];
reg  [`SIZE_PHYSICAL_TABLE-1:0]         src1Addr_byte1   [0:`ISSUE_WIDTH-1];
reg  [`SIZE_PHYSICAL_TABLE-1:0]         src1Addr_byte2   [0:`ISSUE_WIDTH-1];
reg  [`SIZE_PHYSICAL_TABLE-1:0]         src1Addr_byte3   [0:`ISSUE_WIDTH-1];

reg  [`SIZE_PHYSICAL_TABLE-1:0]         src2Addr_byte0   [0:`ISSUE_WIDTH-1];
reg  [`SIZE_PHYSICAL_TABLE-1:0]         src2Addr_byte1   [0:`ISSUE_WIDTH-1];
reg  [`SIZE_PHYSICAL_TABLE-1:0]         src2Addr_byte2   [0:`ISSUE_WIDTH-1];
reg  [`SIZE_PHYSICAL_TABLE-1:0]         src2Addr_byte3   [0:`ISSUE_WIDTH-1];

reg  [`SIZE_PHYSICAL_TABLE-1:0]         destAddr_byte0   [0:`ISSUE_WIDTH-1];
reg  [`SIZE_PHYSICAL_TABLE-1:0]         destAddr_byte1   [0:`ISSUE_WIDTH-1];
reg  [`SIZE_PHYSICAL_TABLE-1:0]         destAddr_byte2   [0:`ISSUE_WIDTH-1];
reg  [`SIZE_PHYSICAL_TABLE-1:0]         destAddr_byte3   [0:`ISSUE_WIDTH-1];

reg  [`SRAM_DATA_WIDTH-1:0]             destData_byte0   [0:`ISSUE_WIDTH-1];
reg  [`SRAM_DATA_WIDTH-1:0]             destData_byte1   [0:`ISSUE_WIDTH-1];
reg  [`SRAM_DATA_WIDTH-1:0]             destData_byte2   [0:`ISSUE_WIDTH-1];
reg  [`SRAM_DATA_WIDTH-1:0]             destData_byte3   [0:`ISSUE_WIDTH-1];

reg                                     destWe_byte0     [0:`ISSUE_WIDTH-1];
reg                                     destWe_byte1     [0:`ISSUE_WIDTH-1];
reg                                     destWe_byte2     [0:`ISSUE_WIDTH-1];
reg                                     destWe_byte3     [0:`ISSUE_WIDTH-1];

`ifdef DYNAMIC_CONFIG
reg [`SIZE_PHYSICAL_LOG-1:0]        phySrc1Gated [0:`ISSUE_WIDTH-1];
reg [`SIZE_PHYSICAL_LOG-1:0]        phySrc2Gated [0:`ISSUE_WIDTH-1];
reg [`SIZE_PHYSICAL_LOG-1:0]        bypassTagGated [0:`ISSUE_WIDTH-1];

reg [`ISSUE_WIDTH-1:0][`NUM_PARTS_RF_LOG-1:0] src1DataPartitionSelect_byte0;
reg [`ISSUE_WIDTH-1:0][`NUM_PARTS_RF_LOG-1:0] src1DataPartitionSelect_byte1;
reg [`ISSUE_WIDTH-1:0][`NUM_PARTS_RF_LOG-1:0] src1DataPartitionSelect_byte2;
reg [`ISSUE_WIDTH-1:0][`NUM_PARTS_RF_LOG-1:0] src1DataPartitionSelect_byte3;
                      
reg [`ISSUE_WIDTH-1:0][`NUM_PARTS_RF_LOG-1:0] src2DataPartitionSelect_byte0;
reg [`ISSUE_WIDTH-1:0][`NUM_PARTS_RF_LOG-1:0] src2DataPartitionSelect_byte1;
reg [`ISSUE_WIDTH-1:0][`NUM_PARTS_RF_LOG-1:0] src2DataPartitionSelect_byte2;
reg [`ISSUE_WIDTH-1:0][`NUM_PARTS_RF_LOG-1:0] src2DataPartitionSelect_byte3;

always_comb
begin
	int i;

	for (i = 0; i < `ISSUE_WIDTH; i++)
	begin
    // Input Gating
    // TODO: This gating should be done outside by the clamping logic surrounding the execution lanes
    phySrc1Gated[i]           = execLaneActive_i[i] ?  phySrc1_i[i]          : {`SIZE_PHYSICAL_LOG{1'b0}};
    phySrc2Gated[i]           = execLaneActive_i[i] ?  phySrc2_i[i]          : {`SIZE_PHYSICAL_LOG{1'b0}};
    bypassTagGated[i]         = execLaneActive_i[i] ?  bypassPacket_i[i].tag : {`SIZE_PHYSICAL_LOG{1'b0}};

    src1DataPartitionSelect_byte0[i]   =   phySrc1Gated[i][`SIZE_PHYSICAL_LOG-1 :`SIZE_PHYSICAL_LOG-`NUM_PARTS_RF_LOG];
    src2DataPartitionSelect_byte0[i]   =   phySrc2Gated[i][`SIZE_PHYSICAL_LOG-1 :`SIZE_PHYSICAL_LOG-`NUM_PARTS_RF_LOG];

`ifndef RR_THREE_DEEP
    src1DataPartitionSelect_byte1[i]   =   src1DataPartitionSelect_byte0[i];
    src2DataPartitionSelect_byte1[i]   =   src2DataPartitionSelect_byte0[i];
`endif

`ifndef RR_TWO_DEEP
    src1DataPartitionSelect_byte2[i]   =   src1DataPartitionSelect_byte1[i];
    src2DataPartitionSelect_byte2[i]   =   src2DataPartitionSelect_byte1[i];
`endif

`ifndef RR_FOUR_DEEP
    src1DataPartitionSelect_byte3[i]   =   src1DataPartitionSelect_byte2[i];
    src2DataPartitionSelect_byte3[i]   =   src2DataPartitionSelect_byte2[i];
`endif
  end
end

always_ff @(posedge clk)
begin
	int i;

	for (i = 0; i < `ISSUE_WIDTH; i++)
	begin
`ifdef RR_THREE_DEEP
    src1DataPartitionSelect_byte1[i]   <=   src1DataPartitionSelect_byte0[i];
    src2DataPartitionSelect_byte1[i]   <=   src2DataPartitionSelect_byte0[i];
`endif

`ifdef RR_TWO_DEEP
    src1DataPartitionSelect_byte2[i]   <=   src1DataPartitionSelect_byte1[i];
    src2DataPartitionSelect_byte2[i]   <=   src2DataPartitionSelect_byte1[i];
`endif

`ifdef RR_FOUR_DEEP
    src1DataPartitionSelect_byte3[i]   <=   src1DataPartitionSelect_byte2[i];
    src2DataPartitionSelect_byte3[i]   <=   src2DataPartitionSelect_byte2[i];
`endif
  end

end

`endif

/* The physical register file is split into bytes to accomodate different
 * depths. The bytes read/written in each cycle for different depths is as follows:
 *                Cycle-n  n+1  n+2  n+3
 * RR_ONE_DEEP    0,1,2,3
 * RR_TWO_DEEP    0,1      2,3
 * RR_THREE_DEEP  0        1    2,3
 * RR_FOUR_DEEP   0        1    2    3
 */

/* Reads and writes start at byte 0. The addresses/write enables get passed from
 * byte 0 to byte 1 to byte 2 to byte 3. Whether the signals get passed
 * immediately or in the next cycle depends on the register read depth.
 * The data being written comes from the bypass and gets delayed here for
 * depths > 1. */

// TODO: Might be worthwhile to gate the per lane decoders
// This should be decided based upon the power numbers obtained
// from Prime Time. Dynamic power will be saved as the addresses
// are gated. 
always_comb
begin
	int i;

	for (i = 0; i < `ISSUE_WIDTH; i++)
	begin
		/* Decode the addresses */
`ifdef DYNAMIC_CONFIG    
		src1Addr_byte0[i]         = 1 << phySrc1Gated[i];
		src2Addr_byte0[i]         = 1 << phySrc2Gated[i];
		destAddr_byte0[i]         = 1 << bypassTagGated[i];
`else
		src1Addr_byte0[i]         = 1 << phySrc1_i[i];
		src2Addr_byte0[i]         = 1 << phySrc2_i[i];
		destAddr_byte0[i]         = 1 << bypassPacket_i[i].tag;
`endif    
		destWe_byte0[i]           = bypassPacket_i[i].valid;
		destData_byte0[i]         = bypassPacket_i[i].data[`SRAM_DATA_WIDTH-1:0];

`ifndef RR_THREE_DEEP
		src1Addr_byte1[i]         = src1Addr_byte0[i];
		src2Addr_byte1[i]         = src2Addr_byte0[i];
		destAddr_byte1[i]         = destAddr_byte0[i];
		destWe_byte1[i]           = destWe_byte0[i];
		destData_byte1[i]         = bypassPacket_i[i].data[2*`SRAM_DATA_WIDTH-1:`SRAM_DATA_WIDTH];
		bypassData_byte2[i]       = bypassPacket_i[i].data[3*`SRAM_DATA_WIDTH-1:2*`SRAM_DATA_WIDTH];
		bypassData_byte3_t0[i]    = bypassPacket_i[i].data[4*`SRAM_DATA_WIDTH-1:3*`SRAM_DATA_WIDTH];
`endif

`ifndef RR_TWO_DEEP
		src1Addr_byte2[i]         = src1Addr_byte1[i];
		src2Addr_byte2[i]         = src2Addr_byte1[i];
		destAddr_byte2[i]         = destAddr_byte1[i];
		destWe_byte2[i]           = destWe_byte1[i];
		destData_byte2[i]         = bypassPacket_i[i].data[3*`SRAM_DATA_WIDTH-1:2*`SRAM_DATA_WIDTH];
		destData_byte3[i]         = bypassPacket_i[i].data[4*`SRAM_DATA_WIDTH-1:3*`SRAM_DATA_WIDTH];
`endif

`ifndef RR_FOUR_DEEP
		src1Addr_byte3[i]         = src1Addr_byte2[i];
		src2Addr_byte3[i]         = src2Addr_byte2[i];
		destAddr_byte3[i]         = destAddr_byte2[i];
		destWe_byte3[i]           = destWe_byte2[i];
		bypassData_byte3[i]       = bypassData_byte3_t0[i];
`endif
	end

`ifdef ZERO
	/* Hijack a port to load from a checkpoint */
	/* Note: This is not implemented yet */
	if (dbWe_i)
	begin
		destAddr_byte0[0]   = 1 << dbAddr_i;
		destAddr_byte1[0]   = 1 << dbAddr_i;
		destAddr_byte3[0]   = 1 << dbAddr_i;

		destData_byte0[0]   = dbData_i[`SRAM_DATA_WIDTH-1:0];
		destData_byte1[0]   = dbData_i[2*`SRAM_DATA_WIDTH-1:`SRAM_DATA_WIDTH];
		destData_byte3[0]   = dbData_i[4*`SRAM_DATA_WIDTH-1:3*`SRAM_DATA_WIDTH];

		destWe_byte0[0]     = 1'h1;
		destWe_byte1[0]     = 1'h1;
		destWe_byte3[0]     = 1'h1;
	end
`endif
end


// LANE: Per lane logic

always_ff @(posedge clk)
begin
	int i;

`ifdef RR_THREE_DEEP
	for (i = 0; i < `ISSUE_WIDTH; i++)
	begin
		src1Addr_byte1[i]        <= src1Addr_byte0[i];
		src2Addr_byte1[i]        <= src2Addr_byte0[i];
		destAddr_byte1[i]        <= destAddr_byte0[i];
		destWe_byte1[i]          <= destWe_byte0[i];
		destData_byte1[i]        <= bypassPacket_i[i].data[2*`SRAM_DATA_WIDTH-1:`SRAM_DATA_WIDTH];
		bypassData_byte2[i]      <= bypassPacket_i[i].data[3*`SRAM_DATA_WIDTH-1:2*`SRAM_DATA_WIDTH];
		bypassData_byte3_t0[i]   <= bypassPacket_i[i].data[4*`SRAM_DATA_WIDTH-1:3*`SRAM_DATA_WIDTH];
	end
`endif

`ifdef RR_TWO_DEEP
	for (i = 0; i < `ISSUE_WIDTH; i++)
	begin
		src1Addr_byte2[i]        <= src1Addr_byte1[i];
		src2Addr_byte2[i]        <= src2Addr_byte1[i];
		destAddr_byte2[i]        <= destAddr_byte1[i];
		destWe_byte2[i]          <= destWe_byte1[i];
		destData_byte2[i]        <= bypassData_byte2[i];
		destData_byte3[i]        <= bypassData_byte3[i];
	end
`endif

`ifdef RR_FOUR_DEEP
	for (i = 0; i < `ISSUE_WIDTH; i++)
	begin
		src1Addr_byte3[i]        <= src1Addr_byte2[i];
		src2Addr_byte3[i]        <= src2Addr_byte2[i];
		destAddr_byte3[i]        <= destAddr_byte2[i];
		destWe_byte3[i]          <= destWe_byte2[i];
		bypassData_byte3[i]      <= bypassData_byte3_t0[i];
	end
`endif

`ifdef ZERO
	/* Hijack a port to load from a checkpoint */
	if (dbWe_i)
	begin
		destAddr_byte2[0]  <= 1 << dbAddr_i;
		destData_byte2[0]  <= dbData_i[3*`SRAM_DATA_WIDTH-1:2*`SRAM_DATA_WIDTH];
		destWe_byte2[0]    <= 1'h1;
	end
`endif
end

`ifdef PRF_DEBUG_PORT

  wire debugPRFWrEn_byte0;
  wire debugPRFWrEn_byte1;
  wire debugPRFWrEn_byte2;
  wire debugPRFWrEn_byte3;
  
  wire [`SRAM_DATA_WIDTH-1:0] debugPRFRdData_byte0;
  wire [`SRAM_DATA_WIDTH-1:0] debugPRFRdData_byte1;
  wire [`SRAM_DATA_WIDTH-1:0] debugPRFRdData_byte2;
  wire [`SRAM_DATA_WIDTH-1:0] debugPRFRdData_byte3;
  
  
  wire [`SIZE_PHYSICAL_TABLE-1:0]  debugPRFAddr_shifted;
  wire [`NUM_PARTS_RF_LOG-1:0] debugPRFPartitionSelect;
  
  assign debugPRFWrEn_byte0 = (debugPRFAddr_i[`SIZE_DATA_BYTE_OFFSET+`SIZE_PHYSICAL_LOG-1-:2] == 2'b00) ? debugPRFWrEn_i : 0;
  assign debugPRFWrEn_byte1 = (debugPRFAddr_i[`SIZE_DATA_BYTE_OFFSET+`SIZE_PHYSICAL_LOG-1-:2] == 2'b01) ? debugPRFWrEn_i : 0;
  assign debugPRFWrEn_byte2 = (debugPRFAddr_i[`SIZE_DATA_BYTE_OFFSET+`SIZE_PHYSICAL_LOG-1-:2] == 2'b10) ? debugPRFWrEn_i : 0;
  assign debugPRFWrEn_byte3 = (debugPRFAddr_i[`SIZE_DATA_BYTE_OFFSET+`SIZE_PHYSICAL_LOG-1-:2] == 2'b11) ? debugPRFWrEn_i : 0;
  
  assign debugPRFRdData_o =     (debugPRFAddr_i[`SIZE_DATA_BYTE_OFFSET+`SIZE_PHYSICAL_LOG-1-:2] == 2'b00) ? debugPRFRdData_byte0 
                              : (debugPRFAddr_i[`SIZE_DATA_BYTE_OFFSET+`SIZE_PHYSICAL_LOG-1-:2] == 2'b01) ? debugPRFRdData_byte1 
                              : (debugPRFAddr_i[`SIZE_DATA_BYTE_OFFSET+`SIZE_PHYSICAL_LOG-1-:2] == 2'b10) ? debugPRFRdData_byte2 
                              :                                                                             debugPRFRdData_byte3;
  


  assign debugPRFAddr_shifted       = 1 << debugPRFAddr_i[`SIZE_PHYSICAL_LOG-1:0] ;
  assign debugPRFPartitionSelect    =   debugPRFAddr_i[`SIZE_PHYSICAL_LOG-1 :`SIZE_PHYSICAL_LOG-`NUM_PARTS_RF_LOG];

`endif //PRF_DEBUG_PORT

// address has to be converted to fully decoded bit vector i.e., d3 = b11 = b01000 before giving to RAM.

PRF_RAM #(
	.DEPTH             (`SIZE_PHYSICAL_TABLE),
	.INDEX             (`SIZE_PHYSICAL_LOG),
	.WIDTH             (8)
	)

	PhyRegFile_byte0   (
	
	.src1Addr0_i       (src1Addr_byte0[0]),
	.src1Data0_o       (src1Data_byte0_o[0]),

	.src2Addr0_i       (src2Addr_byte0[0]),
	.src2Data0_o       (src2Data_byte0_o[0]),

	.destAddr0_i       (destAddr_byte0[0]), 
	.destData0_i       (destData_byte0[0]),
	.destWe0_i         (destWe_byte0[0]),


`ifdef ISSUE_TWO_WIDE
	.src1Addr1_i       (src1Addr_byte0[1]),
	.src1Data1_o       (src1Data_byte0_o[1]),

	.src2Addr1_i       (src2Addr_byte0[1]),
	.src2Data1_o       (src2Data_byte0_o[1]),

	.destAddr1_i       (destAddr_byte0[1]),
	.destData1_i       (destData_byte0[1]),
	.destWe1_i         (destWe_byte0[1]),
`endif


`ifdef ISSUE_THREE_WIDE
	.src1Addr2_i       (src1Addr_byte0[2]),
	.src1Data2_o       (src1Data_byte0_o[2]),

	.src2Addr2_i       (src2Addr_byte0[2]),
	.src2Data2_o       (src2Data_byte0_o[2]),

	.destAddr2_i       (destAddr_byte0[2]),
	.destData2_i       (destData_byte0[2]),
	.destWe2_i         (destWe_byte0[2]),
`endif


`ifdef ISSUE_FOUR_WIDE
	.src1Addr3_i       (src1Addr_byte0[3]),
	.src1Data3_o       (src1Data_byte0_o[3]),

	.src2Addr3_i       (src2Addr_byte0[3]),
	.src2Data3_o       (src2Data_byte0_o[3]),

	.destAddr3_i       (destAddr_byte0[3]),
	.destData3_i       (destData_byte0[3]),
	.destWe3_i         (destWe_byte0[3]),
`endif

`ifdef ISSUE_FIVE_WIDE
	.src1Addr4_i       (src1Addr_byte0[4]),
	.src1Data4_o       (src1Data_byte0_o[4]),

	.src2Addr4_i       (src2Addr_byte0[4]),
	.src2Data4_o       (src2Data_byte0_o[4]),

	.destAddr4_i       (destAddr_byte0[4]),
	.destData4_i       (destData_byte0[4]),
	.destWe4_i         (destWe_byte0[4]),
`endif

`ifdef ISSUE_SIX_WIDE
	.src1Addr5_i       (src1Addr_byte0[5]),
	.src1Data5_o       (src1Data_byte0_o[5]),

	.src2Addr5_i       (src2Addr_byte0[5]),
	.src2Data5_o       (src2Data_byte0_o[5]),

	.destAddr5_i       (destAddr_byte0[5]),
	.destData5_i       (destData_byte0[5]),
	.destWe5_i         (destWe_byte0[5]),
`endif

`ifdef ISSUE_SEVEN_WIDE
	.src1Addr6_i       (src1Addr_byte0[6]),
	.src1Data6_o       (src1Data_byte0_o[6]),

	.src2Addr6_i       (src2Addr_byte0[6]),
	.src2Data6_o       (src2Data_byte0_o[6]),

	.destAddr6_i       (destAddr_byte0[6]),
	.destData6_i       (destData_byte0[6]),
	.destWe6_i         (destWe_byte0[6]),
`endif

`ifdef ISSUE_EIGHT_WIDE
	.src1Addr7_i       (src1Addr_byte0[7]),
	.src1Data7_o       (src1Data_byte0_o[7]),

	.src2Addr7_i       (src2Addr_byte0[7]),
	.src2Data7_o       (src2Data_byte0_o[7]),

	.destAddr7_i       (destAddr_byte0[7]),
	.destData7_i       (destData_byte0[7]),
	.destWe7_i         (destWe_byte0[7]),
`endif

`ifdef DYNAMIC_CONFIG
  .execLaneActive_i   (execLaneActive_i),
  .rfPartitionActive_i(rfPartitionActive_i),
  .src1DataPartitionSelect_i(src1DataPartitionSelect_byte0),
  .src2DataPartitionSelect_i(src2DataPartitionSelect_byte0),
`endif
       
`ifdef PRF_DEBUG_PORT
  `ifdef DYNAMIC_CONFIG
    .debugPRFPartitionSelect_i(debugPRFPartitionSelect),
  `endif
  .debugPRFRdAddr_i  (debugPRFAddr_shifted),
  .debugPRFRdData_o  (debugPRFRdData_byte0),
  .debugPRFWrData_i  (debugPRFWrData_i),
  .debugPRFWrEn_i    (debugPRFWrEn_byte0),
`endif //PRF_DEBUG_PORT
	
	.clk               (clk),
	.reset             (reset && ~dbWe_i)
	);


PRF_RAM #(
	.DEPTH             (`SIZE_PHYSICAL_TABLE),
	.INDEX             (`SIZE_PHYSICAL_LOG),
	.WIDTH             (8)
	)

	PhyRegFile_byte1   (

	.src1Addr0_i       (src1Addr_byte1[0]),
	.src1Data0_o       (src1Data_byte1_o[0]),

	.src2Addr0_i       (src2Addr_byte1[0]),
	.src2Data0_o       (src2Data_byte1_o[0]),

	.destAddr0_i       (destAddr_byte1[0]), 
	.destData0_i       (destData_byte1[0]),
	.destWe0_i         (destWe_byte1[0]),


`ifdef ISSUE_TWO_WIDE
	.src1Addr1_i       (src1Addr_byte1[1]),
	.src1Data1_o       (src1Data_byte1_o[1]),

	.src2Addr1_i       (src2Addr_byte1[1]),
	.src2Data1_o       (src2Data_byte1_o[1]),

	.destAddr1_i       (destAddr_byte1[1]),
	.destData1_i       (destData_byte1[1]),
	.destWe1_i         (destWe_byte1[1]),
`endif


`ifdef ISSUE_THREE_WIDE
	.src1Addr2_i       (src1Addr_byte1[2]),
	.src1Data2_o       (src1Data_byte1_o[2]),

	.src2Addr2_i       (src2Addr_byte1[2]),
	.src2Data2_o       (src2Data_byte1_o[2]),

	.destAddr2_i       (destAddr_byte1[2]),
	.destData2_i       (destData_byte1[2]),
	.destWe2_i         (destWe_byte1[2]),
`endif


`ifdef ISSUE_FOUR_WIDE
	.src1Addr3_i       (src1Addr_byte1[3]),
	.src1Data3_o       (src1Data_byte1_o[3]),

	.src2Addr3_i       (src2Addr_byte1[3]),
	.src2Data3_o       (src2Data_byte1_o[3]),

	.destAddr3_i       (destAddr_byte1[3]),
	.destData3_i       (destData_byte1[3]),
	.destWe3_i         (destWe_byte1[3]),
`endif

`ifdef ISSUE_FIVE_WIDE
	.src1Addr4_i       (src1Addr_byte1[4]),
	.src1Data4_o       (src1Data_byte1_o[4]),

	.src2Addr4_i       (src2Addr_byte1[4]),
	.src2Data4_o       (src2Data_byte1_o[4]),

	.destAddr4_i       (destAddr_byte1[4]),
	.destData4_i       (destData_byte1[4]),
	.destWe4_i         (destWe_byte1[4]),
`endif

`ifdef ISSUE_SIX_WIDE
	.src1Addr5_i       (src1Addr_byte1[5]),
	.src1Data5_o       (src1Data_byte1_o[5]),

	.src2Addr5_i       (src2Addr_byte1[5]),
	.src2Data5_o       (src2Data_byte1_o[5]),

	.destAddr5_i       (destAddr_byte1[5]),
	.destData5_i       (destData_byte1[5]),
	.destWe5_i         (destWe_byte1[5]),
`endif

`ifdef ISSUE_SEVEN_WIDE
	.src1Addr6_i       (src1Addr_byte1[6]),
	.src1Data6_o       (src1Data_byte1_o[6]),

	.src2Addr6_i       (src2Addr_byte1[6]),
	.src2Data6_o       (src2Data_byte1_o[6]),

	.destAddr6_i       (destAddr_byte1[6]),
	.destData6_i       (destData_byte1[6]),
	.destWe6_i         (destWe_byte1[6]),
`endif

`ifdef ISSUE_EIGHT_WIDE
	.src1Addr7_i       (src1Addr_byte1[7]),
	.src1Data7_o       (src1Data_byte1_o[7]),

	.src2Addr7_i       (src2Addr_byte1[7]),
	.src2Data7_o       (src2Data_byte1_o[7]),

	.destAddr7_i       (destAddr_byte1[7]),
	.destData7_i       (destData_byte1[7]),
	.destWe7_i         (destWe_byte1[7]),
`endif

`ifdef DYNAMIC_CONFIG
  .execLaneActive_i   (execLaneActive_i),
  .rfPartitionActive_i(rfPartitionActive_i),
  .src1DataPartitionSelect_i(src1DataPartitionSelect_byte1),
  .src2DataPartitionSelect_i(src2DataPartitionSelect_byte1),
`endif

`ifdef PRF_DEBUG_PORT
  `ifdef DYNAMIC_CONFIG
    .debugPRFPartitionSelect_i(debugPRFPartitionSelect),
  `endif
  .debugPRFRdAddr_i  (debugPRFAddr_shifted),
  .debugPRFRdData_o  (debugPRFRdData_byte1),
  .debugPRFWrData_i  (debugPRFWrData_i),
  .debugPRFWrEn_i    (debugPRFWrEn_byte1),
`endif //PRF_DEBUG_PORT

	.clk               (clk),
	.reset             (reset && ~dbWe_i)
	);


PRF_RAM #(
	.DEPTH             (`SIZE_PHYSICAL_TABLE),
	.INDEX             (`SIZE_PHYSICAL_LOG),
	.WIDTH             (8)
	)

	PhyRegFile_byte2   (

	.src1Addr0_i       (src1Addr_byte2[0]),
	.src1Data0_o       (src1Data_byte2_o[0]),

	.src2Addr0_i       (src2Addr_byte2[0]),
	.src2Data0_o       (src2Data_byte2_o[0]),

	.destAddr0_i       (destAddr_byte2[0]), 
	.destData0_i       (destData_byte2[0]),
	.destWe0_i         (destWe_byte2[0]),


`ifdef ISSUE_TWO_WIDE
	.src1Addr1_i       (src1Addr_byte2[1]),
	.src1Data1_o       (src1Data_byte2_o[1]),

	.src2Addr1_i       (src2Addr_byte2[1]),
	.src2Data1_o       (src2Data_byte2_o[1]),

	.destAddr1_i       (destAddr_byte2[1]),
	.destData1_i       (destData_byte2[1]),
	.destWe1_i         (destWe_byte2[1]),
`endif


`ifdef ISSUE_THREE_WIDE
	.src1Addr2_i       (src1Addr_byte2[2]),
	.src1Data2_o       (src1Data_byte2_o[2]),

	.src2Addr2_i       (src2Addr_byte2[2]),
	.src2Data2_o       (src2Data_byte2_o[2]),

	.destAddr2_i       (destAddr_byte2[2]),
	.destData2_i       (destData_byte2[2]),
	.destWe2_i         (destWe_byte2[2]),
`endif


`ifdef ISSUE_FOUR_WIDE
	.src1Addr3_i       (src1Addr_byte2[3]),
	.src1Data3_o       (src1Data_byte2_o[3]),

	.src2Addr3_i       (src2Addr_byte2[3]),
	.src2Data3_o       (src2Data_byte2_o[3]),

	.destAddr3_i       (destAddr_byte2[3]),
	.destData3_i       (destData_byte2[3]),
	.destWe3_i         (destWe_byte2[3]),
`endif

`ifdef ISSUE_FIVE_WIDE
	.src1Addr4_i       (src1Addr_byte2[4]),
	.src1Data4_o       (src1Data_byte2_o[4]),

	.src2Addr4_i       (src2Addr_byte2[4]),
	.src2Data4_o       (src2Data_byte2_o[4]),

	.destAddr4_i       (destAddr_byte2[4]),
	.destData4_i       (destData_byte2[4]),
	.destWe4_i         (destWe_byte2[4]),
`endif

`ifdef ISSUE_SIX_WIDE
	.src1Addr5_i       (src1Addr_byte2[5]),
	.src1Data5_o       (src1Data_byte2_o[5]),

	.src2Addr5_i       (src2Addr_byte2[5]),
	.src2Data5_o       (src2Data_byte2_o[5]),

	.destAddr5_i       (destAddr_byte2[5]),
	.destData5_i       (destData_byte2[5]),
	.destWe5_i         (destWe_byte2[5]),
`endif

`ifdef ISSUE_SEVEN_WIDE
	.src1Addr6_i       (src1Addr_byte2[6]),
	.src1Data6_o       (src1Data_byte2_o[6]),

	.src2Addr6_i       (src2Addr_byte2[6]),
	.src2Data6_o       (src2Data_byte2_o[6]),

	.destAddr6_i       (destAddr_byte2[6]),
	.destData6_i       (destData_byte2[6]),
	.destWe6_i         (destWe_byte2[6]),
`endif

`ifdef ISSUE_EIGHT_WIDE
	.src1Addr7_i       (src1Addr_byte2[7]),
	.src1Data7_o       (src1Data_byte2_o[7]),

	.src2Addr7_i       (src2Addr_byte2[7]),
	.src2Data7_o       (src2Data_byte2_o[7]),

	.destAddr7_i       (destAddr_byte2[7]),
	.destData7_i       (destData_byte2[7]),
	.destWe7_i         (destWe_byte2[7]),
`endif

`ifdef DYNAMIC_CONFIG
  .execLaneActive_i   (execLaneActive_i),
  .rfPartitionActive_i(rfPartitionActive_i),
  .src1DataPartitionSelect_i(src1DataPartitionSelect_byte2),
  .src2DataPartitionSelect_i(src2DataPartitionSelect_byte2),
`endif

`ifdef PRF_DEBUG_PORT
  `ifdef DYNAMIC_CONFIG
    .debugPRFPartitionSelect_i(debugPRFPartitionSelect),
  `endif
  .debugPRFRdAddr_i  (debugPRFAddr_shifted),
  .debugPRFRdData_o  (debugPRFRdData_byte2),
  .debugPRFWrData_i  (debugPRFWrData_i),
  .debugPRFWrEn_i    (debugPRFWrEn_byte2),
`endif //PRF_DEBUG_PORT

	.clk               (clk),
	.reset             (reset && ~dbWe_i)
	);


PRF_RAM #(
	.DEPTH             (`SIZE_PHYSICAL_TABLE),
	.INDEX             (`SIZE_PHYSICAL_LOG),
	.WIDTH             (8)
	)

	PhyRegFile_byte3   (

	.src1Addr0_i       (src1Addr_byte3[0]),
	.src1Data0_o       (src1Data_byte3_o[0]),

	.src2Addr0_i       (src2Addr_byte3[0]),
	.src2Data0_o       (src2Data_byte3_o[0]),

	.destAddr0_i       (destAddr_byte3[0]), 
	.destData0_i       (destData_byte3[0]),
	.destWe0_i         (destWe_byte3[0]),


`ifdef ISSUE_TWO_WIDE
	.src1Addr1_i       (src1Addr_byte3[1]),
	.src1Data1_o       (src1Data_byte3_o[1]),

	.src2Addr1_i       (src2Addr_byte3[1]),
	.src2Data1_o       (src2Data_byte3_o[1]),

	.destAddr1_i       (destAddr_byte3[1]),
	.destData1_i       (destData_byte3[1]),
	.destWe1_i         (destWe_byte3[1]),
`endif


`ifdef ISSUE_THREE_WIDE
	.src1Addr2_i       (src1Addr_byte3[2]),
	.src1Data2_o       (src1Data_byte3_o[2]),

	.src2Addr2_i       (src2Addr_byte3[2]),
	.src2Data2_o       (src2Data_byte3_o[2]),

	.destAddr2_i       (destAddr_byte3[2]),
	.destData2_i       (destData_byte3[2]),
	.destWe2_i         (destWe_byte3[2]),
`endif


`ifdef ISSUE_FOUR_WIDE
	.src1Addr3_i       (src1Addr_byte3[3]),
	.src1Data3_o       (src1Data_byte3_o[3]),

	.src2Addr3_i       (src2Addr_byte3[3]),
	.src2Data3_o       (src2Data_byte3_o[3]),

	.destAddr3_i       (destAddr_byte3[3]),
	.destData3_i       (destData_byte3[3]),
	.destWe3_i         (destWe_byte3[3]),
`endif

`ifdef ISSUE_FIVE_WIDE
	.src1Addr4_i       (src1Addr_byte3[4]),
	.src1Data4_o       (src1Data_byte3_o[4]),

	.src2Addr4_i       (src2Addr_byte3[4]),
	.src2Data4_o       (src2Data_byte3_o[4]),

	.destAddr4_i       (destAddr_byte3[4]),
	.destData4_i       (destData_byte3[4]),
	.destWe4_i         (destWe_byte3[4]),
`endif

`ifdef ISSUE_SIX_WIDE
	.src1Addr5_i       (src1Addr_byte3[5]),
	.src1Data5_o       (src1Data_byte3_o[5]),

	.src2Addr5_i       (src2Addr_byte3[5]),
	.src2Data5_o       (src2Data_byte3_o[5]),

	.destAddr5_i       (destAddr_byte3[5]),
	.destData5_i       (destData_byte3[5]),
	.destWe5_i         (destWe_byte3[5]),
`endif

`ifdef ISSUE_SEVEN_WIDE
	.src1Addr6_i       (src1Addr_byte3[6]),
	.src1Data6_o       (src1Data_byte3_o[6]),

	.src2Addr6_i       (src2Addr_byte3[6]),
	.src2Data6_o       (src2Data_byte3_o[6]),

	.destAddr6_i       (destAddr_byte3[6]),
	.destData6_i       (destData_byte3[6]),
	.destWe6_i         (destWe_byte3[6]),
`endif

`ifdef ISSUE_EIGHT_WIDE
	.src1Addr7_i       (src1Addr_byte3[7]),
	.src1Data7_o       (src1Data_byte3_o[7]),

	.src2Addr7_i       (src2Addr_byte3[7]),
	.src2Data7_o       (src2Data_byte3_o[7]),

	.destAddr7_i       (destAddr_byte3[7]),
	.destData7_i       (destData_byte3[7]),
	.destWe7_i         (destWe_byte3[7]),
`endif

`ifdef DYNAMIC_CONFIG
  .execLaneActive_i   (execLaneActive_i),
  .rfPartitionActive_i(rfPartitionActive_i),
  .src1DataPartitionSelect_i(src1DataPartitionSelect_byte3),
  .src2DataPartitionSelect_i(src2DataPartitionSelect_byte3),
`endif
 
`ifdef PRF_DEBUG_PORT
  `ifdef DYNAMIC_CONFIG
    .debugPRFPartitionSelect_i(debugPRFPartitionSelect),
  `endif
  .debugPRFRdAddr_i  (debugPRFAddr_shifted),
  .debugPRFRdData_o  (debugPRFRdData_byte3),
  .debugPRFWrData_i  (debugPRFWrData_i),
  .debugPRFWrEn_i    (debugPRFWrEn_byte3),
`endif

	.clk               (clk),
	.reset             (reset && ~dbWe_i)
	);


endmodule

