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
#include <set>
#include <functional>

using namespace std;

static const double PI = acos(-1.0);

static const int N_STAGES = 6;
static const int MAX_CSD  = 4;
static const int MAX_SHIFT = 15;

static const int OUT_WIDTH  = 16;
static const int OUT_FRAC   = 8;
static const int GUARD_BITS = 4;

static const int CORDIC_WIDTH = OUT_WIDTH + GUARD_BITS;
static const int CORDIC_FRAC  = OUT_FRAC  + GUARD_BITS;

static const int SCALE_FRAC  = OUT_FRAC;
static const int FINAL_SHIFT = SCALE_FRAC + GUARD_BITS;

static const int MICRO_EXT_WIDTH = CORDIC_WIDTH + 3;
static const int TERM_WIDTH      = CORDIC_WIDTH + MAX_SHIFT + 3;
static const int PAIR_WIDTH      = TERM_WIDTH + 1;
static const int FULL_WIDTH      = TERM_WIDTH + 2;

static const int TOP_SIGMA_CANDIDATES = 32;

static const int BASIS_AMPLITUDE_OUT      = 1 << OUT_FRAC;
static const int BASIS_AMPLITUDE_INTERNAL = 1 << CORDIC_FRAC;

static const array<int, N_STAGES> SHIFTS = {0, 3, 6, 9, 12, 15};

struct ScaleTerm {
    bool valid;
    bool is_neg;
    int  shift;
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
        return a.fit_error < b.fit_error;
    }
};

static inline double sqr(double x) {
    return x * x;
}

static inline int64_t wrap_signed(int64_t x, int bits) {
    const int64_t mod  = 1LL << bits;
    const int64_t mask = mod - 1;
    int64_t u = x & mask;
    if (u >= (1LL << (bits - 1))) u -= mod;
    return u;
}

static inline int64_t arshift_signed(int64_t x, int s) {
    if (s <= 0) return x;
    if (x >= 0) return x >> s;

    const int64_t mag = -x;
    return -((mag + ((1LL << s) - 1)) >> s);
}

static inline int wrap_out(int64_t x) {
    return (int)wrap_signed(x, OUT_WIDTH);
}

static inline int wrap_cordic(int64_t x) {
    return (int)wrap_signed(x, CORDIC_WIDTH);
}

static inline int64_t wrap_micro_ext(int64_t x) {
    return wrap_signed(x, MICRO_EXT_WIDTH);
}

static inline int64_t wrap_term(int64_t x) {
    return wrap_signed(x, TERM_WIDTH);
}

static inline int64_t wrap_pair(int64_t x) {
    return wrap_signed(x, PAIR_WIDTH);
}

static inline int64_t wrap_full(int64_t x) {
    return wrap_signed(x, FULL_WIDTH);
}

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

static inline int64_t sigma_mul_ext(int value_ext, int sigma) {
    int64_t v = value_ext;

    switch (sigma) {
        case -4:
            return wrap_micro_ext(-wrap_micro_ext(v << 2));

        case -3:
            return wrap_micro_ext(-wrap_micro_ext(wrap_micro_ext(v << 1) + v));

        case -2:
            return wrap_micro_ext(-wrap_micro_ext(v << 1));

        case -1:
            return wrap_micro_ext(-v);

        case 0:
            return 0;

        case 1:
            return wrap_micro_ext(v);

        case 2:
            return wrap_micro_ext(v << 1);

        case 3:
            return wrap_micro_ext(wrap_micro_ext(v << 1) + v);

        case 4:
            return wrap_micro_ext(v << 2);

        default:
            return 0;
    }
}

static inline pair<int,int> simulate_micro_stage(int x, int y, int sigma, int shift_amount) {
    int shifted_r = wrap_cordic(arshift_signed(x, shift_amount));
    int shifted_i = wrap_cordic(arshift_signed(y, shift_amount));

    int shifted_r_ext = (int)wrap_micro_ext(shifted_r);
    int shifted_i_ext = (int)wrap_micro_ext(shifted_i);

    int data_r_ext = (int)wrap_micro_ext(x);
    int data_i_ext = (int)wrap_micro_ext(y);

    int64_t sigma_mul_i = sigma_mul_ext(shifted_i_ext, sigma);
    int64_t sigma_mul_r = sigma_mul_ext(shifted_r_ext, sigma);

    int64_t next_r_ext = wrap_micro_ext((int64_t)data_r_ext - sigma_mul_i);
    int64_t next_i_ext = wrap_micro_ext((int64_t)data_i_ext + sigma_mul_r);

    int o_r = wrap_cordic(next_r_ext);
    int o_i = wrap_cordic(next_i_ext);

    return {o_r, o_i};
}

