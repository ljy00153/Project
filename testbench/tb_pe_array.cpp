#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

using namespace std;

struct index
{
    int count_if_col;
    int count_if_row;
    int count_weight_col;
    int count_weight_row;
    int count_of_col;
    int count_of_row;
};

void load_data();
