#include <iostream>
#include <vector>
#include <string>
#include <cmath>

//#include "data_type.h"
using namespace std;

#define DATA_SIZE 1
#define PSUM_DATA_SIZE 4  // Byte
#define BUS_BANDWIDTH 4  // Byte

// Time
#define CLOCK_RATE 200 * 1e6  // 200 MHz
#define TIME_UNIT 1  // cycle
#define SPAD_ACCESS_TIME 1 * TIME_UNIT
#define GLB_ACCESS_TIME 2 * TIME_UNIT
#define DRAM_ACCESS_TIME 5 * TIME_UNIT

// Energy
#define ENERGY_UNIT 1e-6  // 1 pJ = 10^6 uJ
#define ENERGY_PER_MAC 2 * ENERGY_UNIT
#define ENERGY_PER_GLB_ACCESS 10 * ENERGY_UNIT
#define ENERGY_PER_DRAM_ACCESS 200 * ENERGY_UNIT
#define POWER_UNIT 1  // 1 uW
#define POWER_LEAKAGE 50 * POWER_UNIT



class EyerissAnalyzer
{
    public:
        EyerissHardwareParam hardware_param;
        EyerissMappingParam mapping;
        LinearShapeParam linear_shape;

        EyerissAnalyzer()
        {
            // Constructor implementation
        }

        EyerissHardwareParam hardware() const
        {
            return hardware_param;
        }

        void set_hardware(const EyerissHardwareParam& param)
        {
            hardware_param = param;
        }

        int in_features_used()
        {
            return mapping.tk * 12 * DATA_SIZE;
        }

        int weight_used()
        {
            return mapping.tn * mapping.tk * 48 * DATA_SIZE;
        }

        int psum_used()
        {
            return mapping.tn * 4 * PSUM_DATA_SIZE;
        }

        vector<pair<string, int>> glb_usage_per_pass()
        {
            vector<pair<string, int>> usage;

            usage.push_back({"i_linear", mapping.K * 3 * DATA_SIZE});
            usage.push_back({"weight_linear", mapping.K 
                                            * mapping.N * 12 * DATA_SIZE});
            usage.push_back({"o_linear", mapping.tn * 4 * PSUM_DATA_SIZE});
            usage.push_back({"total", usage[0].second + usage[1].second + usage[2].second});//3
            return usage;
        }

        bool glb_size_legal()
        {
            return glb_usage_per_pass()[3].second <= 64 * 1024; // 64KB
        }

        vector<pair<string, int>> dram_access_per_layer()
        {
            vector<pair<string, int>> res;
            //cout << "in_features" << linear_shape.in_features << endl;
            //cout << "mapping.K" << mapping.K << endl;
            int num_i_linear = ceil(float(linear_shape.in_features) / float(mapping.K));
            int num_weight_linear = num_i_linear * ceil(float(linear_shape.out_features) / float(mapping.N));

            res.push_back({"i_linear_read", num_i_linear * DATA_SIZE});
            res.push_back({"weight_linear_read", num_weight_linear * DATA_SIZE});
            res.push_back({"o_linear_read", 0}); // No read for output
            res.push_back({"o_linear_write", 0});// No write for output
            res.push_back({"read", res[0].second + res[1].second + res[2].second});
            res.push_back({"write", res[3].second});
            res.push_back({"total", res[4].second + res[5].second});//6
            return res;
        }

        vector<pair<string, int>> glb_access_per_layer()
        {
            vector<pair<string, int>> res;

            int num_i_linear = ceil(float(mapping.K) / float(mapping.tk));
            int num_weight_linear = num_i_linear * ceil(float(mapping.N) / float(mapping.tn));
            res.push_back({"i_linear_read", num_i_linear * DATA_SIZE});
            res.push_back({"weight_linear_read", num_weight_linear * DATA_SIZE});
            res.push_back({"o_linear_write", 0});
            res.push_back({"read", res[0].second + res[1].second});
            res.push_back({"write", res[2].second});
            res.push_back({"total", res[3].second + res[4].second});//5
            return res;
        }

        int latency_per_layer()
        {
            return (glb_access_per_layer()[5].second * GLB_ACCESS_TIME 
                    + dram_access_per_layer()[6].second * DRAM_ACCESS_TIME);
        }

        int macs_per_layer()
        {
            return linear_shape.in_features * linear_shape.out_features;
        }

        vector<pair<string, float>> energy_per_layer()
        {
            vector<pair<string, float>> res;
            float compute_energy = float(macs_per_layer()) * ENERGY_PER_MAC;
            float memory_energy = (
                glb_access_per_layer()[5].second * ENERGY_PER_GLB_ACCESS
                + dram_access_per_layer()[6].second * ENERGY_PER_DRAM_ACCESS
            );
            float leakage_energy = POWER_LEAKAGE * float(latency_per_layer()) / CLOCK_RATE;
            float total_energy = compute_energy + memory_energy + leakage_energy;

            res.push_back({"compute", compute_energy});
            res.push_back({"memory_energy", memory_energy});
            res.push_back({"leakage_energy", leakage_energy});
            res.push_back({"total_energy", total_energy});

            return res;
        } 

        vector<pair<string, float>> power_per_layer()
        {
            vector<pair<string, float>> res;
            float compute_power = energy_per_layer()[0].second / latency_per_layer() * CLOCK_RATE;
            float memory_power = energy_per_layer()[1].second / latency_per_layer() * CLOCK_RATE;
            float leakage_power = POWER_LEAKAGE;
            float total_power = compute_power + memory_power + leakage_power;

            res.push_back({"compute", compute_power});
            res.push_back({"memory", memory_power});
            res.push_back({"leakage", leakage_power});
            res.push_back({"total", total_power});

            return res;
        }

        float operational_intensity()
        {
            return macs_per_layer() / dram_access_per_layer()[6].second;
        }

        int peak_performance()
        {
            return 48;
        }

        int peak_bandwidth()
        {
            return hardware_param.bus_bw;
        }

        string bound_by()
        {
            float machine_blance_point = peak_performance() / peak_bandwidth();
            if(operational_intensity() > machine_blance_point)
                return "compute";
            else if (operational_intensity() < machine_blance_point)
                return "memory";
            else 
                return "balanced";
        }

        bool is_compute_bound()
        {
            return bound_by() == "compute";
        }

        bool is_memory_bound()
        {
            return bound_by() == "memory";
        }

        bool is_balanced()
        {
            return bound_by() == "balanced";
        }

        AnalysisResult summary()
        {
            AnalysisResult result;
            result.glb_usage = glb_usage_per_pass()[3].second;
            result.glb_access = glb_access_per_layer()[5].second;
            result.dram_access = dram_access_per_layer()[6].second;
            result.macs = macs_per_layer();
            result.latency = latency_per_layer();

            result.glb_read = glb_access_per_layer()[3].second;
            result.glb_write = glb_access_per_layer()[4].second;
            result.dram_read = dram_access_per_layer()[4].second;
            result.dram_write = dram_access_per_layer()[5].second;
            result.energy_total = energy_per_layer()[3].second;
            result.power_total = power_per_layer()[3].second;
            result.intensity = operational_intensity();
            result.peak_performance = peak_performance();
            result.peak_bandwidth = peak_bandwidth();

            return result;
        }

};


