"""
gen_sigma_rom.py
================
Generate ROM content for sigma_precompute block of radix-8 CORDIC,
used in radix-2^2 DIF FFT (Das et al., 2024).

HONESTY NOTE ABOUT delta COMPUTATION:
--------------------------------------
Paper Das et al. cites Ref [38] = Kuhlmann & Parhi, P-CORDIC (2002) for the
precomputation formula:
    sigma = b + 0.5c + eps0*sign(theta) + delta
    where delta = sum_{i=1}^{n/3} eps_i * d_i
    and   eps_i = 2^{-i} - arctan(2^{-i})

However, the exact bit-accurate ROM generation procedure is not fully
described in either paper at a level sufficient to reproduce exactly.
Specifically:
  - The exact encoding from 'greedy radix-8 sigma' to 'd_i' (binary digits)
    is not fully specified for radix-8 (papers describe radix-2 version clearly).
  - The exact ROM indexing scheme (how theta maps to ROM address) is not
    spelled out in detail.

APPROACH USED HERE (consistent and transparent):
  1. Divide [-pi/2, pi/2] into N = 2^ceil(m/3) = 64 equal-width bins.
  2. For each bin k, theta_ref_k = midpoint of bin.
  3. Run greedy radix-8 CORDIC angle selection on theta_ref_k to get
     sigma_i in {-4,...,4} for i = 0..num_stages-1.
  4. Compute epsilon_i = 2^{-i} - atan(2^{-i})  (standard P-CORDIC definition)
  5. Convert sigma_i to binary digit d_i via:
       d_i = (sigma_i + 4) / 8   mapped to {0,1} after normalization
     ACTUALLY: since sigma_i in {-4..4} is NOT binary {0,1}, we use
     the magnitude interpretation:
       eps_contribution_i = sigma_i * epsilon_i
       (this is the direct interpretation: delta absorbs the cumulative
        angle approximation error from the greedy selection)
  6. delta_k = sum_{i=1}^{num_stages-1} sigma_i * epsilon_i
     (i starts at 1 because i=0 term is handled separately by eps0*sign(theta))

This is the most direct consistent interpretation that:
  - Matches the spirit of P-CORDIC Eq. 10
  - Uses the actual greedy sigma values from radix-8 selection
  - Does not fabricate a bit-accurate match to an unpublished procedure

Fixed-point: signed Q2.14, 16-bit two's complement.
  Range: [-2.0, 2.0), resolution: 2^{-14} = ~6.1e-5
"""

import math
import sys

# ==============================================================
# PARAMETERS
# ==============================================================
M         = 16                       # precision bits
RADIX     = 8
NUM_STAGES = math.ceil(M / 3)        # = 6
N_ENTRIES  = 2 ** NUM_STAGES         # = 64
ANGLE_MIN  = -math.pi / 2
ANGLE_MAX  =  math.pi / 2

Q_FRAC_BITS = 14                     # Q2.14 format
Q_TOTAL_BITS = 16


# ==============================================================
# FIXED-POINT HELPERS
# ==============================================================
def to_q2_14(val):
    """
    Convert float to signed Q2.14 16-bit two's complement integer.
    Range: [-2.0, +2.0 - 2^{-14}]
    Clamps if out of range.
    Returns int in [-(2^15), 2^15 - 1].
    """
    scaled = val * (2 ** Q_FRAC_BITS)
    rounded = int(math.floor(scaled + 0.5))   # round half-up
    max_val =  (1 << (Q_TOTAL_BITS - 1)) - 1  # +32767
    min_val = -(1 << (Q_TOTAL_BITS - 1))      # -32768
    clamped = max(min_val, min(max_val, rounded))
    return clamped


def to_twos_complement_hex(signed_int, bits=16):
    """
    Convert signed int to two's complement unsigned int, then to hex string.
    E.g.: -1 -> 0xFFFF for 16-bit.
    Returns zero-padded hex string WITHOUT '0x' prefix, length = bits/4.
    """
    if signed_int < 0:
        unsigned = signed_int + (1 << bits)
    else:
        unsigned = signed_int
    hex_digits = bits // 4
    return f"{unsigned:0{hex_digits}X}"


