#!/usr/bin/env python3

from pathlib import Path
import math
import re
import sys

METRICS = ["MSE", "RMSE", "SQNR", "PSNR"]


def find_verification_dir(start_path: Path) -> Path:
    cur = start_path.resolve()

    if cur.is_file():
        cur = cur.parent

    for p in [cur] + list(cur.parents):
        if (p / "output_results" / "evaluation").is_dir():
            return p

    raise RuntimeError("Cannot find FFT_Verification directory")


def parse_float(s: str) -> float:
    s = s.strip()

    if s.lower() == "inf":
        return math.inf
    if s.lower() == "-inf":
        return -math.inf
    if s.lower() == "nan":
        return math.nan

    return float(s)


def read_eval_file(path: Path) -> dict:
    """
    Return:
    {
        comparison_name: {
            "MSE": value,
            "RMSE": value,
            "SQNR": value,
            "PSNR": value
        }
    }
    """

    rows = {}

    with path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")

            if not line.startswith("|"):
                continue

            if "Comparison" in line or "---" in line:
                continue

            parts = [p.strip() for p in line.split("|")[1:-1]]

            if len(parts) < 5:
                continue

            name = parts[0]

            # Format mới:
            # Comparison | MSE | RMSE | SQNR | PSNR
            if len(parts) == 5:
                mse = parse_float(parts[1])
                rmse = parse_float(parts[2])
                sqnr = parse_float(parts[3])
                psnr = parse_float(parts[4])

            # Format cũ:
            # Comparison | MSE | RMSE | SNR | SQNR | SNR/SQNR | PSNR
            elif len(parts) >= 7:
                mse = parse_float(parts[1])
                rmse = parse_float(parts[2])
                sqnr = parse_float(parts[4])
                psnr = parse_float(parts[6])

            else:
                continue

            rows[name] = {
                "MSE": mse,
                "RMSE": rmse,
                "SQNR": sqnr,
                "PSNR": psnr,
            }

    return rows


def avg(values: list[float]) -> float:
    finite_values = [
        v for v in values
        if not math.isnan(v) and not math.isinf(v)
    ]

    if finite_values:
        return sum(finite_values) / len(finite_values)

    # Nếu tất cả đều là inf, giữ inf
    if any(v == math.inf for v in values):
        return math.inf

    if any(v == -math.inf for v in values):
        return -math.inf

    return math.nan


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


def make_table(rows: list[tuple[str, dict]], num_files: int) -> str:
    lines = []

    lines.append("")
    lines.append("FFT Average Error Evaluation")
    lines.append(f"Number of eval files: {num_files}")
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


def main() -> None:
    verif_dir = find_verification_dir(Path(__file__))
    eval_dir = verif_dir / "output_results" / "evaluation"

    eval_files = sorted(eval_dir.glob("eval_*.txt"))

    # Bỏ qua file tổng hợp nếu đã từng tạo
    eval_files = [
        f for f in eval_files
        if f.name not in {
            "eval_average.txt",
            "eval_all_inputs.txt",
            "eval_summary.txt",
        }
    ]

    if not eval_files:
        print(f"ERROR: no eval_*.txt files found in {eval_dir}")
        sys.exit(1)

    collected = {}

    for path in eval_files:
        data = read_eval_file(path)

        for comparison, metrics in data.items():
            if comparison not in collected:
                collected[comparison] = {m: [] for m in METRICS}

            for m in METRICS:
                collected[comparison][m].append(metrics[m])

    avg_rows = []

    for comparison, values in collected.items():
        avg_metrics = {
            "MSE": avg(values["MSE"]),
            "RMSE": avg(values["RMSE"]),
            "SQNR": avg(values["SQNR"]),
            "PSNR": avg(values["PSNR"]),
        }

        avg_rows.append((comparison, avg_metrics))

    result = make_table(avg_rows, len(eval_files))

    print(result)

    out_path = eval_dir / "eval_average.txt"

    with out_path.open("w", encoding="utf-8") as f:
        f.write(result)
        f.write("\n")

    print()
    print(f"Average evaluation written to: {out_path}")


if __name__ == "__main__":
    main()
