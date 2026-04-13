// ================================================================
//  genrom_radix8_csd4.cpp
//  Sinh ROM twiddle factor cho FFT Radix-8 CORDIC
//  Datapath: Q8.8  |  CSD: 4 terms  |  CORDIC: 6 stage radix-8
//
//  Entry format: {quad[1:0], sigma[23:0], scale_cmds[23:0]} = 50 bit
//
//    quad      : 2 bit – góc phần tư
//                0 → (cos, sin),  1 → (-sin, cos)
//                2 → (-cos,-sin), 3 → (sin, -cos)
//
//    sigma     : 24 bit – 6×4 bit signed nibble, stage0 tại MSB
//
//    scale_cmds: 24 bit – 4 CSD term × 6 bit
//                term_i = {valid[5], neg[4], shift[3:0]}
//                term0 tại LSB [5:0], term3 tại [23:18]
//                hardware: acc += neg ? -(x>>>shift) : (x>>>shift)
//
//  Verilog decode template ở đầu output file
//
//  FIX so với bản cũ:
//    1. reduce_quadrant dùng round() thay floor() → đúng cho góc âm nhỏ
//    2. FRAC_BITS=8 (Q8.8) thay vì 30 → shift đúng với datapath
//    3. In dec thay hex cho N_s, entries trong comment
//
//  Compile:  g++ -O2 -o genrom genrom_radix8_csd4.cpp
//  Run:      ./genrom > rom_out.v
// ================================================================

#include <iostream>
#include <cmath>
#include <iomanip>
#include <vector>
#include <cstdint>
#include <string>

using namespace std;

static const double PI        = acos(-1.0);
static const int    N_STAGES  = 6;
static const int    FRAC_BITS = 8;   // Q8.8
static const int    MAX_CSD   = 4;

struct ScaleTerm {
    bool valid;
    bool is_neg;
    int  shift;  // right-shift trên Q8.8 word (0..15)
};

static int reduce_quadrant(double theta, double& alpha) {
    int k = static_cast<int>(round(theta / (PI / 2.0)));
    alpha = theta - k * (PI / 2.0);   // alpha ∈ [-π/4, π/4]
    k = ((k % 4) + 4) % 4;            // normalize 0..3
    return k;
}

// ----------------------------------------------------------------
// Radix-8 CORDIC: tính sigma[n] ∈ [-4,4]
// rotation unit n: arctan(sigma_n * 8^-n)
// ----------------------------------------------------------------
static vector<int> compute_sigma(double alpha) {
    vector<int> sigma(N_STAGES, 0);
    double rem = alpha;
    for (int n = 0; n < N_STAGES; ++n) {
        double r_n = pow(8.0, -(double)n);
        int s = static_cast<int>(round(tan(rem) / r_n));
        s = max(-4, min(4, s));
        sigma[n] = s;
        rem -= atan(static_cast<double>(s) * r_n);
    }
    return sigma;
}

// ----------------------------------------------------------------
// K^-1 = 1 / ∏_n sqrt(1 + σ_n² * 8^(-2n))
// ----------------------------------------------------------------
static double compute_Kinv(const vector<int>& sigma) {
    double K = 1.0;
    for (int n = 0; n < N_STAGES; ++n) {
        double s = static_cast<double>(sigma[n]);
        K *= sqrt(1.0 + s * s * pow(8.0, -2.0 * n));
    }
    return 1.0 / K;
}