# ==============================================================
# EPSILON COMPUTATION
# ==============================================================
def compute_epsilon(i):
    """
    epsilon_i = 2^{-i} - atan(2^{-i})
    Standard definition from P-CORDIC (Kuhlmann & Parhi, 2002), Table 1.
    epsilon_0 is handled separately in the main formula (eps0 * sign(theta)).
    delta uses epsilon_i for i >= 1.
    """
    return 2.0 ** (-i) - math.atan(2.0 ** (-i))


# ==============================================================
# GREEDY RADIX-8 SIGMA SELECTION
# ==============================================================
def greedy_radix8_sigma(theta_target, num_stages):
    """
    Greedy selection of sigma_i in {-4,-3,-2,-1,0,1,2,3,4} for radix-8 CORDIC.

    At each stage i:
      angle_step(sigma, i) = atan(sigma * 8^{-i})
      Choose sigma_i that minimizes |z_remaining - angle_step(sigma_i, i)|
      Then: z = z - angle_step(sigma_i, i)

    Returns:
      sigma_list : list of int, length num_stages
      z_final    : residual angle after all stages (approximation error)
    """
    SIGMA_RANGE = list(range(-4, 5))   # {-4, -3, -2, -1, 0, 1, 2, 3, 4}
    z = theta_target
    sigma_list = []

    for i in range(num_stages):
        best_sigma = 0
        best_residual = float('inf')

        for s in SIGMA_RANGE:
            # angle contributed by this micro-rotation
            angle_step = math.atan(s * (RADIX ** (-i)))
            residual = abs(z - angle_step)
            if residual < best_residual:
                best_residual = residual
                best_sigma = s

        chosen_angle = math.atan(best_sigma * (RADIX ** (-i)))
        z = z - chosen_angle
        sigma_list.append(best_sigma)

    return sigma_list, z


# ==============================================================
# DELTA COMPUTATION
# ==============================================================
def compute_delta(sigma_list):
    """
    delta = sum_{i=1}^{num_stages-1} sigma_i * epsilon_i

    Interpretation:
      Each epsilon_i = 2^{-i} - atan(2^{-i}) is the difference between
      the 'ideal binary step' and the actual arctan step at stage i.
      Multiplying by sigma_i gives the signed contribution of stage i
      to the cumulative angle approximation offset.
      The sum starting at i=1 (not i=0) because epsilon_0 is absorbed
      into the separate 'eps0 * sign(theta)' term in the main formula.

    This follows the P-CORDIC (Kuhlmann & Parhi) structure where:
      delta = sum_{i=1}^{n/3} d_i * epsilon_i
    but adapted for radix-8 sigma values (not binary d_i).
    """
    total = 0.0
    for i in range(1, len(sigma_list)):   # start at i=1
        eps_i = compute_epsilon(i)
        total += sigma_list[i] * eps_i
    return total


# ==============================================================
# MAIN ROM GENERATION
# ==============================================================
def generate_rom():
    """
    Generate all N_ENTRIES ROM entries.
    Each entry: (theta_ref_k, delta_k, delta_k_minus_1)
    All in Q2.14 signed fixed-point.
    """
    # Bin width
    bin_width = (ANGLE_MAX - ANGLE_MIN) / N_ENTRIES

    rom = []   # list of dicts

    for k in range(N_ENTRIES):
        theta_min_k = ANGLE_MIN + k * bin_width
        theta_max_k = ANGLE_MIN + (k + 1) * bin_width
        theta_ref_k = (theta_min_k + theta_max_k) / 2.0   # midpoint

        # Greedy sigma sequence for this theta_ref
        sigma_list, z_residual = greedy_radix8_sigma(theta_ref_k, NUM_STAGES)

        # Delta for this entry
        delta_k = compute_delta(sigma_list)

        rom.append({
            'k':           k,
            'theta_ref':   theta_ref_k,
            'delta':       delta_k,
            'sigma_list':  sigma_list,
            'z_residual':  z_residual,
        })

    # Add delta_{k-1}: entry k stores delta of entry k-1
    for k in range(N_ENTRIES):
        if k == 0:
            rom[k]['delta_km1'] = rom[k]['delta']   # no previous entry
        else:
            rom[k]['delta_km1'] = rom[k-1]['delta']

    return rom


