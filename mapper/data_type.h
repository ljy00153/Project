struct LinearShapeParam
{
    int N;  // batch size
    int in_features;
    int out_features;
};

struct EyerissHardwareParam
{
    int pe_array_h;
    int pe_array_w;
    int ifmap_spad_size;
    int filter_spad_size;
    int psum_spad_size;
    int glb_size;
    int bus_bw;
    int noc_bw;
};

struct EyerissMappingParam
{
    int tk; //1~6
    int tn; //1~8
    int K; 
    int N; // K * 1 * 3 + K * N * 12 < 64kb
};

struct AnalysisResult
{
    int glb_usage;
    int glb_access;
    int dram_access;
    int macs;
    int latency;
    int glb_read;
    int glb_write;
    int dram_read;
    int dram_write;
    float energy_total;
    float power_total;
    float intensity;
    float peak_performance;
    float peak_bandwidth;
};