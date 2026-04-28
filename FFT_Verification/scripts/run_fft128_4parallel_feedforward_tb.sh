#!/usr/bin/env bash
set -e

if [ $# -ne 1 ]; then
  echo "Usage: ./run_fft128_4parallel_feedforward_tb.sh input_vectors/q88/input_<description>.txt"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIF_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

TB_DIR="$VERIF_DIR/testbench"
OUTPUT_DIR="$VERIF_DIR/output_results/rtl_cordic_fft"

TB_NAME="fft128_4parallel_feedforward_tb"
TB_VVP="$TB_DIR/${TB_NAME}.vvp"

INPUT_ARG="$1"

case "$INPUT_ARG" in
  /*)
    INPUT_PATH="$INPUT_ARG"
    ;;
  *)
    if [ -f "$INPUT_ARG" ]; then
      INPUT_PATH="$(cd "$(dirname "$INPUT_ARG")" && pwd)/$(basename "$INPUT_ARG")"
    else
      INPUT_PATH="$VERIF_DIR/$INPUT_ARG"
    fi
    ;;
esac

if [ ! -f "$INPUT_PATH" ]; then
  echo "ERROR: input file not found: $INPUT_PATH"
  exit 1
fi

if [ ! -f "$TB_VVP" ]; then
  echo "ERROR: compiled simulation not found: $TB_VVP"
  echo "Please run: $SCRIPT_DIR/compile_fft128_4parallel_feedforward_tb.sh"
  exit 1
fi

BASE_NAME="$(basename "$INPUT_PATH")"

case "$BASE_NAME" in
  input_*.txt)
    ;;
  *)
    echo "ERROR: input file name must have format: input_<description>.txt"
    echo "Current file name: $BASE_NAME"
    exit 1
    ;;
esac

STEM_NAME="${BASE_NAME%.txt}"
DESC_NAME="${STEM_NAME#input_}"

if [ -z "$DESC_NAME" ]; then
  echo "ERROR: empty input description in file name: $BASE_NAME"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

OUTPUT_PATH="$OUTPUT_DIR/output_${DESC_NAME}_rtl_cordic.txt"

vvp "$TB_VVP" \
  +INPUT="$INPUT_PATH" \
  +OUTPUT="$OUTPUT_PATH"

echo "RTL CORDIC FFT output written to: $OUTPUT_PATH"