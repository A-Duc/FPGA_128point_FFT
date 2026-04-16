#include <iostream>
#include <cmath>
#include <iomanip>
#include <vector>
#include <cstdint>
#include <string>
#include <algorithm>
#include <array>
#include <limits>

using namespace std;

static const double PI        = acos(-1.0);
static const int    N_STAGES  = 6;
static const int    FRAC_BITS = 8;   // Q8.8
static const int    MAX_CSD   = 4;
static const int    MAX_SHIFT = 15;

struct ScaleTerm {
    bool valid;
    bool is_neg;
    int  shift;   // RTL scale section uses (x6_e <<< shift)
};

struct Candidate {
    array<int, N_STAGES> sigma{};
    double angle_err_abs = numeric_limits<double>::infinity();
    double residual      = 0.0;
    double Kinv          = 0.0;
};

static int reduce_quadrant(double theta, double& alpha) {
    int k = static_cast<int>(round(theta / (PI / 2.0)));
    alpha = theta - k * (PI / 2.0);
    k = ((k % 4) + 4) % 4;
    return k;
}

static inline double coeff_value(bool is_neg, int shift) {
    double v = ldexp(1.0, shift - FRAC_BITS); // 2^(shift-FRAC_BITS)
    return is_neg ? -v : v;
}

static double compute_Kinv(const array<int, N_STAGES>& sigma) {
    double K = 1.0;
    for (int n = 0; n < N_STAGES; ++n) {
        double s = static_cast<double>(sigma[n]);
        K *= sqrt(1.0 + s * s * pow(8.0, -2.0 * n));
    }
    return 1.0 / K;
}

static Candidate find_best_sigma(double alpha) {
    // brute-force 9^6 = 531,441 sequences, still small for offline generation
    array<array<double, 9>, N_STAGES> angle_tbl{};
    for (int n = 0; n < N_STAGES; ++n) {
        double r_n = pow(8.0, -(double)n);
        for (int si = 0; si < 9; ++si) {
            int s = si - 4;
            angle_tbl[n][si] = atan((double)s * r_n);
        }
    }

    Candidate best;
    constexpr double EPS = 1e-18;

    for (int s0 = -4; s0 <= 4; ++s0)
    for (int s1 = -4; s1 <= 4; ++s1)
    for (int s2 = -4; s2 <= 4; ++s2)
    for (int s3 = -4; s3 <= 4; ++s3)
    for (int s4 = -4; s4 <= 4; ++s4)
    for (int s5 = -4; s5 <= 4; ++s5) {
        array<int, N_STAGES> sig = {s0, s1, s2, s3, s4, s5};
        double sum = angle_tbl[0][s0 + 4]
                   + angle_tbl[1][s1 + 4]
                   + angle_tbl[2][s2 + 4]
                   + angle_tbl[3][s3 + 4]
                   + angle_tbl[4][s4 + 4]
                   + angle_tbl[5][s5 + 4];
        double residual = alpha - sum;
        double err_abs  = fabs(residual);

        // Tie-breaks:
        // 1) smaller |residual|
        // 2) smaller sum(|sigma|) to prefer gentler sequence
        // 3) smaller max(|sigma|) for stability
        if (err_abs + EPS < best.angle_err_abs) {
            best.sigma = sig;
            best.angle_err_abs = err_abs;
            best.residual = residual;
        } else if (fabs(err_abs - best.angle_err_abs) <= EPS) {
            int cur_l1 = 0, best_l1 = 0, cur_linf = 0, best_linf = 0;
            for (int i = 0; i < N_STAGES; ++i) {
                cur_l1   += abs(sig[i]);
                best_l1  += abs(best.sigma[i]);
                cur_linf  = max(cur_linf, abs(sig[i]));
                best_linf = max(best_linf, abs(best.sigma[i]));
            }
            if (cur_l1 < best_l1 || (cur_l1 == best_l1 && cur_linf < best_linf)) {
                best.sigma = sig;
                best.angle_err_abs = err_abs;
                best.residual = residual;
            }
        }
    }

    best.Kinv = compute_Kinv(best.sigma);
    return best;
}

