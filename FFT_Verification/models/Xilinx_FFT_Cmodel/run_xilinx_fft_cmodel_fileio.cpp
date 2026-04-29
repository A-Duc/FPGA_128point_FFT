#include "xfft_v9_1_bitacc_cmodel.h"

#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <string>
#include <cstdlib>
#include <iomanip>

using namespace std;

static string basename_no_ext(const string &path) {
    size_t slash_pos = path.find_last_of("/\\");
    string name = (slash_pos == string::npos) ? path : path.substr(slash_pos + 1);

    size_t dot_pos = name.find_last_of('.');
    if (dot_pos != string::npos) {
        name = name.substr(0, dot_pos);
    }

    return name;
}

static string make_output_path_from_input(const string &input_path) {
    string stem = basename_no_ext(input_path);

    const string prefix = "input_";
    string desc;

    if (stem.compare(0, prefix.size(), prefix) == 0) {
        desc = stem.substr(prefix.size());
    } else {
        desc = stem;
    }

    return "../../output_results/xilinx_cmodel_fft/output_" + desc + "_xilinx_cmodel.txt";
}

static bool read_complex_input_file(
    const string &input_path,
    vector<double> &re,
    vector<double> &im,
    int expected_samples
) {
    ifstream fin(input_path.c_str());

    if (!fin) {
        cerr << "ERROR: cannot open input file: " << input_path << endl;
        return false;
    }

    re.clear();
    im.clear();

    string line;
    int line_no = 0;

    while (getline(fin, line)) {
        line_no++;

        size_t first_non_space = line.find_first_not_of(" \t\r\n");

        if (first_non_space == string::npos) {
            continue;
        }

        if (line[first_non_space] == '#') {
            continue;
        }

        stringstream ss(line);
        double real_value;
        double imag_value;

        if (!(ss >> real_value >> imag_value)) {
            cerr << "ERROR: invalid line " << line_no << " in " << input_path << endl;
            cerr << "Line content: " << line << endl;
            return false;
        }

        if (real_value < -1.0 || real_value >= 1.0 ||
            imag_value < -1.0 || imag_value >= 1.0) {
            cerr << "ERROR: Xilinx fixed-point C model input must be in range [-1.0, 1.0)." << endl;
            cerr << "Line " << line_no << ": re=" << real_value
                 << ", im=" << imag_value << endl;
            return false;
        }

        re.push_back(real_value);
        im.push_back(imag_value);
    }

    if ((int)re.size() != expected_samples) {
        cerr << "ERROR: input sample count mismatch." << endl;
        cerr << "Expected: " << expected_samples << endl;
        cerr << "Actual  : " << re.size() << endl;
        return false;
    }

    return true;
}

static bool write_complex_output_file(
    const string &output_path,
    const vector<double> &re,
    const vector<double> &im
) {
    ofstream fout(output_path.c_str());

    if (!fout) {
        cerr << "ERROR: cannot open output file: " << output_path << endl;
        return false;
    }

    fout << "# k re_decimal im_decimal\n";
    fout << fixed << setprecision(12);

    for (size_t k = 0; k < re.size(); k++) {
        fout << k << " " << re[k] << " " << im[k] << "\n";
    }

    return true;
}

