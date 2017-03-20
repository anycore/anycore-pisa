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

module RAM_PARTITIONED #(
	/* Parameters */
	parameter DEPTH = `RAM_CONFIG_DEPTH,
	parameter INDEX = `RAM_CONFIG_INDEX,
	parameter WIDTH = `RAM_CONFIG_WIDTH,
  parameter NUM_WR_PORTS = `RAM_CONFIG_WP,
  parameter NUM_RD_PORTS = `RAM_CONFIG_RP,
  parameter WR_PORTS_LOG = `RAM_CONFIG_WP_LOG,
  parameter NUM_PARTS    = `RAM_PARTS,
  parameter NUM_PARTS_LOG= `RAM_PARTS_LOG,
  parameter DYNAMIC_WIDTH = `RAM_CONFIG_DYNAMIC_WIDTH,
  parameter DYNAMIC_SIZE = `RAM_CONFIG_DYNAMIC_SIZE,
  parameter LATCH_BASED_RAM= `LATCH_BASED_RAM,
  parameter GATING_ENABLED = 1,
  parameter RESET_VAL = `RAM_RESET_ZERO, //RAM_RESET_SEQ or RAM_RESET_ZERO
  parameter SEQ_START = 0,       // valid only when RESET_VAL = "SEQ"
  parameter PARENT_MODULE = "NO_PARENT" // This gives the module name in which this is instantiated
) (

  input       [NUM_WR_PORTS-1:0]                  writePortGated_i,
  input       [NUM_RD_PORTS-1:0]                  readPortGated_i,
  input       [NUM_PARTS-1:0]                     partitionGated_i,

	input       [NUM_RD_PORTS-1:0][INDEX-1:0]       addr_i,
	output reg  [NUM_RD_PORTS-1:0][WIDTH-1:0]       data_o,

	input       [NUM_WR_PORTS-1:0][INDEX-1:0]       addrWr_i,
	input       [NUM_WR_PORTS-1:0][WIDTH-1:0]       dataWr_i,

	input       [NUM_WR_PORTS-1:0]                  wrEn_i,

	input                                           clk,
	input                                           reset,
  output                                          ramReady_o //Used to signal that the RAM is ready for operation
);


  wire [NUM_RD_PORTS-1:0][WIDTH-1:0]                rdData[NUM_PARTS-1:0];
  wire [NUM_RD_PORTS-1:0][INDEX-NUM_PARTS_LOG-1:0]  addrPartition;
  wire [NUM_WR_PORTS-1:0][INDEX-NUM_PARTS_LOG-1:0]  addrWrPartition;
  wire [NUM_RD_PORTS-1:0][NUM_PARTS_LOG-1:0]        addrPartSelect;
  wire [NUM_WR_PORTS-1:0][NUM_PARTS_LOG-1:0]        addrWrPartSelect;
  wire [NUM_PARTS-1:0]                              ramReady;


  genvar rp;
  genvar wp;
  genvar wp1;
  genvar part;
  generate
    for(rp = 0; rp < NUM_RD_PORTS; rp++)
    begin
      assign addrPartition[rp]   = addr_i[rp][INDEX-NUM_PARTS_LOG-1:0];
      assign addrPartSelect[rp]  = addr_i[rp][INDEX-1:INDEX-NUM_PARTS_LOG];
    end

    for(wp = 0; wp < NUM_WR_PORTS; wp++)
    begin
      assign addrWrPartition[wp]   = addrWr_i[wp][INDEX-NUM_PARTS_LOG-1:0];
      assign addrWrPartSelect[wp]  = addrWr_i[wp][INDEX-1:INDEX-NUM_PARTS_LOG];
    end

    for(part = 0; part < NUM_PARTS; part++)//For every dispatch lane read port pair
    begin:INST_LOOP
      wire [NUM_WR_PORTS-1:0] writeEnPartition;
      for(wp1 = 0; wp1 < NUM_WR_PORTS; wp1++)//For every dispatch lane write port
      begin
        // NOTE: Gating of wrEn for dynamic width is done in RAM_STATIC_CONFIG module.
        // The RAM_PARTITIONED module is only responsible for gating and MUXing for partitioning,
        // which is only relevant in case of DYNAMIC_SIZE. Actually, RAM_PARTITIONED will be used
        // only if DYNAMIC_SIZE is enabled. Otherwise non-partitioned RAM will be used.
        assign writeEnPartition[wp1]  = wrEn_i[wp1] & |(addrWrPartSelect[wp1] == part);
      end

      RAM_STATIC_CONFIG 
      #(
        .DEPTH(DEPTH/NUM_PARTS),
        .INDEX(INDEX-NUM_PARTS_LOG),
        .WIDTH(WIDTH),
        .NUM_WR_PORTS(NUM_WR_PORTS),
        .NUM_RD_PORTS(NUM_RD_PORTS),
        .WR_PORTS_LOG(WR_PORTS_LOG),
        .DYNAMIC_WIDTH(DYNAMIC_WIDTH),
        .DYNAMIC_SIZE(DYNAMIC_SIZE),
        .RESET_VAL(RESET_VAL),
        .SEQ_START(SEQ_START+(part*DEPTH/NUM_PARTS)),
        .GATING_ENABLED(GATING_ENABLED),
        .LATCH_BASED_RAM(LATCH_BASED_RAM),
        .PARENT_MODULE({PARENT_MODULE,"_RAM_STATIC"})
      ) ram_instance
      ( 
        .writePortGated_i   (writePortGated_i), 
        .readPortGated_i    (readPortGated_i), 
        .ramGated_i         (partitionGated_i[part]),
        .addr_i             (addrPartition),
        .addrWr_i           (addrWrPartition), //Write to the same address in RAM for each read port
        .wrEn_i             (writeEnPartition),
        .dataWr_i           (dataWr_i),  // Write the same data in each RAM for each read port
        .clk                (clk),
        .reset              (reset),
        .data_o             (rdData[part]),
        .ramReady_o         (ramReady[part])
      );

    end //for INSTANCE_LOOP
  endgenerate

  /* RAM reset state machine */
  assign ramReady_o = &ramReady;

  /* Read operation */
  always_comb 
  begin
    int rp;
    for(rp = 0; rp< NUM_RD_PORTS; rp++)
    begin
      case(addrPartSelect[rp])
        0: data_o[rp] = rdData[0][rp];
        1: data_o[rp] = rdData[1][rp];
        2: data_o[rp] = rdData[2][rp];
        3: data_o[rp] = rdData[3][rp];
        4: data_o[rp] = rdData[4][rp];
        5: data_o[rp] = rdData[5][rp];
        6: data_o[rp] = rdData[6][rp];
        7: data_o[rp] = rdData[7][rp];
      endcase
    end
  end
  //always_comb 
  //begin
  //  int rp;
  //  for(rp = 0; rp< NUM_RD_PORTS; rp++)
  //  begin
  //    data_o[rp] = rdData[addrPartSelect[rp]][rp];
  //  end
  //end

endmodule


