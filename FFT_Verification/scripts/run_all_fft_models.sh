#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIF_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="$(cd "$VERIF_DIR/.." && pwd)"

if [[ $# -ne 1 ]]; then
    echo "Usage:"
    echo "  $0 <input_name>"
    echo
    echo "Examples:"
    echo "  $0 impulse_A0125"
    echo "  $0 input_impulse_A0125"
    echo "  $0 input_impulse_A0125.txt"
    exit 1
fi

RAW_NAME="$1"
BASE_NAME="$(basename "$RAW_NAME")"
BASE_NAME="${BASE_NAME%.txt}"

if [[ "$BASE_NAME" != input_* ]]; then
    BASE_NAME="input_${BASE_NAME}"
fi

INPUT_FILE="${BASE_NAME}.txt"
DESC_NAME="${BASE_NAME#input_}"

RTL_INPUT="$VERIF_DIR/input_vectors/q88/$INPUT_FILE"
PYTHON_INPUT="$VERIF_DIR/input_vectors/decimal/$INPUT_FILE"
XILINX_INPUT="$VERIF_DIR/input_vectors/xilinx_cmodel_fft/$INPUT_FILE"

RTL_OUTPUT="$VERIF_DIR/output_results/rtl_cordic_fft/output_${DESC_NAME}_rtl_cordic.txt"
PYTHON_OUTPUT="$VERIF_DIR/output_results/python_fft/output_${DESC_NAME}_python_fft.txt"
XILINX_OUTPUT="$VERIF_DIR/output_results/xilinx_cmodel_fft/output_${DESC_NAME}_xilinx_cmodel.txt"

TB_VVP="$VERIF_DIR/testbench/fft128_4parallel_feedforward_tb.vvp"

echo "============================================================"
echo "Input set : $DESC_NAME"
echo "Input file: $INPUT_FILE"
echo "============================================================"

for f in "$RTL_INPUT" "$PYTHON_INPUT" "$XILINX_INPUT"; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: missing input file:"
        echo "  $f"
        exit 1
    fi
done

echo
echo "===== Input paths ====="
echo "RTL Q8.8 input        : $RTL_INPUT"
echo "Python decimal input : $PYTHON_INPUT"
echo "Xilinx C model input : $XILINX_INPUT"

echo
echo "============================================================"
echo "1. Running RTL CORDIC FFT testbench"
echo "============================================================"

if [[ "${FORCE_COMPILE:-0}" == "1" || ! -f "$TB_VVP" ]]; then
    echo "Compiling RTL testbench..."
    "$VERIF_DIR/scripts/compile_fft128_4parallel_feedforward_tb.sh"
else
    echo "Using existing compiled testbench:"
    echo "  $TB_VVP"
fi

"$VERIF_DIR/scripts/run_fft128_4parallel_feedforward_tb.sh" \
    "input_vectors/q88/$INPUT_FILE"

echo
echo "============================================================"
echo "2. Running Python NumPy FFT"
echo "============================================================"

python3 "$VERIF_DIR/models/Python/python_fft.py" \
    "$PYTHON_INPUT"

echo
echo "============================================================"
echo "3. Running Xilinx FFT C model"
echo "============================================================"

(
    cd "$VERIF_DIR/models/Xilinx_FFT_Cmodel"
    export LD_LIBRARY_PATH="$PWD:${LD_LIBRARY_PATH:-}"

    ./run_xilinx_fft_cmodel_fileio \
        "../../input_vectors/xilinx_cmodel_fft/$INPUT_FILE"
)

echo
echo "============================================================"
echo "Checking output files"
echo "============================================================"

for f in "$RTL_OUTPUT" "$PYTHON_OUTPUT" "$XILINX_OUTPUT"; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: missing output file:"
        echo "  $f"
        exit 1
    fi
done

echo "RTL CORDIC output    : $RTL_OUTPUT"
echo "Python FFT output    : $PYTHON_OUTPUT"
echo "Xilinx C model output: $XILINX_OUTPUT"

echo
echo "============================================================"
echo "Preview outputs"
echo "============================================================"

echo
echo "----- RTL CORDIC -----"
head -n 6 "$RTL_OUTPUT"

echo
echo "----- Python FFT -----"
head -n 6 "$PYTHON_OUTPUT"

echo
echo "----- Xilinx C model -----"
head -n 6 "$XILINX_OUTPUT"

echo
echo "DONE."