// ----------------------------------------------------------------
// CSD decompose Kinv, normalized về Q8.8
// fixed = round(val * 2^8)  → CSD trên integer 16-bit
// shift = bit position từ LSB → hardware: (x >>> shift)
// ----------------------------------------------------------------
static vector<ScaleTerm> get_csd_commands(double val) {
    int64_t fixed = static_cast<int64_t>(round(val * (double)(1 << FRAC_BITS)));
    if (fixed < 0)      fixed = 0;
    if (fixed > 0xFFFF) fixed = 0xFFFF;

    int64_t n = fixed;
    int bit = 0;
    vector<ScaleTerm> all_terms;

    while (n != 0 && bit < 16) {
        if (n & 1) {
            int d = 2 - static_cast<int>(n & 3);  // +1 or -1
            all_terms.push_back({true, (d < 0), bit});
            n -= d;
        }
        n >>= 1;
        ++bit;
    }

    // Lấy MAX_CSD term significance cao nhất
    vector<ScaleTerm> selected;
    selected.reserve(MAX_CSD);
    for (int i = (int)all_terms.size() - 1;
         i >= 0 && (int)selected.size() < MAX_CSD; --i)
        selected.push_back(all_terms[i]);

    while ((int)selected.size() < MAX_CSD)
        selected.push_back({false, false, 0});

    return selected;
}

// ----------------------------------------------------------------
// Pack helpers
// ----------------------------------------------------------------
static uint32_t pack_sigma(const vector<int>& sigma) {
    uint32_t p = 0;
    for (int n = 0; n < N_STAGES; ++n)
        p |= static_cast<uint32_t>(sigma[n] & 0xF) << (4 * (N_STAGES - 1 - n));
    return p;
}

static uint32_t pack_cmds(const vector<ScaleTerm>& cmds) {
    uint32_t p = 0;
    for (int i = 0; i < MAX_CSD; ++i) {
        uint32_t term = ((cmds[i].valid  ? 1u : 0u) << 5)
                      | ((cmds[i].is_neg ? 1u : 0u) << 4)
                      | (static_cast<uint32_t>(cmds[i].shift) & 0xFu);
        p |= (term << (i * 6));
    }
    return p;
}

// ----------------------------------------------------------------
// Reconstruct Kinv từ CSD terms (verify)
// shift=k trong Q8.8 → real contribution = ±2^(k - FRAC_BITS)
// ----------------------------------------------------------------
static double reconstruct_csd(const vector<ScaleTerm>& cmds) {
    double v = 0.0;
    for (const auto& t : cmds)
        if (t.valid)
            v += (t.is_neg ? -1.0 : 1.0) * pow(2.0, (double)(t.shift - FRAC_BITS));
    return v;
}

static double residual_angle(double alpha, const vector<int>& sigma) {
    double rem = alpha;
    for (int n = 0; n < N_STAGES; ++n)
        rem -= atan(static_cast<double>(sigma[n]) * pow(8.0, -(double)n));
    return rem;
}

