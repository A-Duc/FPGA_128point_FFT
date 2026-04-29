from pathlib import Path
import numpy as np

N = 128
SCALE = 256

VERIF_DIR = Path(__file__).resolve().parents[1]

Q88_DIR = VERIF_DIR / "input_vectors" / "q88"
DECIMAL_DIR = VERIF_DIR / "input_vectors" / "decimal"
XILINX_DIR = VERIF_DIR / "input_vectors" / "xilinx_cmodel_fft"

Q88_DIR.mkdir(parents=True, exist_ok=True)
DECIMAL_DIR.mkdir(parents=True, exist_ok=True)
XILINX_DIR.mkdir(parents=True, exist_ok=True)


def quantize_q88(x: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    re_q = np.rint(np.real(x) * SCALE).astype(int)
    im_q = np.rint(np.imag(x) * SCALE).astype(int)

    # Keep inputs compatible with Xilinx fixed-point C model range [-1, 1).
    # q = -256 maps to -1.0; q = 255 maps to 0.99609375.
    re_q = np.clip(re_q, -256, 255)
    im_q = np.clip(im_q, -256, 255)

    return re_q, im_q


def write_input_set(name: str, x: np.ndarray) -> None:
    if len(x) != N:
        raise ValueError(f"{name}: expected {N} samples, got {len(x)}")

    re_q, im_q = quantize_q88(x)

    q88_path = Q88_DIR / f"input_{name}.txt"
    decimal_path = DECIMAL_DIR / f"input_{name}.txt"
    xilinx_path = XILINX_DIR / f"input_{name}.txt"

    with q88_path.open("w", encoding="utf-8") as fq, \
         decimal_path.open("w", encoding="utf-8") as fd, \
         xilinx_path.open("w", encoding="utf-8") as fx:

        fq.write("# re_q88_int im_q88_int\n")
        fd.write("# re_decimal im_decimal\n")
        fx.write("# re_decimal im_decimal\n")

        for r, i in zip(re_q, im_q):
            re_dec = r / SCALE
            im_dec = i / SCALE

            fq.write(f"{r} {i}\n")
            fd.write(f"{re_dec:.12f} {im_dec:.12f}\n")
            fx.write(f"{re_dec:.12f} {im_dec:.12f}\n")

    print(f"Generated input_{name}.txt")


def complex_tone(k: float, amp: float, phase: float = 0.0) -> np.ndarray:
    n = np.arange(N)
    return amp * np.exp(1j * (2.0 * np.pi * k * n / N + phase))


def make_slot_noise(seed: int, amp: float, slot_start: int, slot_stop: int) -> np.ndarray:
    rng = np.random.default_rng(seed)

    freq = rng.normal(0.0, 1.0, N) + 1j * rng.normal(0.0, 1.0, N)

    freq[slot_start:slot_stop + 1] = 0.0

    # Also clear the mirrored negative-frequency area to make the slot clearer.
    mirror_start = (N - slot_stop) % N
    mirror_stop = (N - slot_start) % N

    if mirror_start <= mirror_stop:
        freq[mirror_start:mirror_stop + 1] = 0.0
    else:
        freq[mirror_start:] = 0.0
        freq[:mirror_stop + 1] = 0.0

    time_sig = np.fft.ifft(freq)

    max_abs_component = max(
        np.max(np.abs(np.real(time_sig))),
        np.max(np.abs(np.imag(time_sig))),
        1e-12
    )

    time_sig = time_sig / max_abs_component * amp
    return time_sig


def main() -> None:
    n = np.arange(N)

    # Group 1: sanity / debug inputs
    write_input_set("zero", np.zeros(N, dtype=np.complex128))

    impulse = np.zeros(N, dtype=np.complex128)
    impulse[0] = 0.125 + 0j
    write_input_set("impulse_A0125", impulse)

    write_input_set("dc_A025", np.full(N, 0.25 + 0j, dtype=np.complex128))

    write_input_set("alt_A025", 0.25 * ((-1.0) ** n).astype(np.complex128))

    # Group 2: integer-bin complex tones
    for k in [1, 7, 31, 63]:
        write_input_set(f"tone_k{k}_A025", complex_tone(k=k, amp=0.25))

    # Group 3: PG109-style two-tone inputs
    x_pg109_a025 = complex_tone(2.6, 0.25) + complex_tone(23.2, 0.25 / 4.0)
    write_input_set("pg109_twotone_A025", x_pg109_a025)

    x_pg109_a05 = complex_tone(2.6, 0.50) + complex_tone(23.2, 0.50 / 4.0)
    write_input_set("pg109_twotone_A05", x_pg109_a05)

    # Group 4: random statistical inputs
    rng = np.random.default_rng(1)

    x_random_a025 = (
        rng.uniform(-0.25, 0.25, N)
        + 1j * rng.uniform(-0.25, 0.25, N)
    )
    write_input_set("random_uniform_A025_seed1", x_random_a025)

    rng = np.random.default_rng(1)
    x_random_a05 = (
        rng.uniform(-0.50, 0.50, N)
        + 1j * rng.uniform(-0.50, 0.50, N)
    )
    write_input_set("random_uniform_A05_seed1", x_random_a05)

    rng = np.random.default_rng(1)
    x_gauss = rng.normal(0.0, 1.0, N) + 1j * rng.normal(0.0, 1.0, N)
    max_abs_component = max(
        np.max(np.abs(np.real(x_gauss))),
        np.max(np.abs(np.imag(x_gauss))),
        1e-12
    )
    x_gauss = x_gauss / max_abs_component * 0.25
    write_input_set("gaussian_A025_seed1", x_gauss)

    # Group 5: slot-noise dynamic-range style inputs
    write_input_set(
        "slot_noise_A05_seed1",
        make_slot_noise(seed=1, amp=0.50, slot_start=40, slot_stop=55)
    )

    write_input_set(
        "slot_noise_A0875_seed1",
        make_slot_noise(seed=1, amp=0.875, slot_start=40, slot_stop=55)
    )


if __name__ == "__main__":
    main()