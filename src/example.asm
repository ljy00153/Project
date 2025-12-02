# -----------------------------
# 初始化 CSRs & 其他設定（示意）
# -----------------------------
# 這裡如果要用 CFG_SET 可以這樣：
#   CFG_SET DATA_FLOW, CSR[13]   # DATA_FLOW
#   CFG_SET DRAM_IFMAP_ADDR, DRAM_IFMAP_BASE
#   CFG_SET DRAM_W_ADDR,   DRAM_WEIGHT_BASE
#   CFG_SET DRAM_OFMAP_ADDR, DRAM_OFMAP_BASE
#   CFG_SET GLB_IFMAP_ADDR, GLB_IFMAP_BASE
#   CFG_SET GLB_WEIGHT_ADDR, GLB_WEIGHT_BASE
#   CFG_SET GLB_OPSUM_ADDR, GLB_OPSUM_BASE

# SET_PE_EN_CONFIG 等同於把 valid_e 寫進 e（REG[7]），這裡只是示意：
# LOADI e, 3   # 例如 valid_e = 3 row enable，COMPUTE 會讀 REG[6/7] 由你決

# -----------------------------
# 初始化 count 計數器
# -----------------------------
# count_b   -> b
# count_tn  -> n
# count_tk  -> k
# count_K   -> inf
# count_N   -> outf

CFG_SET DRAM_IFMAP_BASE, DRAM_IFMAP_BASE 
CFG_SET DRAM_WEIGHT_BASE,DRAM_WEIGHT_BASE
CFG_SET DRAM_OFMAP_BASE,DRAM_OFMAP_BASE
CFG_SET GLB_IFMAP_BASE,GLB_IFMAP_BASE
CFG_SET GLB_WEIGHT_BASE,GLB_WEIGHT_BASE
CFG_SET GLB_OPSUM_BASE,GLB_OPSUM_BASE
CFG_SET OF_SIZE,OF_SIZE
CFG_SET IF_SIZE,IF_SIZE
CFG_SET B_SIZE,B_SIZE
CFG_SET K_SIZE,K_SIZE
CFG_SET N_SIZE,N_SIZE
CFG_SET M_SIZE,M_SIZE
CFG_SET MODE,MODE #PC=0x000c


#ADDI m,x0,     32
#ADDI n,x0,     4      
#ADDI k,x0,     2    
#ADDI b,x0,     1     
#ADDI inf,x0,   59   
#ADDI outf,x0,  2   

ADDI m,x0,     0
ADDI n,x0,     0      
ADDI k,x0,     0    
ADDI b,x0,     0     
ADDI inf,x0,   0   
ADDI outf,x0,  0  

#ADDI r7,x0,0 
#ADDI r8,x0,0
#ADDI r9,x0,0
#ADDI r10,x0,0
#ADDI r11,x0,0
#ADDI r12,x0,0 #PC=0x0018

# ------------------------------------------------
# D2G_IFM block：從 DRAM 把 IFMAP / WEIGHT 搬到 GLB
# ------------------------------------------------
D2G_WEIGHT_LOOP:

    # D2G_WEIGHT
    DMA_LOAD_WEIGHT  DRAM_WEIGHT_BASE, x0,4608   
    WAIT DMA 

    ADDI inf, x0, 0
D2G_IFM_LOOP_inf:
    ADDI b, x0, 0 
               
D2G_IFM_LOOP_b:
    # D2G_IFM
    DMA_LOAD_IFMAP   DRAM_IFMAP_BASE, x0, 1152    
    WAIT DMA                                   

                                       

# ------------------------------------------------
# G2P_WEIGHT block：從 GLB 把 weight 丟到 PE
# ------------------------------------------------
    ADDI k, x0, 0                              
G2P_WEIGHT_LOOP_k:
    ADDI n, x0, 0                              

G2P_WEIGHT_LOOP_n:
    G2P GLB_WEIGHT_BASE, x0,576                
    WAIT GLB                                  

# ------------------------------------------------
# G2P_IFM block：ifmap + ipsum 丟到 PE，再把 opsum 收回
# ------------------------------------------------
    ADDI m, x0, 0                              

G2P_IFM_LOOP:

    # G2P_IFM
    G2P GLB_IFMAP_BASE, x0, 18                 
    WAIT GLB                                    

    # G2P_IPSUM  (這裡用 GLB_OPSUM_BASE 表示 psum/ipsum)
    G2P GLB_OPSUM_BASE, x0, 32                  
    WAIT GLB                                   

    # P2G_OPSUM
    P2G_OPSUM GLB_OPSUM_BASE, x0, 32            
    WAIT GLB                                   

    # -------------------
    # batch 內的迴圈（count_m）
    # -------------------
    LOOP M_SIZE, m, G2P_IFM_LOOP, 1             

    # -------------------
    # tn 迴圈（count_tn）
    # -------------------
    LOOP N_SIZE, n, G2P_WEIGHT_LOOP_n, 1         

    # -------------------
    # tk 迴圈（count_tk）
    # -------------------
    LOOP K_SIZE, k, G2P_WEIGHT_LOOP_k, 1          
    # -------------------
    # b 迴圈（count_b）
    # -------------------
    LOOP B_SIZE, b, D2G_IFM_LOOP_b, 1   
    # -------------------
    # K 維度迴圈（count_K）
    # -------------------
    LOOP IF_SIZE, inf, D2G_IFM_LOOP_inf, 1         

# ------------------------------------------------
# 把 OFMAP 從 GLB 寫回 DRAM
# ------------------------------------------------
G2D_OFM_LOOP:
    DMA_STORE_OFMAP DRAM_OFMAP_BASE, x0, 8192     
    WAIT DMA                                    

    # -------------------
    # N 維度迴圈（count_N）
    # -------------------
    LOOP OF_SIZE, outf, D2G_WEIGHT_LOOP, 1         
END
