
#in feature = 128 * 8 * 8 = 8192
#batch = 64
#out feature = 256

#set constant
.set IF, 8192 
.set OF, 256
.set B, 64
.set M, 64
.set K, 144 # K * 3 * 4
.set N, 128 # N * 4
.set outf_offest, 128 # N * 4
.set inf_offest, 144 # K * 3 * 4 
.set b_offest, 64 # M
.set k_offest, 72 # tk * 3 * 4
.set n_offest, 32 # tn * 4
.set m_offest, 1  # mode

.set PE_ARRAY_WEIGHT_SIZE, 2304  # 48 * 12
.set PE_ARRAY_IPSUM_SIZE, 128    # 8 * 1 * 4 * 4byte
.set PE_ARRAY_IFMAP_SIZE, 72   # 48 * 3
.set DRAM_IFMAP_SIZE, 9216      # M * K * 12
.set DRAM_WEIGHT_SIZE, 18432    # K * N * 48
.set DRAM_OPSUM_SIZE, 32768     # B * N * 16
.set DRAM_IFMAP_SIZE_per_fetch, 4608      # M * tk * 12
.set DRAM_WEIGHT_SIZE_per_fetch, 2304    # tK * tN * 48
.set DRAM_OPSUM_SIZE_per_fetch, 0     # B * N * 16
#.set DRAM_IFMAP_SIZE, 0      # M * K * 12
#.set DRAM_WEIGHT_SIZE, 0    # K * N * 48
#.set DRAM_OPSUM_SIZE, 0     # B * N * 16
SET_ID
CFG_SET DRAM_IFMAP_BASE,     0
CFG_SET DRAM_WEIGHT_BASE,    1
CFG_SET DRAM_OFMAP_BASE,     2
CFG_SET GLB_IFMAP_BASE,      3
CFG_SET GLB_WEIGHT_BASE,     4
CFG_SET GLB_OPSUM_BASE,      5
CFG_SET OF_SIZE, 6
CFG_SET IF_SIZE, 7
CFG_SET B_SIZE,  8
CFG_SET K_SIZE,  9
CFG_SET N_SIZE,  10
CFG_SET M_SIZE,  11
CFG_SET MODE,    12
CFG_SET DATA_FLOW, 13

LOADI outf,  0
LOADI inf,   0
LOADI b,     0
LOADI k,     0
LOADI n,     0
LOADI m,     0
LOADI REG[7], 6
LOADI REG[8], 0
LOADI REG[9], 0
LOADI REG[10], 0
LOADI REG[11], 0
LOADI REG[12], 0 #next_k
LOADI REG[13], 0
LOADI REG[14], 0
LOADI REG[15], 0 #next_n
LOADI REG[16], 0 
# Output feature tiles
loop_outf:
    #load PSUM to GLB
    DMA_LOAD_PSUM DRAM_OFMAP_BASE, outf, DRAM_OPSUM_SIZE
    WAIT DMA
    loop_inf:
        #load WEIGHT to GLB
        #compute index
        ADD REG[8], k, inf
        MULI REG[8], REG[8] , OF
        ADD REG[8], REG[8], outf
        ADD REG[8], REG[8], n #REG[8] = (inf *(out_features + k)  + outf + n);
        DMA_LOAD_WEIGHT DRAM_WEIGHT_BASE, REG[8], DRAM_WEIGHT_SIZE_per_fetch
        WAIT DMA
        loop_b:
            #load IFMAP to GLB
            #compute index
            MULI REG[9], b, IF
            ADD REG[9], REG[9], inf #REG[9] = (b * in_feature + inf);
            DMA_LOAD_IFMAP DRAM_IFMAP_BASE, REG[9], DRAM_IFMAP_SIZE
            WAIT DMA
            loop_k:
                
                loop_n:
                    #prefetch and compute weight index
                    WAIT DMA

                    ##############################
                    #prefetch weight pseudo code:
                    #if (b==0){ 只有b==0需要預取weight
                        #if (next_n == N_SIZE) {
                        #   next_n=0;
                        #   next_k+=k_offest;
                        #   if(next_k == K_SIZE) {
                        #       next_k=0;
                        #       next_inf+=inf_offest;
                        #       if(next_inf == IF_SIZE){ inf、outf還沒有做，因為REG不夠
                        #           next_inf=0;
                        #           next_outf+=outf_offest;
                        #           if(next_outf == OF_SIZE){
                        #               next_outf=0;
                        #               jump after_prefetch
                    #           }
                    #       }
                    #   }
                    # }
                    #  prefetch:
                    #  DRAM_LOAD
                    #  after_prefetch:                   
                    ##############################
                    ADDI REG[15], n, n_offest #next_n
                    LOOP N_SIZE, REG[15], prefetch,0 
                    ADDI REG[15], REG[0], 0       #reset next_n
                    ADDI REG[12], k, k_offest     #next_k
                    LOOP K_SIZE, REG[12], prefetch, k_offest
                    ADDI REG[12],REG[0], 0        #reset next_k     
                    jump after_prefetch
                           
                    prefetch:
                    ADD REG[8], REG[12], inf
                    MULI REG[8], REG[8] , OF
                    ADD REG[8], REG[8], outf
                    ADD REG[8], REG[8], REG[15] #REG[8] = (inf+ k) *out_features  + outf + n;
                    DMA_LOAD_WEIGHT DRAM_WEIGHT_BASE, REG[8], DRAM_WEIGHT_SIZE_per_fetch

                    after_prefetch:
                    #load weight to pe array
                    CPT_TAGXY WEIGHT
                    #compute index
                    MULI REG[10], k, N
                    ADD REG[10], REG[10], n
                    G2P GLB_WEIGHT_BASE, REG[10], PE_ARRAY_WEIGHT_SIZE
                    WAIT GLB
                    loop_m:
                        #load ipsum to pe array
                        CPT_TAGXY IPSUM
                        #compute index
                        ADD REG[11], b, m
                        MULI REG[11], REG[11], N_SIZE
                        ADD REG[11], REG[11], n
                        G2P GLB_OPSUM_BASE, REG[11], PE_ARRAY_IPSUM_SIZE
                        WAIT GLB
                        #load ifmap to pe array
                        CPT_TAGXY IFMAP
                        #compute index
                        MULI REG[13], m, K
                        G2P GLB_IFMAP_BASE, REG[13], PE_ARRAY_IFMAP_SIZE
                        WAIT GLB
                        #start pe array
                        COMPUTE
                        WAIT PE_ARRAY
                        #write to GLB
                        CPT_TAGXY OPSUM
                        P2G_OPSUM GLB_OPSUM_BASE, REG[11], PE_ARRAY_IPSUM_SIZE
                        LOOP M_SIZE, m, loop_m, m_offest
                    LOOP N_SIZE, n, loop_n, n_offest
                LOOP K_SIZE, k, loop_k, k_offest
            LOOP B_SIZE, b, loop_b, b_offest
        LOOP IF_SIZE, inf, loop_inf, inf_offest
    #write opsum to DRAM
    CPT_TAGXY OPSUM
    DMA_STORE_OFMAP DRAM_OFMAP_BASE, outf, DRAM_OPSUM_SIZE
    WAIT DMA
    LOOP OF_SIZE, outf, loop_outf, outf_offest
    END