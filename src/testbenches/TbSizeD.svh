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

`define  RF_PARTITION_ACTIVE            {{`NUM_PARTS_RF-4{1'b0}},4'b1111};
`define  AL_PARTITION_ACTIVE            {{`NUM_PARTS_RF-4{1'b0}},4'b1111};
`define  LSQ_PARTITION_ACTIVE           {{`STRUCT_PARTS_LSQ-2{1'b0}},2'b11};
`define  IQ_PARTITION_ACTIVE            {{`STRUCT_PARTS-4{1'b0}},4'b1111};
`define  IBUFF_PARTITION_ACTIVE         {{`STRUCT_PARTS-2{1'b0}},2'b11};
