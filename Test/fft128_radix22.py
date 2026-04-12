"""
FFT 128-point — Decimation In Frequency (DIF)
==============================================
Input : input.txt
        - Mỗi dòng: <re_q88> <im_q88>  (số nguyên Q8.8 dạng two's complement 16-bit)
        - Nếu chỉ có 1 số trên dòng thì phần ảo = 0
        - Dòng bắt đầu bằng '#' là comment, bị bỏ qua
        - Đọc đúng 128 dòng dữ liệu

Output: output.txt
    - Mỗi dòng: index | real | imag
    - Giá trị thập phân, không còn ở dạng Q8.8 (giống format testbench Verilog)

Q8.8 convention:
        - 16-bit signed two's complement
        - 1 bit dấu, 7 bit nguyên, 8 bit thập phân
        - Giá trị thực = raw / 256
        - Dải: -128.0 đến +127.99609375
"""

import math

# ──────────────────────────────────────────────────────
FRAC_BITS   = 8
SCALE       = 1 << FRAC_BITS   # 256
N           = 128
INPUT_FILE  = "input_diverse_q88.txt"  # Đổi để đọc file .txt trong thư mục Test
OUTPUT_FILE = "output.txt"
# ──────────────────────────────────────────────────────


def q88_to_float(raw: int) -> float:
    """Q8.8 two's complement 16-bit → float."""
    raw = int(raw) & 0xFFFF
    if raw >= 0x8000:
        raw -= 0x10000
    return raw / SCALE


def twiddle(length: int, k: int) -> complex:
    """W_{length}^k = e^{-j 2pi k / length}"""
    angle = -2.0 * math.pi * k / length
    return complex(math.cos(angle), math.sin(angle))


def fft_dif(x: list) -> list:
    """
    Cooley-Tukey DIF FFT radix-2.
    Cấu trúc butterfly khớp với radix-2^2:
      stage lẻ  → butterfly thuần (twiddle = W^0 = 1)
      stage chẵn → butterfly + twiddle
    Output được hoán vị bit-reverse về natural order.
    """
    X = list(x)
    length = N

    while length > 1:
        half       = length // 2
        num_groups = N // length
        for g in range(num_groups):
            for k in range(half):
                i0 = g * length + k
                i1 = i0 + half
                tw = twiddle(length, k)
                a  = X[i0]
                b  = X[i1]
                X[i0] = a + b
                X[i1] = (a - b) * tw
        length //= 2

    # Bit-reverse permutation
    bits = int(math.log2(N))
    for i in range(N):
        j = int(f'{i:0{bits}b}'[::-1], 2)
        if i < j:
            X[i], X[j] = X[j], X[i]

    return X


def read_input(path: str) -> list:
    samples = []
    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts  = line.split()
            re_raw = int(parts[0])
            im_raw = int(parts[1]) if len(parts) >= 2 else 0
            samples.append(complex(q88_to_float(re_raw),
                                   q88_to_float(im_raw)))
            if len(samples) == N:
                break

    if len(samples) < N:
        print(f"[WARN] Chỉ đọc được {len(samples)} mẫu, zero-padding lên {N}")
        samples += [0+0j] * (N - len(samples))

    return samples


def write_output(path: str, result: list):
    with open(path, "w") as f:
        # Format tương tự testbench Verilog: "index real imag" (Q8.8 đã đổi sang thập phân)
        f.write("# index  real  imag  (Q8.8 -> decimal)\n")
        for i, val in enumerate(result):
            re = val.real
            im = val.imag
            f.write(f"{i:3d} {re:.8f} {im:.8f}\n")


def main():
    print(f"Đọc dữ liệu từ '{INPUT_FILE}'...")
    samples = read_input(INPUT_FILE)
    print(f"Đọc {len(samples)} mẫu.")

    print("Tính FFT...")
    result = fft_dif(samples)

    print(f"Ghi kết quả vào '{OUTPUT_FILE}'...")
    write_output(OUTPUT_FILE, result)
    print("Hoàn thành.")


if __name__ == "__main__":
    main()
