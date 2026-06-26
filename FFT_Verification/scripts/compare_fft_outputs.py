#!/usr/bin/env python3

from pathlib import Path
import sys
import math
import numpy as np

N = 128


def find_verification_dir(start_path: Path) -> Path:
    cur = start_path.resolve()

    if cur.is_file():
        cur = cur.parent

    for p in [cur] + list(cur.parents):
        if (p / "input_vectors").is_dir() and (p / "output_results").is_dir():
            return p

    raise RuntimeError("Cannot find FFT_Verification directory")


def normalize_input_name(raw_name: str) -> str:
    name = Path(raw_name).name

    if name.endswith(".txt"):
        name = name[:-4]

    if name.startswith("input_"):
        desc = name[len("input_"):]
    else:
        desc = name

    return desc


def read_fft_output(path: Path) -> np.ndarray:
    if not path.is_file():
        raise FileNotFoundError(f"Missing output file: {path}")

    values = {}

    with path.open("r", encoding="utf-8") as f:
        for line_no, line in enumerate(f, start=1):
            line = line.strip()

            if not line or line.startswith("#"):
                continue

            parts = line.split()

            if len(parts) < 3:
                raise ValueError(f"{path}: invalid line {line_no}: {line}")

            k = int(parts[0])
            re = float(parts[1])
            im = float(parts[2])

            if k < 0 or k >= N:
                raise ValueError(f"{path}: invalid k={k} at line {line_no}")

            values[k] = re + 1j * im

    if len(values) != N:
        raise ValueError(f"{path}: read {len(values)} bins, expected {N}")

    return np.array([values[k] for k in range(N)], dtype=np.complex128)


def safe_db_ratio(num: float, den: float) -> float:
    if den == 0.0:
        return math.inf

    if num == 0.0:
        return -math.inf

    return 10.0 * math.log10(num / den)


def compute_metrics(x_test: np.ndarray, x_ref: np.ndarray) -> dict:
    err = x_test - x_ref

    mse = float(np.mean(np.abs(err) ** 2))
    rmse = math.sqrt(mse)

    signal_power = float(np.sum(np.abs(x_ref) ** 2))
    noise_power = float(np.sum(np.abs(err) ** 2))

    sqnr_db = safe_db_ratio(signal_power, noise_power)

    peak = float(np.max(np.abs(x_ref)))

    if mse == 0.0:
        psnr_db = math.inf
    elif peak == 0.0:
        psnr_db = -math.inf
    else:
        psnr_db = 10.0 * math.log10((peak ** 2) / mse)

    return {
        "MSE": mse,
        "RMSE": rmse,
        "SQNR": sqnr_db,
        "PSNR": psnr_db,
    }


def fmt_sci(x: float) -> str:
    if math.isinf(x):
        return "inf" if x > 0 else "-inf"

    if math.isnan(x):
        return "nan"

    return f"{x:.4e}"


def fmt_db(x: float) -> str:
    if math.isinf(x):
        return "inf" if x > 0 else "-inf"

    if math.isnan(x):
        return "nan"

    return f"{x:.3f}"


def make_table(desc: str, rows: list[tuple[str, dict]]) -> str:
    lines = []

    lines.append("")
    lines.append("FFT Error Evaluation")
    lines.append(f"Input set : {desc}")
    lines.append("")
    lines.append(
        "+-----------------------------------+--------------+--------------+-----------+-----------+"
    )
    lines.append(
        "| Comparison                        | MSE          | RMSE         | SQNR(dB)  | PSNR(dB)  |"
    )
    lines.append(
        "+-----------------------------------+--------------+--------------+-----------+-----------+"
    )

    for name, m in rows:
        lines.append(
            f"| {name:<33} "
            f"| {fmt_sci(m['MSE']):>12} "
            f"| {fmt_sci(m['RMSE']):>12} "
            f"| {fmt_db(m['SQNR']):>9} "
            f"| {fmt_db(m['PSNR']):>9} |"
        )

    lines.append(
        "+-----------------------------------+--------------+--------------+-----------+-----------+"
    )

    return "\n".join(lines)


def compare_one(verif_dir: Path, raw_name: str) -> Path:
    desc = normalize_input_name(raw_name)

    rtl_path = (
        verif_dir
        / "output_results"
        / "rtl_cordic_fft"
        / f"output_{desc}_rtl_cordic.txt"
    )

    python_path = (
        verif_dir
        / "output_results"
        / "python_fft"
        / f"output_{desc}_python_fft.txt"
    )

    xilinx_path = (
        verif_dir
        / "output_results"
        / "xilinx_cmodel_fft"
        / f"output_{desc}_xilinx_cmodel.txt"
    )

    x_rtl = read_fft_output(rtl_path)
    x_python = read_fft_output(python_path)
    x_xilinx = read_fft_output(xilinx_path)

    rows = [
        ("Xilinx C model vs Python FFT", compute_metrics(x_xilinx, x_python)),
        ("FFT_Core_RTL vs Python FFT", compute_metrics(x_rtl, x_python)),
        ("FFT_Core_RTL vs Xilinx C model", compute_metrics(x_rtl, x_xilinx)),
    ]

    result_text = make_table(desc, rows)
    print(result_text)

    eval_dir = verif_dir / "output_results" / "evaluation"
    eval_dir.mkdir(parents=True, exist_ok=True)

    eval_path = eval_dir / f"eval_{desc}.txt"

    with eval_path.open("w", encoding="utf-8") as f:
        f.write(result_text)
        f.write("\n")

    print(f"Evaluation written to: {eval_path}")
    return eval_path


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage:")
        print("  ./FFT_Verification/scripts/compare_fft_outputs.py <input_name> [input_name ...]")
        print()
        print("Examples:")
        print("  ./FFT_Verification/scripts/compare_fft_outputs.py tone_k7_A025")
        print("  ./FFT_Verification/scripts/compare_fft_outputs.py input_tone_k7_A025")
        print("  ./FFT_Verification/scripts/compare_fft_outputs.py input_tone_k7_A025.txt")
        print("  ./FFT_Verification/scripts/compare_fft_outputs.py input_gaussian_A025_seed1 input_random_uniform_A05_seed1")
        sys.exit(1)

    verif_dir = find_verification_dir(Path(__file__))

    for idx, raw_name in enumerate(sys.argv[1:], start=1):
        if idx > 1:
            print("\n")
        compare_one(verif_dir, raw_name)


if __name__ == "__main__":
    main()
