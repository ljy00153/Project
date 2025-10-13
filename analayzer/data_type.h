struct LinearShapeParam
{
    int B;  // batch size
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
    int mode;
    //1: 6個PE累加，共一組
    //2: 3個PE累加，共兩組
    //3: 2個PE累加，共三組
    //4: 1個PE累加，共六組
    int M;
    int K; 
    int N; // K * 1 * 3 + K * N * 12 < 64kb
};

struct AnalysisResult
{
    int pe_array_h;
    int pe_array_w;
    int tk; //1~6
    int tn; //1~8
    int mode;
    int M;
    int K; 
    int N; // K * 1 * 3 + K * N * 12 < 64kb

    int glb_usage;
    long long int glb_read;
    long long int glb_write;   
    long long int glb_access;

    long long int dram_read;
    long long int dram_write;    
    long long int dram_access;

    long long int macs;
    double latency;


    double energy_total;
    double power_total;

    double intensity;
    double peak_performance;
    double peak_bandwidth;
};