# ==============================================================
# PRINT VERIFICATION TABLE
# ==============================================================
def print_verification(rom, n_samples=8):
    """Print a few sample entries for manual verification."""
    print("# ============================================================")
    print("# VERIFICATION SAMPLES")
    print("# Format: k | theta_ref | sigma_list | delta_k | delta_km1 | z_residual")
    print("# ============================================================")

    indices = [0, 1, 2, N_ENTRIES//4, N_ENTRIES//2, N_ENTRIES-3, N_ENTRIES-2, N_ENTRIES-1]
    for k in indices:
        e = rom[k]
        tr_fx   = to_q2_14(e['theta_ref'])
        dk_fx   = to_q2_14(e['delta'])
        dkm_fx  = to_q2_14(e['delta_km1'])
        print(f"# k={k:>3}  θref={e['theta_ref']:>9.6f} rad"
              f"  σ={e['sigma_list']}"
              f"  δk={e['delta']:>10.7f}"
              f"  δk-1={e['delta_km1']:>10.7f}"
              f"  z_res={e['z_residual']:>9.2e}")
        print(f"#       Q2.14 hex: θref=0x{to_twos_complement_hex(tr_fx)}"
              f"  δk=0x{to_twos_complement_hex(dk_fx)}"
              f"  δk-1=0x{to_twos_complement_hex(dkm_fx)}")
    print("#")


# ==============================================================
# PRINT VERILOG LOCALPARAM ROM
# ==============================================================
def print_verilog_rom(rom):
    """
    Print the Verilog localparam block.
    Bit packing per entry (48-bit total):
      [47:32] = theta_ref_k  (16-bit Q2.14)
      [31:16] = delta_k      (16-bit Q2.14)
      [15:0]  = delta_k-1    (16-bit Q2.14)
    """
    print("// ============================================================")
    print("// Auto-generated by gen_sigma_rom.py")
    print(f"// m={M}, radix={RADIX}, stages={NUM_STAGES}, entries={N_ENTRIES}")
    print("// Fixed-point: Q2.14 signed, 16-bit two's complement")
    print("// Bit layout per entry: [47:32]=theta_ref [31:16]=delta_k [15:0]=delta_km1")
    print("// IMPORTANT: delta computed as sum_{i=1}^{stages-1} sigma_i * epsilon_i")
    print("//            where epsilon_i = 2^{-i} - atan(2^{-i})")
    print("//            This is an approximation consistent with P-CORDIC structure.")
    print("//            Verify against simulation before tapeout.")
    print("// ============================================================")
    print(f"localparam [47:0] PRECOMP_ROM [0:{N_ENTRIES-1}] = '{{")

    for k, e in enumerate(rom):
        # Convert to Q2.14
        tr_fx  = to_q2_14(e['theta_ref'])
        dk_fx  = to_q2_14(e['delta'])
        dkm_fx = to_q2_14(e['delta_km1'])

        # Convert to two's complement hex
        tr_hex  = to_twos_complement_hex(tr_fx)
        dk_hex  = to_twos_complement_hex(dk_fx)
        dkm_hex = to_twos_complement_hex(dkm_fx)

        # Pack into 48-bit entry
        packed_hex = tr_hex + dk_hex + dkm_hex

        # Trailing comma except last entry
        comma = "," if k < N_ENTRIES - 1 else " "

        # Inline comment
        comment = (f"// [{k:>2}] θref={e['theta_ref']:>8.5f}"
                   f"  δk={e['delta']:>9.6f}"
                   f"  σ={e['sigma_list']}")

        print(f"    48'h{packed_hex}{comma}  {comment}")

    print("};")


# ==============================================================
# ENTRY POINT
# ==============================================================
if __name__ == "__main__":
    # Sanity check: Q2.14 range covers [-pi/2, pi/2]
    assert abs(ANGLE_MIN) < 2.0, "Q2.14 range [-2,2) sufficient for [-pi/2, pi/2]"
    assert abs(ANGLE_MAX) < 2.0, "Q2.14 range [-2,2) sufficient for [-pi/2, pi/2]"

    rom = generate_rom()
    print_verification(rom)
    print()
    print_verilog_rom(rom)