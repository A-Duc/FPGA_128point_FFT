import random
from pathlib import Path

N = 128
OUT_DIR = Path("inputs")

def make_dataset(filename: str, low_raw: int, high_raw: int, seed: int) -> None:
    rng = random.Random(seed)
    path = OUT_DIR / filename
    with path.open("w", encoding="utf-8") as f:
        for _ in range(N):
            re_raw = rng.randint(low_raw, high_raw)
            im_raw = rng.randint(low_raw, high_raw)
            f.write(f"{re_raw} {im_raw}\n")
    print(f"[DONE] {path}")

def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    make_dataset(
        filename="input_rand_m1_to_1_q88.txt",
        low_raw=-256,
        high_raw=256,
        seed=101
    )

    make_dataset(
        filename="input_rand_m0p5_to_0p5_q88.txt",
        low_raw=-128,
        high_raw=128,
        seed=202
    )

    make_dataset(
        filename="input_rand_m10_to_10_q88.txt",
        low_raw=-2560,
        high_raw=2560,
        seed=303
    )

if __name__ == "__main__":
    main()