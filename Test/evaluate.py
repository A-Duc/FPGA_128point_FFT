import sys
import math
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
OUTPUT_EVAL_DIR = SCRIPT_DIR / "outputs_eval"

# Q8.8 signed on 16-bit:
# max positive raw value = 32767
# per-component full-scale in time domain
Q88_FULL_SCALE_COMPONENT = 32767.0 / 256.0

# FFT is unnormalized (same as numpy.fft.fft),
# so worst-case per-component full-scale in frequency domain is N * input_full_scale.
# We compute this after reading N from the files.

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


def build_report_lines(
    n: int,
    signal_power: float,
    noise_power: float,
    snr_db: float,
    psnr_db: float,
    mse: float,
    rmse: float,
    ref_path: Path,
    dut_path: Path,
    fft_full_scale_component: float,
    fft_full_scale_power: float,
):
    lines = [
        "===== EVALUATION =====",
        f"Reference file: {ref_path}",
        f"DUT file: {dut_path}",
        f"N: {n}",
        f"Signal power: {fmt_num(signal_power)}",
        f"Noise power: {fmt_num(noise_power)}",
        f"SNR (dB): {fmt_num(snr_db)}",
        f"PSNR (dB): {fmt_num(psnr_db)}",
        f"Input full-scale component (Q8.8): {fmt_num(Q88_FULL_SCALE_COMPONENT)}",
        f"FFT full-scale component: {fmt_num(fft_full_scale_component)}",
        f"FFT full-scale complex power: {fmt_num(fft_full_scale_power)}",
        f"MSE: {fmt_num(mse)}",
        f"RMSE: {fmt_num(rmse)}",
    ]
    return lines


def save_report(dut_path: Path, report_lines):
    OUTPUT_EVAL_DIR.mkdir(parents=True, exist_ok=True)

    out_name = f"evaluate_{dut_path.stem}.txt"
    out_path = OUTPUT_EVAL_DIR / out_name

    with out_path.open("w", encoding="utf-8") as f:
        f.write("\n".join(report_lines) + "\n")

    return out_path


def main():
    if len(sys.argv) != 3:
        print("Usage: python evaluate.py <reference_file> <dut_file>")
        print("Example:")
        print(
            "  python evaluate.py outputs_sw/out_input_rand_m1_to_1_q88_python.txt outputs_hw/out_input_rand_m1_to_1_q88.txt"
        )
        sys.exit(1)

    ref_path = Path(sys.argv[1])
    dut_path = Path(sys.argv[2])

    if not ref_path.is_absolute():
        ref_path = (Path.cwd() / ref_path).resolve()
    if not dut_path.is_absolute():
        dut_path = (Path.cwd() / dut_path).resolve()

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

    for (_, ref_re, ref_im), (_, dut_re, dut_im) in zip(ref_rows, dut_rows):
        err_re = dut_re - ref_re
        err_im = dut_im - ref_im

        ref_mag_sq = ref_re * ref_re + ref_im * ref_im
        err_mag_sq = err_re * err_re + err_im * err_im

        signal_power += ref_mag_sq
        noise_power += err_mag_sq

    mse = noise_power / n
    rmse = math.sqrt(mse)
    snr_db = safe_db(signal_power, noise_power)

    fft_full_scale_component = Q88_FULL_SCALE_COMPONENT * n
    fft_full_scale_power = 2.0 * (fft_full_scale_component ** 2)
    psnr_db = safe_db(fft_full_scale_power, mse)

    report_lines = build_report_lines(
        n=n,
        signal_power=signal_power,
        noise_power=noise_power,
        snr_db=snr_db,
        psnr_db=psnr_db,
        mse=mse,
        rmse=rmse,
        ref_path=ref_path,
        dut_path=dut_path,
        fft_full_scale_component=fft_full_scale_component,
        fft_full_scale_power=fft_full_scale_power,
    )

    for line in report_lines:
        print(line)

    out_path = save_report(dut_path, report_lines)
    print(f"Evaluation saved to: {out_path}")


if __name__ == "__main__":
    main()