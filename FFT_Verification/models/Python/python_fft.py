from pathlib import Path
import sys
import numpy as np

N = 128


def find_verification_dir(start_path: Path) -> Path:
    cur = start_path.resolve()

    if cur.is_file():
        cur = cur.parent

    for p in [cur] + list(cur.parents):
        if (p / "input_vectors").is_dir() and (p / "output_results").is_dir():
            return p

    raise RuntimeError(
        "Cannot find FFT_Verification directory. "
        "Expected folders: input_vectors/ and output_results/"
    )


SCRIPT_DIR = Path(__file__).resolve().parent
VERIF_DIR = find_verification_dir(SCRIPT_DIR)

INPUT_DECIMAL_DIR = VERIF_DIR / "input_vectors" / "decimal"
OUTPUT_PYTHON_DIR = VERIF_DIR / "output_results" / "python_fft"


def read_input_decimal(path: Path) -> np.ndarray:
    xs = []

    with path.open("r", encoding="utf-8") as f:
        for line_no, line in enumerate(f, start=1):
            line = line.strip()

            if not line or line.startswith("#"):
                continue

            parts = line.split()

            if len(parts) < 2:
                raise ValueError(f"{path}: invalid line {line_no}: {line}")

            re = float(parts[0])
            im = float(parts[1])

            xs.append(re + 1j * im)

    if len(xs) != N:
        raise ValueError(f"{path.name}: read {len(xs)} samples, expected {N}")

    return np.array(xs, dtype=np.complex128)


def make_output_path(input_path: Path) -> Path:
    stem = input_path.stem

    if stem.startswith("input_"):
        desc = stem[len("input_"):]
    else:
        desc = stem

    return OUTPUT_PYTHON_DIR / f"output_{desc}_python_fft.txt"


def write_fft_natural(path: Path, X: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)

    with path.open("w", encoding="utf-8") as f:
        f.write("# k re_decimal im_decimal\n")

        for k in range(N):
            f.write(f"{k} {X[k].real:.12f} {X[k].imag:.12f}\n")


def resolve_input_path(input_arg: str) -> Path:
    input_path = Path(input_arg)

    if input_path.is_absolute():
        return input_path

    # Case 1: user passes path from current working directory
    cwd_path = Path.cwd() / input_path
    if cwd_path.is_file():
        return cwd_path.resolve()

    # Case 2: user passes path relative to FFT_Verification
    verif_path = VERIF_DIR / input_path
    if verif_path.is_file():
        return verif_path.resolve()

    # Case 3: user passes only file name
    decimal_path = INPUT_DECIMAL_DIR / input_path
    if decimal_path.is_file():
        return decimal_path.resolve()

    raise FileNotFoundError(
        f"Input file not found.\n"
        f"Tried:\n"
        f"  {cwd_path}\n"
        f"  {verif_path}\n"
        f"  {decimal_path}"
    )


def main() -> None:
    if len(sys.argv) != 2:
        print("Usage:")
        print("  python3 python_fft.py input_vectors/decimal/input_<description>.txt")
        print("  python3 python_fft.py input_<description>.txt")
        sys.exit(1)

    input_path = resolve_input_path(sys.argv[1])

    x = read_input_decimal(input_path)
    X = np.fft.fft(x)

    output_path = make_output_path(input_path)
    write_fft_natural(output_path, X)

    print(f"Python FFT input : {input_path}")
    print(f"Python FFT output: {output_path}")


if __name__ == "__main__":
    main()