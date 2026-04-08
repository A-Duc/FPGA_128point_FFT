#include <iostream>
#include <cmath>
#include <iomanip>
#include <vector>
#include <cstdint>
#include <utility>
#include <algorithm>

using namespace std;

// ----------------------------------------------------------------
// Cấu hình hệ thống
// ----------------------------------------------------------------
static const double PI        = acos(-1.0);
static const int    N_STAGES  = 6;    
static const int    FRAC_BITS = 30;   
static const int    MAX_CSD_TERMS = 4; // Tối ưu: 4 lệnh dịch bit

struct ScaleTerm {
    bool valid;
    bool is_neg; 
    int  shift;  
};

// ----------------------------------------------------------------
// Các hàm tính toán CORDIC
// ----------------------------------------------------------------
static int reduce_quadrant(double theta, double& alpha) {
    // 1. Đưa theta về khoảng [0, 2*PI)
    theta = fmod(theta, 2.0 * PI);
    if (theta < 0.0) theta += 2.0 * PI;

    // 2. Dịch trục đi PI/4 để gán góc vào trục tọa độ gần nhất (0, PI/2, PI, 3PI/2)
    double shifted_theta = theta + (PI / 4.0);
    int k = static_cast<int>(floor(shifted_theta / (PI / 2.0)));
    k = k % 4; // Đảm bảo k luôn thuộc {0, 1, 2, 3}

    // 3. Tính góc dư alpha (lúc này alpha sẽ luôn nằm an toàn trong khoảng [-PI/4, PI/4])
    alpha = theta - k * (PI / 2.0);

    return k;
}

static vector<int> compute_sigma(double alpha) {
    vector<int> sigma(N_STAGES, 0);
    double rem = alpha;
    for (int n = 0; n < N_STAGES; ++n) {
        const double r_n = pow(8.0, -static_cast<double>(n)); 
        double sf = tan(rem) / r_n;
        int    s  = static_cast<int>(round(sf));
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
    if (fixed < 0)         fixed = 0;
    if (fixed > INT32_MAX) fixed = INT32_MAX;
    
    int64_t  n   = fixed;
    int      bit = 0;
    vector<ScaleTerm> all_terms;
    
    while (n != 0 && bit < 32) {
        if (n & 1) {                                           
            int d = 2 - static_cast<int>(n & 3);
            if (d == 1)  all_terms.push_back({true, false, bit});
            else         all_terms.push_back({true, true, bit});
            n -= d; 
        }
        n >>= 1;
        ++bit;
    }
    
    vector<ScaleTerm> selected_terms;
    for (int i = (int)all_terms.size() - 1; i >= 0; --i) {
        if (selected_terms.size() < MAX_CSD_TERMS) {
            selected_terms.push_back(all_terms[i]);
        }
    }
    while (selected_terms.size() < MAX_CSD_TERMS) {
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
// Main: Sinh mã Verilog ROM
// ----------------------------------------------------------------
int main() {
    // In phần đầu Case
    cout << "// Verilog ROM Table for Stage 2 - Path 3 (p=3)\n";
    cout << "always @(*) begin\n";
    cout << "    case (n3)\n";

    for (int n3 = 0; n3 < 32; ++n3) {
        // Tính toán cho p = 2
        int p = 3; 
        double theta = static_cast<double>(p * n3) * PI / 64.0;
        
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

        // In dòng Verilog chuẩn
        cout << "            5'd" << dec << setfill('0') << setw(2) << n3 
             << ": {quad, sigma, scale_cmds} = {2'd" << quad 
             << ", 24'h" << hex << uppercase << setw(6) << setfill('0') << spk 
             << ", 28'h" << setw(7) << packed_cmds << "};"
             << " // Angle: " << fixed << setprecision(4) << theta << " rad\n";
    }

    // In phần cuối Case
    cout << "            default: {quad, sigma, scale_cmds} = 54'h0;\n";
    cout << "    endcase\n";
    cout << "end\n";

    return 0;
}