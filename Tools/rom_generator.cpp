#include <iostream>
#include <fstream>
#include <cmath>
#include <iomanip>
#include <vector>
#include <cstdint>
#include <string>
#include <algorithm>
#include <array>
#include <limits>
#include <queue>

using namespace std;

static const double PI                     = acos(-1.0);
static const int    N_STAGES               = 6;
static const int    FRAC_BITS              = 8;   // Q8.8
static const int    MAX_CSD                = 4;
static const int    MAX_SHIFT              = 15;
static const int    BIT_WIDTH              = 16;
static const int    EXT_WIDTH              = BIT_WIDTH + FRAC_BITS;      // 24
static const int    TOP_SIGMA_CANDIDATES   = 12;
static const int    BASIS_AMPLITUDE_Q88    = 1 << FRAC_BITS;             // 1.0 in Q8.8 = 256
static const array<int, N_STAGES> SHIFTS   = {0, 3, 6, 9, 12, 15};

struct ScaleTerm {
    bool valid;
    bool is_neg;
    int  shift;   // RTL scale section uses (x6_e <<< shift)
};

struct SignedShift {
    bool is_neg;
    int  shift;
};

struct BasisState {
    int x_e1;
    int y_e1;
    int x_e2;
    int y_e2;
};

struct SigmaPreCandidate {
    array<int, N_STAGES> sigma{};
    BasisState basis{};
    double fit_gain       = 0.0;
    double fit_error      = numeric_limits<double>::infinity();
    double angle_residual = 0.0;
    double Kinv_math      = 0.0;
};

struct FinalCandidate {
    array<int, N_STAGES> sigma{};
    BasisState basis{};
    vector<ScaleTerm> cmds;
    double fit_gain        = 0.0;
    double scale_recon     = 0.0;
    double fit_error       = numeric_limits<double>::infinity();
    double final_error     = numeric_limits<double>::infinity();
    double angle_residual  = 0.0;
    double Kinv_math       = 0.0;
};

struct HeapWorseFirst {
    bool operator()(const SigmaPreCandidate& a, const SigmaPreCandidate& b) const {
        return a.fit_error < b.fit_error; // max-heap on fit_error
    }
};

static inline int64_t wrap_signed(int64_t x, int bits) {
    const int64_t mod  = (bits == 63) ? 0 : (1LL << bits);
    const int64_t mask = mod - 1;
    int64_t u = x & mask;
    if (u >= (1LL << (bits - 1))) u -= mod;
    return u;
}

static inline int64_t arshift_signed(int64_t x, int s) {
    if (s <= 0) return x;
    if (x >= 0) return x >> s;
    const int64_t mag = -x;
    return -((mag + ((1LL << s) - 1)) >> s); // floor toward -inf
}

static inline int wrap16(int64_t x) { return (int)wrap_signed(x, 16); }
static inline int wrap24(int64_t x) { return (int)wrap_signed(x, 24); }
static inline int wrap25(int64_t x) { return (int)wrap_signed(x, 25); }
static inline int wrap26(int64_t x) { return (int)wrap_signed(x, 26); }

static int reduce_quadrant(double theta, double& alpha) {
    int k = static_cast<int>(round(theta / (PI / 2.0)));
    alpha = theta - k * (PI / 2.0);
    k = ((k % 4) + 4) % 4;
    return k;
}

static double compute_Kinv_math(const array<int, N_STAGES>& sigma) {
    double K = 1.0;
    for (int n = 0; n < N_STAGES; ++n) {
        double s = static_cast<double>(sigma[n]);
        K *= sqrt(1.0 + s * s * pow(8.0, -2.0 * n));
    }
    return 1.0 / K;
}

static double compute_angle_residual(double alpha, const array<int, N_STAGES>& sigma) {
    double rem = alpha;
    for (int n = 0; n < N_STAGES; ++n) {
        rem -= atan(static_cast<double>(sigma[n]) * pow(8.0, -(double)n));
    }
    return rem;
}