// ================================================================
// Main
// ================================================================
int main() {
    // --- Verilog decode template ---
    cout << "// ============================================================\n"
         << "// AUTO-GENERATED: Radix-8 CORDIC ROM  Q8.8  4-CSD  6-stage\n"
         << "// Entry 50 bit: {quad[1:0], sigma[23:0], scale_cmds[23:0]}\n"
         << "// ============================================================\n"
         << "//\n"
         << "// --- Verilog decode template ---\n"
         << "// wire [1:0]  quad       = data_o[49:48];\n"
         << "// wire [23:0] sigma      = data_o[47:24];\n"
         << "// wire [23:0] sc         = data_o[23:0];\n"
         << "//\n";
    for (int i = 0; i < MAX_CSD; ++i) {
        int hi = i*6 + 5, lo = i*6;
        cout << "// wire        v" << i << " = sc[" << hi << "]; "
             << "wire n" << i << " = sc[" << hi-1 << "]; "
             << "wire [3:0] s" << i << " = sc[" << hi-2 << ":" << lo << "];\n";
    }
    cout << "// wire signed [15:0] x; // CORDIC output Q8.8\n"
         << "// wire signed [15:0] t0 = v0 ? (n0 ? -(x>>>s0) : x>>>s0) : 0;\n"
         << "// wire signed [15:0] t1 = v1 ? (n1 ? -(x>>>s1) : x>>>s1) : 0;\n"
         << "// wire signed [15:0] t2 = v2 ? (n2 ? -(x>>>s2) : x>>>s2) : 0;\n"
         << "// wire signed [15:0] t3 = v3 ? (n3 ? -(x>>>s3) : x>>>s3) : 0;\n"
         << "// wire signed [15:0] acc = t0+t1+t2+t3; // = Kinv*x in Q8.8\n"
         << "//\n\n";

    // --- Stage / path ---
    struct StageInfo { int stage_id; int N_s; };
    const StageInfo stages[] = {{2, 128}, {4, 32}, {6, 8}};
    const int paths[] = {2, 1, 3};

    double max_kerr = 0.0, max_aerr = 0.0;
    const double q88_lsb = pow(2.0, -(double)FRAC_BITS);

    for (const auto& st : stages) {
        const int stage       = st.stage_id;
        const int N_s         = st.N_s;
        const int num_entries = N_s / 4;

        int addr_bits = 1;
        { int t = num_entries - 1; while (t > 1) { addr_bits++; t >>= 1; } }

        for (int p : paths) {
            cout << "// Stage=" << dec << stage
                 << " p=" << p
                 << " N_s=" << N_s
                 << " entries=" << num_entries
                 << " addr=" << addr_bits << "bit\n";
            cout << "always @(*) begin\n"
                 << "    case (addr)\n";

            for (int idx = 0; idx < num_entries; ++idx) {
                double theta = -(2.0 * PI * (double)p * (double)idx) / (double)N_s;

                double alpha;
                int    quad  = reduce_quadrant(theta, alpha);
                auto   sigma = compute_sigma(alpha);
                double Kinv  = compute_Kinv(sigma);
                auto   cmds  = get_csd_commands(Kinv);

                uint32_t spk   = pack_sigma(sigma);
                uint32_t pcmd  = pack_cmds(cmds);
                double   recon = reconstruct_csd(cmds);
                double   kerr  = fabs(Kinv - recon);
                double   aerr  = fabs(residual_angle(alpha, sigma));

                if (kerr > max_kerr) max_kerr = kerr;
                if (aerr > max_aerr) max_aerr = aerr;

                cout << "        " << dec << addr_bits << "'d" << idx
                     << ": data_o = {2'd" << quad
                     << ", 24'h" << hex << uppercase << setw(6) << setfill('0') << spk
                     << ", 24'h" << setw(6) << pcmd << "};"
                     << dec   // reset decimal cho comment
                     << " // th=" << fixed << setprecision(5) << theta
                     << " Ki=" << setprecision(4) << Kinv
                     << " rc=" << recon
                     << " ke=" << scientific << setprecision(1) << kerr
                     << "(" << fixed << setprecision(2) << (kerr/q88_lsb) << "L)"
                     << " ae=" << scientific << setprecision(1) << aerr << "\n";
            }

            cout << "        default: data_o = 50'h0;\n"
                 << "    endcase\n"
                 << "end // Stage" << dec << stage << "_p" << p << "\n\n";
        }
    }

    // --- Accuracy summary to stderr ---
    cerr << "\n========================================\n"
         << "  Accuracy Report  (Q8.8 datapath)\n"
         << "========================================\n"
         << "  Q8.8 LSB             = " << fixed << setprecision(6) << q88_lsb << "\n"
         << "  Max Kinv CSD error   = " << scientific << setprecision(3) << max_kerr
         << "  (" << fixed << setprecision(2) << (max_kerr/q88_lsb) << " LSBs)\n"
         << "  Max CORDIC angle err = " << scientific << setprecision(3) << max_aerr << " rad\n"
         << "  CSD error < 1 LSB?   " << (max_kerr < q88_lsb ? "YES ✓" : "NO – tăng MAX_CSD") << "\n"
         << "========================================\n";

    return 0;
}