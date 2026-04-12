from pathlib import Path
import sys
import numpy as np

SCRIPT_DIR = Path(__file__).resolve().parent
OUTPUT_SW_DIR = SCRIPT_DIR / "outputs_sw"
N = 128

def read_input_q88(path: Path) -> np.ndarray:
    xs = []
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            a, b = line.split()
            xs.append(int(a) / 256.0 + 1j * int(b) / 256.0)

    if len(xs) != N:
        raise ValueError(f"{path.name}: read {len(xs)} samples, expected {N}")

    return np.array(xs, dtype=np.complex128)

def write_fft_natural(path: Path, X: np.ndarray) -> None:
    with path.open("w", encoding="utf-8") as f:
        f.write("# k re_decimal im_decimal\n")
        for k in range(N):
            f.write(f"{k} {X[k].real:.6f} {X[k].imag:.6f}\n")

def main():
    if len(sys.argv) != 2:
        print("Usage: python python_fft.py inputs/<input_file>.txt")
        sys.exit(1)

    input_arg = sys.argv[1]
    input_path = Path(input_arg)
    if not input_path.is_absolute():
        input_path = SCRIPT_DIR / input_arg

    if not input_path.is_file():
        print(f"ERROR: input file not found: {input_path}")
        sys.exit(1)

    OUTPUT_SW_DIR.mkdir(parents=True, exist_ok=True)

    stem_name = input_path.stem
    output_path = OUTPUT_SW_DIR / f"out_{stem_name}_python.txt"

    x = read_input_q88(input_path)
    X = np.fft.fft(x)
    write_fft_natural(output_path, X)

    print(f"Python FFT output written to: {output_path}")

if __name__ == "__main__":
    main()