static inline pair<int,int> simulate_micro_stage(int x, int y, int sigma, int shift_amount) {
    int shifted_r   = (int)arshift_signed(x, shift_amount);
    int shifted_i   = (int)arshift_signed(y, shift_amount);
    int sigma_mul_i = wrap16((int64_t)shifted_i * sigma);
    int sigma_mul_r = wrap16((int64_t)shifted_r * sigma);
    int o_r         = wrap16((int64_t)x - sigma_mul_i);
    int o_i         = wrap16((int64_t)y + sigma_mul_r);
    return {o_r, o_i};
}

static BasisState simulate_unscaled_basis(const array<int, N_STAGES>& sigma) {
    BasisState st{BASIS_AMPLITUDE_Q88, 0, 0, BASIS_AMPLITUDE_Q88};
    for (int n = 0; n < N_STAGES; ++n) {
        auto e1 = simulate_micro_stage(st.x_e1, st.y_e1, sigma[n], SHIFTS[n]);
        auto e2 = simulate_micro_stage(st.x_e2, st.y_e2, sigma[n], SHIFTS[n]);
        st.x_e1 = e1.first; st.y_e1 = e1.second;
        st.x_e2 = e2.first; st.y_e2 = e2.second;
    }
    return st;
}

static inline double sqr(double x) { return x * x; }

static double continuous_fit_error_and_gain(double alpha, const BasisState& basis, double& best_gain) {
    const double tx_e1 =  cos(alpha) * BASIS_AMPLITUDE_Q88;
    const double ty_e1 =  sin(alpha) * BASIS_AMPLITUDE_Q88;
    const double tx_e2 = -sin(alpha) * BASIS_AMPLITUDE_Q88;
    const double ty_e2 =  cos(alpha) * BASIS_AMPLITUDE_Q88;

    const double mx_e1 = (double)basis.x_e1;
    const double my_e1 = (double)basis.y_e1;
    const double mx_e2 = (double)basis.x_e2;
    const double my_e2 = (double)basis.y_e2;

    const double numer = mx_e1 * tx_e1 + my_e1 * ty_e1 + mx_e2 * tx_e2 + my_e2 * ty_e2;
    const double denom = mx_e1 * mx_e1 + my_e1 * my_e1 + mx_e2 * mx_e2 + my_e2 * my_e2;

    best_gain = (denom > 0.0) ? max(0.0, numer / denom) : 0.0;

    return sqr(best_gain * mx_e1 - tx_e1)
         + sqr(best_gain * my_e1 - ty_e1)
         + sqr(best_gain * mx_e2 - tx_e2)
         + sqr(best_gain * my_e2 - ty_e2);
}

static priority_queue<SigmaPreCandidate, vector<SigmaPreCandidate>, HeapWorseFirst>
find_top_sigma_candidates(double alpha) {
    priority_queue<SigmaPreCandidate, vector<SigmaPreCandidate>, HeapWorseFirst> heap;

    for (int s0 = -4; s0 <= 4; ++s0)
    for (int s1 = -4; s1 <= 4; ++s1)
    for (int s2 = -4; s2 <= 4; ++s2)
    for (int s3 = -4; s3 <= 4; ++s3)
    for (int s4 = -4; s4 <= 4; ++s4)
    for (int s5 = -4; s5 <= 4; ++s5) {
        SigmaPreCandidate cand;
        cand.sigma = {s0, s1, s2, s3, s4, s5};
        cand.basis = simulate_unscaled_basis(cand.sigma);
        cand.fit_error = continuous_fit_error_and_gain(alpha, cand.basis, cand.fit_gain);
        cand.angle_residual = compute_angle_residual(alpha, cand.sigma);
        cand.Kinv_math = compute_Kinv_math(cand.sigma);

        if ((int)heap.size() < TOP_SIGMA_CANDIDATES) {
            heap.push(cand);
        } else {
            const auto& worst = heap.top();
            bool better = false;
            constexpr double EPS = 1e-18;
            if (cand.fit_error + EPS < worst.fit_error) {
                better = true;
            } else if (fabs(cand.fit_error - worst.fit_error) <= EPS) {
                int cur_l1 = 0, worst_l1 = 0, cur_linf = 0, worst_linf = 0;
                for (int i = 0; i < N_STAGES; ++i) {
                    cur_l1   += abs(cand.sigma[i]);
                    worst_l1 += abs(worst.sigma[i]);
                    cur_linf  = max(cur_linf, abs(cand.sigma[i]));
                    worst_linf= max(worst_linf, abs(worst.sigma[i]));
                }
                if (cur_l1 < worst_l1 || (cur_l1 == worst_l1 && cur_linf < worst_linf)) {
                    better = true;
                }
            }
            if (better) {
                heap.pop();
                heap.push(cand);
            }
        }
    }

    return heap;
}

