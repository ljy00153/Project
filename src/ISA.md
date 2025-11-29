## CSRfile:
0:IFMAP_BASE
1:W_BASE
2:OFM_BASE
3:IFM_SIZE
4:W_SIZE    
5:OFM_SIZE
6:M_SIZE
7:N_SIZE
8:K_SIZE
9:B_SIZE
10:MODE
11:DATAFLOW
12:Out_f
13:In_f
14:Batch

## COMMAND
```
NOP       = 6'b000000,
SET_CSR=6'b000001,
SET_PE_EN_CONFIG (1 cycle)=6'b000010,
SET_LN_config_XID_config_YID_config=6'b000011,
 
D2G_IFM  = 6'b000100, // DMA read IFM
D2G_WEIGHT  = 6'b000101, // DMA read weights
D2G_IPSUM= 6'b000110,// DMA read IPSUM
G2D_OFM = 6'b000111, // DMA write OFM

G2P_IFM = 6'b001100,//GLB to PE IFMAP
G2P_WEIGHT= 6'b001101, //GLB to PE WEIGHT
G2P_IPSUM= 6'b001110, //GLB to PE IPSUM
P2G_OPSUM = 6'b001111,//PE to GLB OPSUM

WAIT      = 6'b001000, // wait for events mask
BLT      = 6'b001001, // branch less than (BLT count,Batch)
ADDI        =6'b001010,// ADD intermediate(ADDI count,1)
END       = 6'b111111  // program end
```
## EXAMPLE MINICODE CODE 
```python
#DMA一次讀取完再跑GLB
SET_CSR
SET_LN_config_XID_config_YID_config 
SET_PE_EN_CONFIG

#初始化count計數器 (還是需要r0 r1這些register)
ADDI x0,r0,0 #countb
ADDI x0,r1,0 #counttn
ADDI x0,r2,0 #counttk
ADDI x0,r3,0 #countK
ADDI x0,r4,0 #countN

#DMA
<D2G_IFM>
D2G_IFM 
WAIT(DMA_DONE) 
D2G_WEIGHT
WAIT(DMA_DONE)


#dataflow control
<G2P_WEIGHT>
G2P_WEIGHT
WAIT(G2P_WEIGHT_done)

<G2P_IFM>
G2P_IFM
WAIT(G2P_IFM_done)
G2P_IPSUM
WAIT(G2P_IPSUM_done)
P2G_OPSUM
WAIT(P2G_OPSUM_done)

ADDI count_b,1 #count_b++
BLT count_b,CSR_BATCH,<G2P_IFM> #回到G2P_IFM，直到Batch跑完

ADDI count_tn,1 #count_tn++
BLT count_tn,N/tn,<G2P_WEIGHT>#回到G2P_WEIGHT，直到GLB的資料都做完運算

ADDI count_tk,1 #count_tk++
BLT count_tk,K/tk,<G2P_WEIGHT>
 
ADDI count_K,1 #count_K++
BLT count_K,In_f/(K*12),<D2G_IFM>#回到D2G_IFM直到把K維度都跑完

G2D_OFM #output OFMAP to DRAM
WAIT(DMA_DONE) 

ADDI count_N,1 #count_N++
BLT count_N,Out_f/(N*4),<D2G_IFM>#回到D2G_IFM直到把N維度都跑完

END
#這些N/tn K/tk tile數量應該會在host算好再存進來
```
