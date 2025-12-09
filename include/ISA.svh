`ifndef AXI_DEFINE
`define AXI_DEFINE
//00000x
`define OP_NOP                      = 6'b000000 // no operation
`define OP_CFG_SET                  = 6'b000001 // SET CSR
`define OP_SET_ID                   = 6'b000010 // SET_LN、SET_XID、SET_YID

//0001xx
`define OP_DMA_LOAD_IFMAP           = 6'b000100 // DMA read ifmap
`define OP_DMA_LOAD_WEIGHT          = 6'b000101 // DMA read weights
`define OP_DMA_LOAD_PSUM            = 6'b000110 // DMA read psum
`define OP_DMA_STORE_OFMAP          = 6'b000111 // DMA write ofmap

//00100x
`define OP_G2P	                    = 6'b001000	// GLB → PE
`define OP_P2G_OPSUM	            = 6'b001001	// PE → GLB opsum

//0100xx
`define OP_CPT_INDEX	            = 6'b010000	//compute index in GLB

//011000
`define OP_CPT_TAGXY	            = 6'b011000 //compute and SET tagX and tagY for BUS
                                        //ifmap:    tagX, tagY
                                        //weight:   tagX, tagY
                                        //ipsum:    tagX, tagY
                                        //opsum:    tagX, tagY
                                        //total 4 kind of tag -> 8 small Register
//0111xx
`define OP_COMPUTE                  = 6'b011100 // set pe enable
`define OP_WAIT                     = 6'b011101 // wait for ready of pe
`define OP_JUMP                     = 6'b011110 // absolute jump (pc = imm)
`define OP_LOOP                     = 6'b011111 // loop counter += offset, if loop counter > certain value, stop looping

//10000x
`define OP_LOADI                    = 6'b100000 // rd = imm
`define OP_ADDI                     = 6'b100001 // rd = rs + imm
`define OP_MULI                     = 6'b100010 // rd = rs1 * imm (unsigned)
//1001xx
`define OP_ADD                      = 6'b100100 // rd = rs1 + rs2
`define OP_MUL                      = 6'b100101 // rd = rs1 * rs2 (unsigned)


//111111
`define OP_END                      = 6'b111111 // program end


// type 
`define DMA_type                    = 4'b0001

`define STREAM_type                 = 5'b00100


`endif