#include <iostream>
#include <cmath>
#include <iomanip>
#include <vector>
#include <cstdint>
#include <string>

using namespace std;

// ----------------------------------------------------------------
// Cấu hình hệ thống
// ----------------------------------------------------------------
static const double PI        = acos(-1.0);
static const int    N_STAGES  = 6;    
static const int    FRAC_BITS = 30;   
static const int    MAX_CSD_TERMS = 4;

// ----------------------------------------------------------------
// Cấu trúc
// ----------------------------------------------------------------
struct ScaleTerm {
    bool valid;
    bool is_neg; 
    int  shift;  
};

// ----------------------------------------------------------------
// Hàm CORDIC (đã sửa theo phiên bản bạn đưa)
// ----------------------------------------------------------------
static int reduce_quadrant(double theta, double& alpha) {
    theta = fmod(theta, 2.0 * PI);
    if (theta < 0.0) theta += 2.0 * PI;

    double shifted_theta = theta + (PI / 4.0);
    int k = static_cast<int>(floor(shifted_theta / (PI / 2.0)));
    k = k % 4;                    // ← SỬA THEO BẠN

    alpha = theta - k * (PI / 2.0);
    return k;
}

static vector<int> compute_sigma(double alpha) {
    vector<int> sigma(N_STAGES, 0);
    double rem = alpha;
    for (int n = 0; n < N_STAGES; ++n) {
        const double r_n = pow(8.0, -static_cast<double>(n));
        double sf = tan(rem) / r_n;
        int s = static_cast<int>(round(sf));
        s = max(-4, min(4, s));
        sigma[n] = s;
        rem -= atan(static_cast<double>(s) * r_n);
    }
    return sigma;
}

static double compute_Kinv(const vector<int>& sigma) {
    double K = 1.0;
    for (int n = 0; n < N_STAGES; ++n) {
        const double s2 = static_cast<double>(sigma[n]) * static_cast<double>(sigma[n]);
        K *= sqrt(1.0 + s2 * pow(8.0, -2.0 * n));
    }
    return 1.0 / K;
}

static vector<ScaleTerm> get_csd_commands(double val) {
    int64_t fixed = static_cast<int64_t>(round(val * static_cast<double>(1LL << FRAC_BITS)));
    if (fixed < 0) fixed = 0;
    if (fixed > INT32_MAX) fixed = INT32_MAX;

    int64_t n = fixed;
    int bit = 0;
    vector<ScaleTerm> all_terms;

    while (n != 0 && bit < 32) {
        if (n & 1) {
            int d = 2 - static_cast<int>(n & 3);
            if (d == 1)
                all_terms.push_back({true, false, bit});   // ← shift = bit (theo bạn)
            else
                all_terms.push_back({true, true,  bit});
            n -= d;
        }
        n >>= 1;
        ++bit;
    }

    vector<ScaleTerm> selected_terms;
    selected_terms.reserve(MAX_CSD_TERMS);
    for (int i = (int)all_terms.size() - 1; i >= 0 && (int)selected_terms.size() < MAX_CSD_TERMS; --i) {
        selected_terms.push_back(all_terms[i]);
    }
    while ((int)selected_terms.size() < MAX_CSD_TERMS) {
        selected_terms.push_back({false, false, 0});
    }
    return selected_terms;
}

static uint32_t pack_sigma(const vector<int>& sigma) {
    uint32_t packed = 0;
    for (int n = 0; n < N_STAGES; ++n)
        packed |= static_cast<uint32_t>(sigma[n] & 0xF) << (4 * (N_STAGES - 1 - n));
    return packed;
}

// ----------------------------------------------------------------
// Main: Sinh ROM cho Stage 2, 4, 6
// ----------------------------------------------------------------
int main() {
    struct StageInfo {
        int stage_id;
        int N_s;
    };

    StageInfo stages[] = {{2, 128}, {4, 32}, {6, 8}};
    int paths[] = {2, 1, 3};

    for (auto& st : stages) {
        int stage = st.stage_id;
        int N_s   = st.N_s;
        int num_n3 = N_s / 4;

        int addr_bits = 0;
        if (num_n3 > 0) {
            int t = num_n3 - 1;
            while (t > 0) { addr_bits++; t >>= 1; }
        }
        if (addr_bits == 0) addr_bits = 1;
        string addr_prefix = to_string(addr_bits) + "'d";

        for (int p : paths) {
            cout << "--------------------------------------------------\n";
            cout << "// ROM Stage " << stage << " - Path p=" << p 
                 << " (N_s=" << N_s << ", " << num_n3 << " entries)\n";
            cout << "always @(*) begin\n";
            cout << "    case (n3)\n";

            for (int n3 = 0; n3 < num_n3; ++n3) {
                // FFT forward twiddle: W_N^(k*n) = exp(-j*2*pi*k*n/N)
                double theta = -(2.0 * PI * p * n3) / static_cast<double>(N_s);

                double alpha;
                int    quad  = reduce_quadrant(theta, alpha);
                auto   sigma = compute_sigma(alpha);
                double Kinv  = compute_Kinv(sigma);
                auto   cmds  = get_csd_commands(Kinv);

                uint32_t packed_cmds = 0;
                for (int i = 0; i < 4; ++i) {
                    uint32_t v = cmds[i].valid ? 1 : 0;
                    uint32_t s = cmds[i].is_neg ? 1 : 0;
                    uint32_t sh = cmds[i].shift & 0x1F;
                    uint32_t term_7b = (v << 6) | (s << 5) | sh;
                    packed_cmds |= (term_7b << (i * 7));
                }

                uint32_t spk = pack_sigma(sigma);

                cout << "        " << addr_prefix << dec << n3 
                     << ": {quad, sigma, scale_cmds} = {2'd" << quad 
                     << ", 24'h" << hex << uppercase << setw(6) << setfill('0') << spk 
                     << ", 28'h" << setw(7) << packed_cmds << "};"
                     << " // theta=" << fixed << setprecision(6) << theta 
                     << " rad, Kinv≈" << Kinv << "\n";
            }

            cout << "        default: {quad, sigma, scale_cmds} = 54'h0;\n";
            cout << "    endcase\n";
            cout << "end\n\n";
        }
    }
    return 0;
}