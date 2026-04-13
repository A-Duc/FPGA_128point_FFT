import sys
import math
from pathlib import Path


def read_fft_file(path: Path):
    rows = []
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split()
            if len(parts) != 3:
                raise ValueError(f"{path}: invalid line: {line}")
            k = int(parts[0])
            re = float(parts[1])
            im = float(parts[2])
            rows.append((k, re, im))

    if not rows:
        raise ValueError(f"{path}: no data found")

    rows.sort(key=lambda x: x[0])
    return rows


def check_same_k(ref_rows, dut_rows):
    if len(ref_rows) != len(dut_rows):
        raise ValueError(
            f"Length mismatch: ref has {len(ref_rows)} rows, dut has {len(dut_rows)} rows"
        )

    for i, (ref_row, dut_row) in enumerate(zip(ref_rows, dut_rows)):
        if ref_row[0] != dut_row[0]:
            raise ValueError(
                f"k mismatch at row {i}: ref k={ref_row[0]}, dut k={dut_row[0]}"
            )


def safe_db(num: float, den: float) -> float:
    if den <= 0.0:
        return float("inf")
    if num <= 0.0:
        return float("-inf")
    return 10.0 * math.log10(num / den)


def fmt_num(x: float) -> str:
    if math.isinf(x):
        return "inf"
    if math.isnan(x):
        return "nan"
    return f"{x:.6f}"


def main():
    if len(sys.argv) != 3:
        print("Usage: python evaluate.py <reference_file> <dut_file>")
        print("Example:")
        print("  python evaluate.py outputs_sw/out_input_rand_m1_to_1_q88.txt outputs_hw/out_input_rand_m1_to_1_q88.txt")
        sys.exit(1)

    ref_path = Path(sys.argv[1])
    dut_path = Path(sys.argv[2])

    if not ref_path.is_file():
        print(f"ERROR: reference file not found: {ref_path}")
        sys.exit(1)

    if not dut_path.is_file():
        print(f"ERROR: dut file not found: {dut_path}")
        sys.exit(1)

    ref_rows = read_fft_file(ref_path)
    dut_rows = read_fft_file(dut_path)
    check_same_k(ref_rows, dut_rows)

    n = len(ref_rows)

    signal_power = 0.0
    noise_power = 0.0
    peak_magnitude = 0.0

    for (_, ref_re, ref_im), (_, dut_re, dut_im) in zip(ref_rows, dut_rows):
        err_re = dut_re - ref_re
        err_im = dut_im - ref_im

        ref_mag_sq = ref_re * ref_re + ref_im * ref_im
        err_mag_sq = err_re * err_re + err_im * err_im

        signal_power += ref_mag_sq
        noise_power += err_mag_sq

        ref_mag = math.sqrt(ref_mag_sq)
        if ref_mag > peak_magnitude:
            peak_magnitude = ref_mag

    mse = noise_power / n
    rmse = math.sqrt(mse)
    snr_db = safe_db(signal_power, noise_power)
    psnr_db = safe_db(peak_magnitude * peak_magnitude, mse)

    print("===== EVALUATION =====")
    print(f"N: {n}")
    print(f"Signal power: {fmt_num(signal_power)}")
    print(f"Noise power: {fmt_num(noise_power)}")
    print(f"SNR (dB): {fmt_num(snr_db)}")
    print(f"Peak magnitude: {fmt_num(peak_magnitude)}")
    print(f"PSNR (dB): {fmt_num(psnr_db)}")
    print(f"MSE: {fmt_num(mse)}")
    print(f"RMSE: {fmt_num(rmse)}")


if __name__ == "__main__":
    main()