static BasisState simulate_unscaled_basis(const array<int, N_STAGES>& sigma) {
    BasisState st{BASIS_AMPLITUDE_INTERNAL, 0, 0, BASIS_AMPLITUDE_INTERNAL};

    for (int n = 0; n < N_STAGES; ++n) {
        auto e1 = simulate_micro_stage(st.x_e1, st.y_e1, sigma[n], SHIFTS[n]);
        auto e2 = simulate_micro_stage(st.x_e2, st.y_e2, sigma[n], SHIFTS[n]);

        st.x_e1 = e1.first;
        st.y_e1 = e1.second;
        st.x_e2 = e2.first;
        st.y_e2 = e2.second;
    }

    return st;
}

static double continuous_fit_error_and_gain(double alpha, const BasisState& basis, double& best_gain) {
    const double target_amp = (double)BASIS_AMPLITUDE_INTERNAL;

    const double tx_e1 =  cos(alpha) * target_amp;
    const double ty_e1 =  sin(alpha) * target_amp;
    const double tx_e2 = -sin(alpha) * target_amp;
    const double ty_e2 =  cos(alpha) * target_amp;

    const double mx_e1 = (double)basis.x_e1;
    const double my_e1 = (double)basis.y_e1;
    const double mx_e2 = (double)basis.x_e2;
    const double my_e2 = (double)basis.y_e2;

    const double numer = mx_e1 * tx_e1
                       + my_e1 * ty_e1
                       + mx_e2 * tx_e2
                       + my_e2 * ty_e2;

    const double denom = mx_e1 * mx_e1
                       + my_e1 * my_e1
                       + mx_e2 * mx_e2
                       + my_e2 * my_e2;

    best_gain = (denom > 0.0) ? max(0.0, numer / denom) : 0.0;

    return sqr(best_gain * mx_e1 - tx_e1)
         + sqr(best_gain * my_e1 - ty_e1)
         + sqr(best_gain * mx_e2 - tx_e2)
         + sqr(best_gain * my_e2 - ty_e2);
}

static int sigma_l1(const array<int, N_STAGES>& sigma) {
    int v = 0;
    for (int s : sigma) {
        v += abs(s);
    }
    return v;
}

