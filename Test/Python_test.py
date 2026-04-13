import numpy as np

INPUT_FILE = "inputs/input_rand_0to12_q88.txt"
OUTPUT_FILE = "outputs/output_rand_0to12_q88.txt"

def read_input_q88(path):
    xs = []
    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            a, b = line.split()
            xs.append(int(a)/256.0 + 1j*int(b)/256.0)
    return np.array(xs, dtype=np.complex128)

def read_hw_output(path):
    rows = []
    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            k, re, im = line.split()
            rows.append((int(k), float(re), float(im)))
    return rows

x = read_input_q88(INPUT_FILE)
X = np.fft.fft(x)
hw = read_hw_output(OUTPUT_FILE)

print("Software X[0] =", X[0])
for k, re, im in hw[:8]:
    print(f"HW row: k={k}, value={re}+j{im}")