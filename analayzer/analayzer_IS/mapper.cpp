#pragma once
#include "../Mapper_base.hpp"
#include "eyeriss.cpp"

class EyerissMapper_IS : public EyerissMapper_base
{
    public:
        void create_analyzer() override
        {
            analyzer = make_unique<EyerissAnalyzer_IS>();
        }

    void mapping_to_csv_no_cycle(AnalysisResult& results, 
                                const EyerissMappingParam mappings, const string& filename) override
    {
        results.name = "linear_IS";
        EyerissMapper_base::mapping_to_csv_no_cycle(results, mappings, filename);
    }

    void mapping_to_csv_with_cycle(const string& filename) override
    {
        best_result.name = "linear_IS";
        EyerissMapper_base::mapping_to_csv_with_cycle(filename);
    }
};