static int sigma_linf(const array<int, N_STAGES>& sigma) {
    int v = 0;
    for (int s : sigma) {
        v = max(v, abs(s));
    }
    return v;
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
                int cur_l1 = sigma_l1(cand.sigma);
                int worst_l1 = sigma_l1(worst.sigma);

                int cur_linf = sigma_linf(cand.sigma);
                int worst_linf = sigma_linf(worst.sigma);

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

static string scale_key_from_terms(const vector<ScaleTerm>& ts) {
    string key;

    for (const auto& t : ts) {
        key += t.valid ? '1' : '0';
        key += t.is_neg ? 'n' : 'p';
        key += to_string(t.shift);
        key += ';';
    }

    return key;
}

static vector<vector<ScaleTerm>> build_scale_term_pool() {
    vector<vector<ScaleTerm>> combos;
    set<string> seen;

    vector<SignedShift> selected;

    auto push_combo = [&]() {
        vector<ScaleTerm> ts;
        ts.reserve(MAX_CSD);

        for (const auto& x : selected) {
            ts.push_back({true, x.is_neg, x.shift});
        }

        sort(ts.begin(), ts.end(), [](const ScaleTerm& a, const ScaleTerm& b) {
            if (a.shift != b.shift) return a.shift > b.shift;
            return (int)a.is_neg < (int)b.is_neg;
        });

        while ((int)ts.size() < MAX_CSD) {
            ts.push_back({false, false, 0});
        }

        string key = scale_key_from_terms(ts);
        if (seen.insert(key).second) {
            combos.push_back(ts);
        }
    };

    function<void(int,int)> dfs = [&](int shift, int used) {
        if (used > MAX_CSD) {
            return;
        }

        if (shift > MAX_SHIFT) {
            push_combo();
            return;
        }

        dfs(shift + 1, used);

        if (used < MAX_CSD) {
            selected.push_back({false, shift});
            dfs(shift + 1, used + 1);
            selected.pop_back();

            selected.push_back({true, shift});
            dfs(shift + 1, used + 1);
            selected.pop_back();
        }
    };

    dfs(0, 0);

    return combos;
}

static int apply_scale_exact_one(int x6r, const vector<ScaleTerm>& cmds) {
    int64_t x6_e = wrap_term(x6r);

    int64_t tx[4] = {0, 0, 0, 0};

    for (int i = 0; i < MAX_CSD; ++i) {
        if (!cmds[i].valid) {
            tx[i] = 0;
        } else {
            int64_t t = wrap_term(x6_e << cmds[i].shift);

            if (cmds[i].is_neg) {
                t = wrap_term(-t);
            }

            tx[i] = t;
        }
    }

    int64_t px01 = wrap_pair(tx[0] + tx[1]);
    int64_t px23 = wrap_pair(tx[2] + tx[3]);
    int64_t full = wrap_full(px01 + px23);

    const int64_t round_bias_pos = 1LL << (FINAL_SHIFT - 1);
    const int64_t round_bias_neg = (1LL << (FINAL_SHIFT - 1)) - 1;

    int64_t full_round = wrap_full(full + (full < 0 ? round_bias_neg : round_bias_pos));
    int64_t scaled = arshift_signed(full_round, FINAL_SHIFT);

    return wrap_out(scaled);
}

static double evaluate_exact_matrix_error(double alpha,
                                          const BasisState& basis,
                                          const vector<ScaleTerm>& cmds) {
    const double target_amp = (double)BASIS_AMPLITUDE_OUT;

    const double tx_e1 =  cos(alpha) * target_amp;
    const double ty_e1 =  sin(alpha) * target_amp;
    const double tx_e2 = -sin(alpha) * target_amp;
    const double ty_e2 =  cos(alpha) * target_amp;

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
        if (!t.valid) {
            continue;
        }

        double c = ldexp(1.0, t.shift - SCALE_FRAC);
        v += t.is_neg ? -c : c;
    }

    return v;
}