static vector<ScaleTerm> find_best_scale_terms(double target) {
    // exact search of best approximation using <= 4 signed powers of two
    // value(term) = ± 2^(shift-FRAC_BITS), shift in [0..15]
    struct SignedShift { bool is_neg; int shift; };
    vector<SignedShift> pool;
    pool.reserve(2 * (MAX_SHIFT + 1));
    for (int sh = 0; sh <= MAX_SHIFT; ++sh) {
        pool.push_back({false, sh});
        pool.push_back({true,  sh});
    }

    double best_err = numeric_limits<double>::infinity();
    vector<ScaleTerm> best_terms;

    auto try_terms = [&](const vector<ScaleTerm>& terms) {
        double acc = 0.0;
        for (const auto& t : terms) {
            if (t.valid) acc += coeff_value(t.is_neg, t.shift);
        }
        double err = fabs(target - acc);

        auto term_count = [](const vector<ScaleTerm>& ts) {
            int c = 0;
            for (auto& t : ts) if (t.valid) ++c;
            return c;
        };
        int cur_count  = term_count(terms);
        int best_count = term_count(best_terms);

        constexpr double EPS = 1e-18;
        if (err + EPS < best_err ||
            (fabs(err - best_err) <= EPS && (best_terms.empty() || cur_count < best_count))) {
            best_err = err;
            best_terms = terms;
        }
    };

    // 0 term
    try_terms({});

    // 1 term
    for (size_t i = 0; i < pool.size(); ++i) {
        vector<ScaleTerm> t1 = {{true, pool[i].is_neg, pool[i].shift}};
        try_terms(t1);
    }

    // 2 terms
    for (size_t i = 0; i < pool.size(); ++i)
    for (size_t j = i + 1; j < pool.size(); ++j) {
        if (pool[i].shift == pool[j].shift && pool[i].is_neg != pool[j].is_neg) continue; // cancel pair useless
        vector<ScaleTerm> t2 = {
            {true, pool[i].is_neg, pool[i].shift},
            {true, pool[j].is_neg, pool[j].shift}
        };
        try_terms(t2);
    }

    // 3 terms
    for (size_t i = 0; i < pool.size(); ++i)
    for (size_t j = i + 1; j < pool.size(); ++j)
    for (size_t k = j + 1; k < pool.size(); ++k) {
        vector<ScaleTerm> t3 = {
            {true, pool[i].is_neg, pool[i].shift},
            {true, pool[j].is_neg, pool[j].shift},
            {true, pool[k].is_neg, pool[k].shift}
        };
        try_terms(t3);
    }

    // 4 terms
    for (size_t i = 0; i < pool.size(); ++i)
    for (size_t j = i + 1; j < pool.size(); ++j)
    for (size_t k = j + 1; k < pool.size(); ++k)
    for (size_t m = k + 1; m < pool.size(); ++m) {
        vector<ScaleTerm> t4 = {
            {true, pool[i].is_neg, pool[i].shift},
            {true, pool[j].is_neg, pool[j].shift},
            {true, pool[k].is_neg, pool[k].shift},
            {true, pool[m].is_neg, pool[m].shift}
        };
        try_terms(t4);
    }

    // sort by significance descending for readability / deterministic packing
    sort(best_terms.begin(), best_terms.end(), [](const ScaleTerm& a, const ScaleTerm& b) {
        return a.shift > b.shift;
    });

    while ((int)best_terms.size() < MAX_CSD)
        best_terms.push_back({false, false, 0});

    return best_terms;
}

