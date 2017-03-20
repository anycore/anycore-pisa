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

`define  FETCH_LANE_ACTIVE              {{`FETCH_WIDTH-2{1'b0}},2'b11};
`define  DISPATCH_LANE_ACTIVE           {{`DISPATCH_WIDTH-2{1'b0}},2'b11};
`define  ISSUE_LANE_ACTIVE              {{`ISSUE_WIDTH-4{1'b0}},4'b1111};
`define  EXEC_LANE_ACTIVE               {{`EXEC_WIDTH-4{1'b0}},4'b1111};
`define  SALU_LANE_ACTIVE               {{`EXEC_WIDTH-4{1'b0}},4'b1100};
`define  CALU_LANE_ACTIVE               {{`EXEC_WIDTH-4{1'b0}},4'b0100};
`define  COMMIT_LANE_ACTIVE             {{`COMMIT_WIDTH-2{1'b0}},2'b11};