static uint32_t pack_sigma(const array<int, N_STAGES>& sigma) {
    uint32_t p = 0;

    for (int n = 0; n < N_STAGES; ++n) {
        p |= static_cast<uint32_t>(sigma[n] & 0xF) << (4 * (N_STAGES - 1 - n));
    }

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

static int count_terms(const vector<ScaleTerm>& cmds) {
    int n = 0;

    for (const auto& t : cmds) {
        if (t.valid) {
            ++n;
        }
    }

    return n;
}

static bool better_final_tie(const FinalCandidate& cur, const FinalCandidate& best) {
    int cur_terms  = count_terms(cur.cmds);
    int best_terms = count_terms(best.cmds);

    if (cur_terms != best_terms) {
        return cur_terms < best_terms;
    }

    int cur_l1  = sigma_l1(cur.sigma);
    int best_l1 = sigma_l1(best.sigma);

    if (cur_l1 != best_l1) {
        return cur_l1 < best_l1;
    }

    int cur_linf  = sigma_linf(cur.sigma);
    int best_linf = sigma_linf(best.sigma);

    return cur_linf < best_linf;
}

static FinalCandidate find_best_candidate_hwaware(double alpha,
                                                  const vector<vector<ScaleTerm>>& scale_pool) {
    auto heap = find_top_sigma_candidates(alpha);

    vector<SigmaPreCandidate> tops;
    while (!heap.empty()) {
        tops.push_back(heap.top());
        heap.pop();
    }

    sort(tops.begin(), tops.end(), [](const SigmaPreCandidate& a, const SigmaPreCandidate& b) {
        if (a.fit_error != b.fit_error) {
            return a.fit_error < b.fit_error;
        }

        int a_l1 = sigma_l1(a.sigma);
        int b_l1 = sigma_l1(b.sigma);

        if (a_l1 != b_l1) {
            return a_l1 < b_l1;
        }

        int a_linf = sigma_linf(a.sigma);
        int b_linf = sigma_linf(b.sigma);

        return a_linf < b_linf;
    });

    FinalCandidate best;
    constexpr double EPS = 1e-18;

    for (const auto& cand : tops) {
        FinalCandidate cur;

        cur.sigma          = cand.sigma;
        cur.basis          = cand.basis;
        cur.fit_gain       = cand.fit_gain;
        cur.fit_error      = cand.fit_error;
        cur.angle_residual = cand.angle_residual;
        cur.Kinv_math      = cand.Kinv_math;

        for (const auto& cmds : scale_pool) {
            double err = evaluate_exact_matrix_error(alpha, cand.basis, cmds);
            double recon = reconstruct_scale(cmds);

            bool take = false;

            if (err + EPS < cur.final_error) {
                take = true;
            } else if (fabs(err - cur.final_error) <= EPS) {
                if (cur.cmds.empty() || count_terms(cmds) < count_terms(cur.cmds)) {
                    take = true;
                }
            }

            if (take) {
                cur.final_error = err;
                cur.cmds = cmds;
                cur.scale_recon = recon;
            }
        }

        if (cur.final_error + EPS < best.final_error) {
            best = cur;
        } else if (fabs(cur.final_error - best.final_error) <= EPS) {
            if (best.cmds.empty() || better_final_tie(cur, best)) {
                best = cur;
            }
        }
    }

    return best;
}

int main() {
    struct StageInfo {
        int stage_id;
        int N_s;
    };

    const StageInfo stages[] = {{2, 128}, {4, 32}, {6, 8}};
    const int p_values[] = {2, 1, 3};

    const double q88_lsb = ldexp(1.0, -OUT_FRAC);

    double max_scale_err_vs_fit  = 0.0;
    double max_scale_err_vs_math = 0.0;
    double max_angle_resid       = 0.0;
    double max_matrix_err        = 0.0;

    vector<vector<ScaleTerm>> scale_pool = build_scale_term_pool();

    ofstream rom_out("rom_hw.txt");
    if (!rom_out.is_open()) {
        cerr << "ERROR: cannot open rom_hw.txt for writing\n";
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
                        << dec << setfill(' ')
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
                        << " terms=" << count_terms(best.cmds)
                        << " sig={";

                for (int n = 0; n < N_STAGES; ++n) {
                    rom_out << best.sigma[n];

                    if (n != N_STAGES - 1) {
                        rom_out << ',';
                    }
                }

                rom_out << "}\n";
            }

            rom_out << "\n";
        }
    }

    rom_out.close();

    cerr << "ROM data written to rom_hw.txt\n";

    cerr << "\n===============================================\n"
         << "  Accuracy Report (hardware-aware generator)\n"
         << "===============================================\n"
         << "  Model                      = CORDIC_v2 internal Q8.12, output Q8.8\n"
         << "  Sigma brute-force space    = 9^6 exact\n"
         << "  Top sigma refined          = " << TOP_SIGMA_CANDIDATES << "\n"
         << "  Scale term search          = exact <=4 signed powers-of-two\n"
         << "  Scale pool size            = " << scale_pool.size() << "\n"
         << "  Output width/frac          = " << OUT_WIDTH << " / " << OUT_FRAC << "\n"
         << "  CORDIC width/frac          = " << CORDIC_WIDTH << " / " << CORDIC_FRAC << "\n"
         << "  Guard bits                 = " << GUARD_BITS << "\n"
         << "  Final shift                = " << FINAL_SHIFT << "\n"
         << "  Probe basis internal       = 1.0 Q8.12 (" << BASIS_AMPLITUDE_INTERNAL << ")\n"
         << "  Output Q8.8 LSB            = " << fixed << setprecision(6) << q88_lsb << "\n"
         << "  Max scale err vs fit gain  = " << scientific << setprecision(3) << max_scale_err_vs_fit
         << "  (" << fixed << setprecision(2) << (max_scale_err_vs_fit / q88_lsb) << " LSBs)\n"
         << "  Max scale err vs math K    = " << scientific << setprecision(3) << max_scale_err_vs_math
         << "  (" << fixed << setprecision(2) << (max_scale_err_vs_math / q88_lsb) << " LSBs)\n"
         << "  Max angle residual         = " << scientific << setprecision(3) << max_angle_resid << " rad\n"
         << "  Max exact matrix error     = " << scientific << setprecision(3) << max_matrix_err << "\n"
         << "===============================================\n";

    return 0;
}