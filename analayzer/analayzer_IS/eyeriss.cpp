#pragma once
#include "../Eyeriss_base.hpp"


class EyerissAnalyzer_IS : public EyerissAnalyzer_base
{
    public:
        vector<pair<string, long long int>> glb_access_per_layer()
        {
            vector<pair<string, long long int>> res;

            long long int M_div_mode = ceil(double(mapping.M) / double(mapping.mode));
            long long int B_div_M = ceil(double(linear_shape.B) / double(mapping.M));
            long long int in_f_div_K = ceil(double(linear_shape.in_features) / double(mapping.K * 3 * 4));
            long long int out_f_div_N = ceil(double(linear_shape.out_features) / double(mapping.N * 4));
            long long int K_div_tk = ceil(double(mapping.K) / double(mapping.tk));
            long long int N_div_tn = ceil(double(mapping.N) / double(mapping.tn));

            long long int num_o_linear_read= ceil(double(linear_shape.in_features) / double(mapping.K * 3) - 1);

            res.push_back({"i_linear_read", out_f_div_N * in_f_div_K * B_div_M * M_div_mode * K_div_tk * mapping.mode * mapping.tk * 12});
            res.push_back({"weight_linear_read", out_f_div_N * in_f_div_K * B_div_M * M_div_mode * K_div_tk * N_div_tn * mapping.tk * mapping.tn * 48});
            res.push_back({"o_linear_read", num_o_linear_read * out_f_div_N * B_div_M * M_div_mode * N_div_tn * K_div_tk * mapping.mode * mapping.tn * 16}); 
            res.push_back({"o_linear_write", in_f_div_K * out_f_div_N * B_div_M * M_div_mode * N_div_tn * K_div_tk * mapping.mode * mapping.tn * 16});
            res.push_back({"read", res[0].second + res[1].second+ res[2].second});
            res.push_back({"write", res[3].second});
            res.push_back({"total", res[4].second + res[5].second});//6
            return res;
        }
};