static uint32_t pack_sigma(const array<int, N_STAGES>& sigma) {
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

static double reconstruct_scale(const vector<ScaleTerm>& cmds) {
    double v = 0.0;
    for (const auto& t : cmds)
        if (t.valid)
            v += coeff_value(t.is_neg, t.shift);
    return v;
}

int main() {
    cout << "// ============================================================\n"
         << "// AUTO-GENERATED: Radix-8 CORDIC ROM (improved)\n"
         << "// Entry 50 bit: {quad[1:0], sigma[23:0], scale_cmds[23:0]}\n"
         << "// Improvements:\n"
         << "//   1) sigma search: exact brute-force over 9^6 sequences\n"
         << "//   2) scale search: exact best <=4 signed powers-of-two\n"
         << "//   3) decode comment fixed: scale uses (x <<< shift), not >>>\n"
         << "// ============================================================\n"
         << "//\n"
         << "// wire [1:0]  quad       = data_o[49:48];\n"
         << "// wire [23:0] sigma      = data_o[47:24];\n"
         << "// wire [23:0] sc         = data_o[23:0];\n";
    for (int i = 0; i < MAX_CSD; ++i) {
        int hi = i*6 + 5, lo = i*6;
        cout << "// wire        v" << i << " = sc[" << hi << "]; "
             << "wire n" << i << " = sc[" << hi-1 << "]; "
             << "wire [3:0] s" << i << " = sc[" << hi-2 << ":" << lo << "];\n";
    }
    cout << "// wire signed [15:0] x;\n"
         << "// wire signed [23:0] x_e = {{8{x[15]}}, x};\n"
         << "// wire signed [23:0] t0 = v0 ? (n0 ? -(x_e<<<s0) : (x_e<<<s0)) : 24'sd0;\n"
         << "// wire signed [23:0] t1 = v1 ? (n1 ? -(x_e<<<s1) : (x_e<<<s1)) : 24'sd0;\n"
         << "// wire signed [23:0] t2 = v2 ? (n2 ? -(x_e<<<s2) : (x_e<<<s2)) : 24'sd0;\n"
         << "// wire signed [23:0] t3 = v3 ? (n3 ? -(x_e<<<s3) : (x_e<<<s3)) : 24'sd0;\n"
         << "// final output = (t0+t1+t2+t3)[23:8]\n\n";

    struct StageInfo { int stage_id; int N_s; };
    const StageInfo stages[] = {{2, 128}, {4, 32}, {6, 8}};
    const int paths[] = {2, 1, 3};

    const double q88_lsb = ldexp(1.0, -FRAC_BITS);
    double max_kerr = 0.0, max_aerr = 0.0;

    for (const auto& st : stages) {
        const int stage       = st.stage_id;
        const int N_s         = st.N_s;
        const int num_entries = N_s / 4;

        int addr_bits = 1;
        for (int t = num_entries - 1; t > 1; t >>= 1) ++addr_bits;

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
                int quad = reduce_quadrant(theta, alpha);

                Candidate cand = find_best_sigma(alpha);
                auto cmds      = find_best_scale_terms(cand.Kinv);

                uint32_t spk   = pack_sigma(cand.sigma);
                uint32_t pcmd  = pack_cmds(cmds);
                double recon   = reconstruct_scale(cmds);
                double kerr    = fabs(cand.Kinv - recon);
                double aerr    = cand.angle_err_abs;

                max_kerr = max(max_kerr, kerr);
                max_aerr = max(max_aerr, aerr);

                cout << "        " << dec << addr_bits << "'d" << idx
                     << ": data_o = {2'd" << quad
                     << ", 24'h" << hex << uppercase << setw(6) << setfill('0') << spk
                     << ", 24'h" << setw(6) << pcmd << "};"
                     << dec
                     << " // th=" << fixed << setprecision(5) << theta
                     << " a=" << alpha
                     << " Ki=" << setprecision(6) << cand.Kinv
                     << " rc=" << recon
                     << " ke=" << scientific << setprecision(2) << kerr
                     << "(" << fixed << setprecision(2) << (kerr / q88_lsb) << "L)"
                     << " ae=" << scientific << setprecision(2) << aerr
                     << " sig={";
                for (int n = 0; n < N_STAGES; ++n) {
                    cout << cand.sigma[n];
                    if (n != N_STAGES - 1) cout << ',';
                }
                cout << "}\n";
            }

            cout << "        default: data_o = 50'h0;\n"
                 << "    endcase\n"
                 << "end // Stage" << dec << stage << "_p" << p << "\n\n";
        }
    }

    cerr << "\n========================================\n"
         << "  Accuracy Report  (Q8.8 datapath)\n"
         << "========================================\n"
         << "  Search sigma         = exact brute-force 9^6\n"
         << "  Search scale terms   = exact best <=4 signed powers-of-two\n"
         << "  Q8.8 LSB             = " << fixed << setprecision(6) << q88_lsb << "\n"
         << "  Max Kinv approx err  = " << scientific << setprecision(3) << max_kerr
         << "  (" << fixed << setprecision(2) << (max_kerr / q88_lsb) << " LSBs)\n"
         << "  Max angle residual   = " << scientific << setprecision(3) << max_aerr << " rad\n"
         << "  Scale err < 1 LSB?   = " << (max_kerr < q88_lsb ? "YES" : "NO") << "\n"
         << "========================================\n";

    return 0;
}