int main(int argc, char **argv) {
    if (argc != 2 && argc != 3) {
        cerr << "Usage:\n";
        cerr << "  ./run_xilinx_fft_cmodel_fileio <input_file>\n";
        cerr << "  ./run_xilinx_fft_cmodel_fileio <input_file> <output_file>\n";
        cerr << "\nExample:\n";
        cerr << "  ./run_xilinx_fft_cmodel_fileio ../../input_vectors/xilinx_cmodel_fft/input_dummy_check_script.txt\n";
        return 1;
    }

    const string input_path = argv[1];
    const string output_path = (argc == 3) ? argv[2] : make_output_path_from_input(input_path);

    /*
        Configuration matched as closely as possible to the user's FFT IP requirement:

        N = 128
        fixed-point
        16-bit input
        16-bit phase/twiddle
        pipelined streaming architecture
        SSR = 4
        unscaled
        truncation
    */

    const int C_NFFT_MAX        = 7;
    const int C_ARCH            = 3;
    const int C_USE_FLT_PT      = 0;
    const int C_HAS_NFFT        = 0;
    const int C_INPUT_WIDTH     = 16;
    const int C_TWIDDLE_WIDTH   = 16;
    const int C_HAS_SCALING     = 0;
    const int C_HAS_BFP         = 0;
    const int C_HAS_ROUNDING    = 0;
    const int C_NSSR            = 4;
    const int C_SYSTOLICFFT_INV = 0;

    const int samples = 1 << C_NFFT_MAX;

    vector<double> xn_re;
    vector<double> xn_im;

    if (!read_complex_input_file(input_path, xn_re, xn_im, samples)) {
        return 1;
    }

    xilinx_ip_xfft_v9_1_generics generics;

    generics.C_NFFT_MAX        = C_NFFT_MAX;
    generics.C_ARCH            = C_ARCH;
    generics.C_USE_FLT_PT      = C_USE_FLT_PT;
    generics.C_HAS_NFFT        = C_HAS_NFFT;
    generics.C_INPUT_WIDTH     = C_INPUT_WIDTH;
    generics.C_TWIDDLE_WIDTH   = C_TWIDDLE_WIDTH;
    generics.C_HAS_SCALING     = C_HAS_SCALING;
    generics.C_HAS_BFP         = C_HAS_BFP;
    generics.C_HAS_ROUNDING    = C_HAS_ROUNDING;
    generics.C_NSSR            = C_NSSR;
    generics.C_SYSTOLICFFT_INV = C_SYSTOLICFFT_INV;

    xilinx_ip_xfft_v9_1_state *state =
        xilinx_ip_xfft_v9_1_create_state(generics);

    if (state == NULL) {
        cerr << "ERROR: could not create FFT state object" << endl;
        return 1;
    }

    xilinx_ip_xfft_v9_1_inputs inputs;

    inputs.nfft = C_NFFT_MAX;

    inputs.xn_re = &xn_re[0];
    inputs.xn_re_size = samples;

    inputs.xn_im = &xn_im[0];
    inputs.xn_im_size = samples;

    /*
        For unscaled mode, scaling_sch is not used by the model in the same way as scaled mode.
        However, the input structure still needs a valid pointer and size.
    */

    const int scaling_sch_size =
        (C_ARCH == 1 || C_ARCH == 3) ? ((C_NFFT_MAX + 1) / 2) : C_NFFT_MAX;

    vector<int> scaling_sch(scaling_sch_size, 0);

    inputs.scaling_sch = &scaling_sch[0];
    inputs.scaling_sch_size = scaling_sch_size;

    inputs.direction = 1;

    vector<double> xk_re(samples, 0.0);
    vector<double> xk_im(samples, 0.0);

    xilinx_ip_xfft_v9_1_outputs outputs;

    outputs.xk_re = &xk_re[0];
    outputs.xk_re_size = samples;

    outputs.xk_im = &xk_im[0];
    outputs.xk_im_size = samples;

    cout << "Running Xilinx FFT C model..." << endl;
    cout << "Input : " << input_path << endl;
    cout << "Output: " << output_path << endl;
    cout << "N     : " << samples << endl;
    cout << "SSR   : " << C_NSSR << endl;
    cout << "Width : " << C_INPUT_WIDTH << " bits fixed-point" << endl;

    int status = xilinx_ip_xfft_v9_1_bitacc_simulate(state, inputs, &outputs);

    if (status != 0) {
        cerr << "ERROR: simulation did not complete successfully" << endl;
        xilinx_ip_xfft_v9_1_destroy_state(state);
        return 1;
    }

    if (outputs.xk_re_size != samples || outputs.xk_im_size != samples) {
        cerr << "ERROR: output sample count mismatch" << endl;
        cerr << "Expected   : " << samples << endl;
        cerr << "xk_re_size : " << outputs.xk_re_size << endl;
        cerr << "xk_im_size : " << outputs.xk_im_size << endl;
        xilinx_ip_xfft_v9_1_destroy_state(state);
        return 1;
    }

    if (!write_complex_output_file(output_path, xk_re, xk_im)) {
        xilinx_ip_xfft_v9_1_destroy_state(state);
        return 1;
    }

    xilinx_ip_xfft_v9_1_destroy_state(state);

    cout << "Simulation completed successfully" << endl;
    cout << "Xilinx C model output written to: " << output_path << endl;

    return 0;
}