static vector<vector<ScaleTerm>> build_scale_term_pool() {
    vector<SignedShift> pool;
    pool.reserve(2 * (MAX_SHIFT + 1));
    for (int sh = 0; sh <= MAX_SHIFT; ++sh) {
        pool.push_back({false, sh});
        pool.push_back({true,  sh});
    }

    vector<vector<ScaleTerm>> combos;
    combos.reserve(45000);

    auto push_combo = [&](const vector<SignedShift>& ss) {
        vector<ScaleTerm> ts;
        ts.reserve(MAX_CSD);
        for (const auto& x : ss) ts.push_back({true, x.is_neg, x.shift});
        sort(ts.begin(), ts.end(), [](const ScaleTerm& a, const ScaleTerm& b) {
            if (a.shift != b.shift) return a.shift > b.shift;
            return (int)a.is_neg < (int)b.is_neg;
        });
        while ((int)ts.size() < MAX_CSD) ts.push_back({false, false, 0});
        combos.push_back(ts);
    };

    // 0 term
    push_combo({});

    // 1 term
    for (size_t i = 0; i < pool.size(); ++i) {
        push_combo({pool[i]});
    }

    // 2 terms
    for (size_t i = 0; i < pool.size(); ++i)
    for (size_t j = i + 1; j < pool.size(); ++j) {
        if (pool[i].shift == pool[j].shift && pool[i].is_neg != pool[j].is_neg) continue;
        push_combo({pool[i], pool[j]});
    }

    // 3 terms
    for (size_t i = 0; i < pool.size(); ++i)
    for (size_t j = i + 1; j < pool.size(); ++j)
    for (size_t k = j + 1; k < pool.size(); ++k) {
        push_combo({pool[i], pool[j], pool[k]});
    }

    // 4 terms
    for (size_t i = 0; i < pool.size(); ++i)
    for (size_t j = i + 1; j < pool.size(); ++j)
    for (size_t k = j + 1; k < pool.size(); ++k)
    for (size_t m = k + 1; m < pool.size(); ++m) {
        push_combo({pool[i], pool[j], pool[k], pool[m]});
    }

    return combos;
}

static int apply_scale_exact_one(int x6r, const vector<ScaleTerm>& cmds) {
    int x6_e = x6r; // sign-extended 16 -> 24 does not change numeric value

    int tx[4] = {0,0,0,0};
    for (int i = 0; i < MAX_CSD; ++i) {
        if (!cmds[i].valid) {
            tx[i] = 0;
        } else {
            int t = wrap24((int64_t)x6_e << cmds[i].shift);
            if (cmds[i].is_neg) t = wrap24(-(int64_t)t);
            tx[i] = t;
        }
    }

    int px01 = wrap25((int64_t)tx[0] + tx[1]);
    int px23 = wrap25((int64_t)tx[2] + tx[3]);
    int full = wrap26((int64_t)px01 + px23);
    int out  = wrap16(arshift_signed(full, FRAC_BITS));
    return out;
}

static double evaluate_exact_matrix_error(double alpha, const BasisState& basis, const vector<ScaleTerm>& cmds) {
    const double tx_e1 =  cos(alpha) * BASIS_AMPLITUDE_Q88;
    const double ty_e1 =  sin(alpha) * BASIS_AMPLITUDE_Q88;
    const double tx_e2 = -sin(alpha) * BASIS_AMPLITUDE_Q88;
    const double ty_e2 =  cos(alpha) * BASIS_AMPLITUDE_Q88;

    int sx_e1 = apply_scale_exact_one(basis.x_e1, cmds);
    int sy_e1 = apply_scale_exact_one(basis.y_e1, cmds);
    int sx_e2 = apply_scale_exact_one(basis.x_e2, cmds);
    int sy_e2 = apply_scale_exact_one(basis.y_e2, cmds);

    return sqr((double)sx_e1 - tx_e1)
         + sqr((double)sy_e1 - ty_e1)
         + sqr((double)sx_e2 - tx_e2)
         + sqr((double)sy_e2 - ty_e2);
}

