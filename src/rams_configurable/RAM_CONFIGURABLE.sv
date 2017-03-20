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

module RAM_CONFIGURABLE #(
	/* Parameters */
	parameter DEPTH = `RAM_CONFIG_DEPTH,
	parameter INDEX = `RAM_CONFIG_INDEX,
	parameter WIDTH = `RAM_CONFIG_WIDTH,
  parameter NUM_WR_PORTS = `RAM_CONFIG_WP,
  parameter NUM_RD_PORTS = `RAM_CONFIG_RP,
  parameter WR_PORTS_LOG = `RAM_CONFIG_WP_LOG,
  parameter USE_RAM_2READ = 0,
  parameter USE_PARTITIONED = 1,
  parameter DYNAMIC_WIDTH = `RAM_CONFIG_DYNAMIC_WIDTH,
  parameter DYNAMIC_SIZE = `RAM_CONFIG_DYNAMIC_SIZE,
  parameter SHARED_DECODE = 0,
  parameter USE_FLIP_FLOP = 0,
  parameter LATCH_BASED_RAM = 0,
  parameter GATING_ENABLED = 1,
  parameter NUM_PARTS    = `STRUCT_PARTS,
  parameter NUM_PARTS_LOG= `STRUCT_PARTS_LOG,
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

  genvar rp;
  genvar wp;
  generate
    // Use non-partitioned RAM if not dynamic size
    if(USE_FLIP_FLOP | !DYNAMIC_SIZE)
    begin:FLIP_FLOP
      RAM_STATIC_CONFIG 
      #(
        .DEPTH(DEPTH),
        .INDEX(INDEX),
        .WIDTH(WIDTH),
        .NUM_WR_PORTS(NUM_WR_PORTS),
        .NUM_RD_PORTS(NUM_RD_PORTS),
        .WR_PORTS_LOG(WR_PORTS_LOG),
        .DYNAMIC_WIDTH(DYNAMIC_WIDTH),
        .DYNAMIC_SIZE(DYNAMIC_SIZE),
        .RESET_VAL(RESET_VAL),
        .SEQ_START(SEQ_START),
        .GATING_ENABLED(1),
        .PARENT_MODULE(PARENT_MODULE)
      ) ram_static
      ( 
        .writePortGated_i   (writePortGated_i), 
        .readPortGated_i    (readPortGated_i), 
        .ramGated_i         (1'b0),
        .addr_i             (addr_i),
        .addrWr_i           (addrWr_i), //Write to the same address in RAM for each read port
        .wrEn_i             (wrEn_i),
        .dataWr_i           (dataWr_i),  // Write the same data in each RAM for each read port
        .clk                (clk),
        .reset              (reset),
        .data_o             (data_o),
        .ramReady_o         (ramReady_o)
      );

    end
    else if(SHARED_DECODE) 
    begin: PARTITIONED_SHARED_DECODE

	    reg [NUM_RD_PORTS-1:0][DEPTH-1:0]               addrDecoded;
	    reg [NUM_RD_PORTS-1:0][NUM_PARTS_LOG-1:0]       rdDataPartition;
	    reg [NUM_WR_PORTS-1:0][DEPTH-1:0]               addrWrDecoded;

      reg  [INDEX-1:0]                                addrGated    [NUM_RD_PORTS-1:0];
      reg  [INDEX-1:0]                                addrWrGated  [NUM_WR_PORTS-1:0];
      reg  [NUM_WR_PORTS-1:0]                         wrEnGated;


      //Signal Gating the addresses before decoding them to reduce dynamic power
      // consumption

      int i;
      always_comb
      begin
        // If input gating enabled and dynamic width, gate both wrEn and addr
        if(GATING_ENABLED & DYNAMIC_WIDTH) 
        begin
          for(i = 0; i < NUM_WR_PORTS; i++)//For every write port
          begin:ADDR_LOOP_WP_GATED
            // Gating the write enable is important. Otherwise, stray wrEn will 
            // write to location 0 in all RAMs as all addrWrGated are 0 after 
            // signal gating.
            wrEnGated[i]        = (writePortGated_i[i] ? 1'b0 : wrEn_i[i]);
            addrWrGated[i]      = (writePortGated_i[i] ? {INDEX{1'b0}} : addrWr_i[i]);
		        addrWrDecoded[i]    = 1 << addrWrGated[i];
          end
          for(i = 0; i < NUM_RD_PORTS; i++)//For every read port
          begin:ADDR_LOOP_RP_GATED
            addrGated[i]        = (readPortGated_i[i] ? {INDEX{1'b0}} : addr_i[i]);
		        addrDecoded[i]      = 1 << addrGated[i];
            rdDataPartition[i]  = addrGated[i][INDEX-1:INDEX-NUM_PARTS_LOG];
          end
        end
        else 
        begin
          for(i = 0; i < NUM_WR_PORTS; i++)//For every write port
          begin:ADDR_LOOP_WP
            // If input gating not enabled and dynamic width, gate only wrEn
            if(DYNAMIC_WIDTH) 
              wrEnGated[i]        = (writePortGated_i[i] ? 1'b0 : wrEn_i[i]);
            else
              wrEnGated[i]        = wrEn_i[i];

            addrWrGated[i]      = addrWr_i[i];
		        addrWrDecoded[i]    = 1 << addrWrGated[i];
          end
          for(i = 0; i < NUM_RD_PORTS; i++)//For every read port
          begin:ADDR_LOOP_RP
            addrGated[i]        = addr_i[i];
		        addrDecoded[i]      = 1 << addrGated[i];
            rdDataPartition[i]  = addrGated[i][INDEX-1:INDEX-NUM_PARTS_LOG];
          end
        end
      end

      RAM_PARTITIONED_NO_DECODE #(
      	/* Parameters */
      	.DEPTH(DEPTH),
      	.INDEX(INDEX),
      	.WIDTH(WIDTH),
        .NUM_WR_PORTS(NUM_WR_PORTS),
        .NUM_RD_PORTS(NUM_RD_PORTS),
        .WR_PORTS_LOG(WR_PORTS_LOG),
        .NUM_PARTS(NUM_PARTS),
        .NUM_PARTS_LOG(NUM_PARTS_LOG),
        .RESET_VAL(RESET_VAL),
        .SEQ_START(SEQ_START),   
        .PARENT_MODULE({PARENT_MODULE,"_NO_DECODE"})
      ) ram_partitioned
      (
      
        .rdDataPartition_i(rdDataPartition),

        //.writePortGated_i(writePortGated_i),
        //.readPortGated_i(readPortGated_i),
        .partitionGated_i(partitionGated_i),
      
      	.addr_i(addrDecoded),
      	.data_o(data_o),
      
      	.addrWr_i(addrWrDecoded),
      	.dataWr_i(dataWr_i),
      
      	.wrEn_i(wrEnGated),
      
      	.clk(clk),
      	.reset(reset),
        .ramReady_o(ramReady_o)
      );

    end
    else if(USE_PARTITIONED) 
    begin: PARTITIONED
      RAM_PARTITIONED #(
      	/* Parameters */
      	.DEPTH(DEPTH),
      	.INDEX(INDEX),
      	.WIDTH(WIDTH),
        .NUM_WR_PORTS(NUM_WR_PORTS),
        .NUM_RD_PORTS(NUM_RD_PORTS),
        .WR_PORTS_LOG(WR_PORTS_LOG),
        .NUM_PARTS(NUM_PARTS),
        .NUM_PARTS_LOG(NUM_PARTS_LOG),
        .DYNAMIC_WIDTH(DYNAMIC_WIDTH),
        .DYNAMIC_SIZE(DYNAMIC_SIZE),
        .LATCH_BASED_RAM(LATCH_BASED_RAM),
        .GATING_ENABLED(GATING_ENABLED),
        .RESET_VAL(RESET_VAL),
        .SEQ_START(SEQ_START),   
        .PARENT_MODULE(PARENT_MODULE)
      ) ram_partitioned
      (
      
        .writePortGated_i(writePortGated_i),
        .readPortGated_i(readPortGated_i),
        .partitionGated_i(partitionGated_i),
      
      	.addr_i(addr_i),
      	.data_o(data_o),
      
      	.addrWr_i(addrWr_i),
      	.dataWr_i(dataWr_i),
      
      	.wrEn_i(wrEn_i),
      
      	.clk(clk),
      	.reset(reset),
        .ramReady_o(ramReady_o)
      );


    end
    else
    begin:REPLICATED  
      localparam NUM_RD_PORTS_INT = USE_RAM_2READ ? NUM_RD_PORTS/2 : NUM_RD_PORTS; 

      reg  [DEPTH-1:0][WR_PORTS_LOG-1:0] ramSelect;
      wire [NUM_WR_PORTS-1:0][NUM_RD_PORTS_INT-1:0] powerGate; 
      wire [NUM_RD_PORTS*NUM_WR_PORTS-1:0][WIDTH-1:0] rdData;
      wire [NUM_WR_PORTS-1:0]  writeEn;

      //TODO: Write the fast restore to RAMs corresponding to read 
      // ports that come out of power gating. Do this by reading multiple
      // values from non power gated ports and writing them through equal
      // number of write ports. Number of cycles required will depend upon
      // how many writes are made in one cycle [Min(NPG read ports,Write Ports)].
      // This can restore multiple read ports at the same time as a write
      // through on of the write ports will write to all read port rams
      // if they are NPG. Assert the ready signal low when this is in progress.
      // TODO:Clock gate this restore logic when not in use to save power.



      for(wp = 0; wp < NUM_WR_PORTS; wp++)//For every dispatch lane write port
      begin:INST_LOOP_WP
        // Mask the write_enables for inactive write lanes to avoid writes from
        // stray write enables

        //TODO: Add an assertion to check for stray write_enables
        //`ifdef SIM
        //  if(wrEn_i[wp] & writePortGated_i[wp])
        //    //$display("***RAM_CONFIGURABLE:: %s Stray write enable in lane %X when write port power gated",PARENT_MODULE, wp);
        //`endif

        assign writeEn[wp]  = wrEn_i[wp] & ~writePortGated_i[wp];

        for(rp = 0; rp < NUM_RD_PORTS_INT; rp++)//For every dispatch lane read port pair
        begin:INST_LOOP_RP
          // TODO: More power saving possible by power gating RAMs corresponding
          // power gated write ports but this will lead to complexity in physical
          // design. Also, when a write port enters power gated mode, the valid
          // locations in that particular RAM has to be copied to RAMs corresponding
          // to active write ports. Can be done using the restore logic for read
          // ports.
          //assign powerGate[wp][rp] = writePortGated_i[wp] | readPortGated_i[rp];
          if(USE_RAM_2READ)
          begin: ram_2read
            // Two read ports go to the same RAM
            // So even if one of them is active, the
            // RAM needs to be active
            assign powerGate[wp][rp] = readPortGated_i[rp*2] & readPortGated_i[rp*2+1];
            RAM_PG_2R1W 
            #(
              .DEPTH(DEPTH),
              .WIDTH(WIDTH),
              .INDEX(INDEX),
              .RESET_VAL(RESET_VAL),
              .SEQ_START(SEQ_START)
            ) ram2r1w
            ( 
              .pwrGate_i(powerGate[wp][rp]), 
              .addr0_i  (addr_i[rp*2]),
              .addr1_i  (addr_i[rp*2+1]),
              .addrWr_i (addrWr_i[wp]), //Write to the same address in RAM for each read port
              .we_i     (writeEn[wp]),
              .data_i   (dataWr_i[wp]),  // Write the same data in each RAM for each read port
              .clk      (clk),
              .reset    (reset),
              .data0_o  (rdData[wp*NUM_RD_PORTS+(rp*2)]),
              .data1_o  (rdData[wp*NUM_RD_PORTS+(rp*2+1)])
            );

          end
          else
          begin: ram_1read
            assign powerGate[wp][rp] = readPortGated_i[rp];
            RAM_PG_1R1W 
            #(
              .DEPTH(DEPTH),
              .WIDTH(WIDTH),
              .INDEX(INDEX),
              .RESET_VAL(RESET_VAL),
              .SEQ_START(SEQ_START)
            ) ram1r1w
            ( 
              .pwrGate_i(powerGate[wp][rp]), 
              .addr0_i  (addr_i[rp]),
              .addrWr_i (addrWr_i[wp]), //Write to the same address in RAM for each read port
              .we_i     (writeEn[wp]),
              .data_i   (dataWr_i[wp]),  // Write the same data in each RAM for each read port
              .clk      (clk),
              .reset    (reset),
              .data0_o  (rdData[wp*NUM_RD_PORTS+rp])
            );
          end //ram_1read
        end //for NUM_RD_PORTS_INT
      end
      /* RAM reset state machine */
      //TODO: To be used in future if requred
      assign ramReady_o = ~reset;


      /* Write operation */
      always_ff @(posedge clk)
      begin
        int wp;
        int rp;
      
      	if (reset)
      	begin
      		for (rp = 0; rp < DEPTH; rp++)
      		begin
      			ramSelect[rp] <= 0;
      		end
      	end
      
      	else
      	begin
          // TODO: Write an assert to make sure all write ports have diffrent addresses
          // TODO: Make it parallel so that it has no priority involved
          for(wp = 0; wp < NUM_WR_PORTS; wp++)
            if(wrEn_i[wp] & ~writePortGated_i[wp])
              ramSelect[addrWr_i[wp]] <= wp;
      
      	end
      end

      /* Read operation */
      always_comb
      begin
        int rp;
        reg [WR_PORTS_LOG-1:0] latest_ram[NUM_RD_PORTS-1:0];
        for(rp = 0; rp< NUM_RD_PORTS; rp++)
        begin
          latest_ram[rp] = ramSelect[addr_i[rp]];
          data_o[rp] = rdData[rp+latest_ram[rp]*NUM_RD_PORTS];
        end
      end
    end // REPLICATED
  endgenerate

endmodule