static double reconstruct_scale(const vector<ScaleTerm>& cmds) {
    double v = 0.0;
    for (const auto& t : cmds) {
        if (!t.valid) continue;
        double c = ldexp(1.0, t.shift - FRAC_BITS); // 2^(shift-FRAC_BITS)
        v += t.is_neg ? -c : c;
    }
    return v;
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

static FinalCandidate find_best_candidate_hwaware(double alpha, const vector<vector<ScaleTerm>>& scale_pool) {
    auto heap = find_top_sigma_candidates(alpha);
    vector<SigmaPreCandidate> tops;
    while (!heap.empty()) {
        tops.push_back(heap.top());
        heap.pop();
    }
    sort(tops.begin(), tops.end(), [](const SigmaPreCandidate& a, const SigmaPreCandidate& b) {
        if (a.fit_error != b.fit_error) return a.fit_error < b.fit_error;
        int a_l1 = 0, b_l1 = 0;
        int a_linf = 0, b_linf = 0;
        for (int i = 0; i < N_STAGES; ++i) {
            a_l1 += abs(a.sigma[i]); b_l1 += abs(b.sigma[i]);
            a_linf = max(a_linf, abs(a.sigma[i]));
            b_linf = max(b_linf, abs(b.sigma[i]));
        }
        if (a_l1 != b_l1) return a_l1 < b_l1;
        return a_linf < b_linf;
    });

    FinalCandidate best;
    constexpr double EPS = 1e-18;

    for (const auto& cand : tops) {
        double best_err_for_sigma = numeric_limits<double>::infinity();
        vector<ScaleTerm> best_cmds;
        double best_recon = 0.0;

        for (const auto& cmds : scale_pool) {
            double err = evaluate_exact_matrix_error(alpha, cand.basis, cmds);
            if (err + EPS < best_err_for_sigma) {
                best_err_for_sigma = err;
                best_cmds = cmds;
                best_recon = reconstruct_scale(cmds);
            } else if (fabs(err - best_err_for_sigma) <= EPS) {
                int cur_terms = 0, old_terms = 0;
                for (auto& t : cmds) if (t.valid) ++cur_terms;
                for (auto& t : best_cmds) if (t.valid) ++old_terms;
                if (best_cmds.empty() || cur_terms < old_terms) {
                    best_cmds = cmds;
                    best_recon = reconstruct_scale(cmds);
                }
            }
        }

        if (best_err_for_sigma + EPS < best.final_error) {
            best.sigma         = cand.sigma;
            best.basis         = cand.basis;
            best.cmds          = best_cmds;
            best.fit_gain      = cand.fit_gain;
            best.scale_recon   = best_recon;
            best.fit_error     = cand.fit_error;
            best.final_error   = best_err_for_sigma;
            best.angle_residual= cand.angle_residual;
            best.Kinv_math     = cand.Kinv_math;
        } else if (fabs(best_err_for_sigma - best.final_error) <= EPS) {
            int cur_l1 = 0, best_l1 = 0;
            for (int i = 0; i < N_STAGES; ++i) {
                cur_l1 += abs(cand.sigma[i]);
                best_l1 += abs(best.sigma[i]);
            }
            if (cur_l1 < best_l1) {
                best.sigma         = cand.sigma;
                best.basis         = cand.basis;
                best.cmds          = best_cmds;
                best.fit_gain      = cand.fit_gain;
                best.scale_recon   = best_recon;
                best.fit_error     = cand.fit_error;
                best.final_error   = best_err_for_sigma;
                best.angle_residual= cand.angle_residual;
                best.Kinv_math     = cand.Kinv_math;
            }
        }
    }

    return best;
}

int main() {
    struct StageInfo { int stage_id; int N_s; };
    const StageInfo stages[] = {{2, 128}, {4, 32}, {6, 8}};
    const int p_values[] = {2, 1, 3};

    const double q88_lsb = ldexp(1.0, -FRAC_BITS);
    double max_scale_err_vs_fit  = 0.0;
    double max_scale_err_vs_math = 0.0;
    double max_angle_resid       = 0.0;
    double max_matrix_err        = 0.0;

    auto scale_pool = build_scale_term_pool();

    ofstream rom_out("rom_hw.txt");
    if (!rom_out.is_open()) {
        std::cerr << "ERROR: cannot open rom_hwaware.txt for writing\n";
        return 1;
    }

    for (const auto& st : stages) {
        const int stage       = st.stage_id;
        const int N_s         = st.N_s;
        const int num_entries = N_s / 4;

        for (int path_idx = 0; path_idx < 3; ++path_idx) {
            int path_no = path_idx + 1;
            int p       = p_values[path_idx];

            rom_out << "|============[ ROM Stage "
                    << stage
                    << ", path "
                    << path_no
                    << ", p = "
                    << p
                    << " ]============|"
                    << "\n";

            for (int idx = 0; idx < num_entries; ++idx) {
                double theta = -(2.0 * PI * (double)p * (double)idx) / (double)N_s;
                double alpha = 0.0;
                int quad = reduce_quadrant(theta, alpha);

                FinalCandidate best = find_best_candidate_hwaware(alpha, scale_pool);

                uint32_t spk  = pack_sigma(best.sigma);
                uint32_t pcmd = pack_cmds(best.cmds);
                double scale_err_fit  = fabs(best.fit_gain  - best.scale_recon);
                double scale_err_math = fabs(best.Kinv_math - best.scale_recon);

                max_scale_err_vs_fit  = max(max_scale_err_vs_fit,  scale_err_fit);
                max_scale_err_vs_math = max(max_scale_err_vs_math, scale_err_math);
                max_angle_resid       = max(max_angle_resid, fabs(best.angle_residual));
                max_matrix_err        = max(max_matrix_err, best.final_error);

                rom_out << "[" << idx << "] = "
                        << "{2'd" << quad
                        << ", 24'h" << hex << uppercase << setw(6) << setfill('0') << spk
                        << ", 24'h" << setw(6) << pcmd << "}"
                        << dec
                        << " // th=" << fixed << setprecision(5) << theta
                        << " a=" << alpha
                        << " Ki=" << setprecision(6) << best.Kinv_math
                        << " fit=" << best.fit_gain
                        << " rc=" << best.scale_recon
                        << " seF=" << scientific << setprecision(2) << scale_err_fit
                        << "(" << fixed << setprecision(2) << (scale_err_fit / q88_lsb) << "L)"
                        << " seK=" << scientific << setprecision(2) << scale_err_math
                        << "(" << fixed << setprecision(2) << (scale_err_math / q88_lsb) << "L)"
                        << " ae=" << scientific << setprecision(2) << fabs(best.angle_residual)
                        << " me=" << scientific << setprecision(2) << best.final_error
                        << " sig={";
                for (int n = 0; n < N_STAGES; ++n) {
                    rom_out << best.sigma[n];
                    if (n != N_STAGES - 1) rom_out << ',';
                }
                rom_out << "}\n";
            }

            rom_out << "\n";
        }
    }

    rom_out.close();

    std::cerr << "ROM data written to rom_hw.txt\n";

    std::cerr << "\n===============================================\n"
         << "  Accuracy Report (hardware-aware generator)\n"
         << "===============================================\n"
         << "  Sigma brute-force space   = 9^6 exact\n"
         << "  Top sigma refined         = " << TOP_SIGMA_CANDIDATES << "\n"
         << "  Scale term search         = exact <=4 signed powers-of-two\n"
         << "  Probe basis amplitude     = 1.0 Q8.8 (256)\n"
         << "  Q8.8 LSB                  = " << fixed << setprecision(6) << q88_lsb << "\n"
         << "  Max scale err vs fit gain = " << scientific << setprecision(3) << max_scale_err_vs_fit
         << "  (" << fixed << setprecision(2) << (max_scale_err_vs_fit / q88_lsb) << " LSBs)\n"
         << "  Max scale err vs math K   = " << scientific << setprecision(3) << max_scale_err_vs_math
         << "  (" << fixed << setprecision(2) << (max_scale_err_vs_math / q88_lsb) << " LSBs)\n"
         << "  Max angle residual        = " << scientific << setprecision(3) << max_angle_resid << " rad\n"
         << "  Max exact matrix error    = " << scientific << setprecision(3) << max_matrix_err << "\n"
         << "===============================================\n";

    return 0;
}