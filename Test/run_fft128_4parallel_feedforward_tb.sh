#!/usr/bin/env bash
set -e

if [ $# -ne 1 ]; then
  echo "Usage: ./run_fft128_4parallel_feedforward_tb.sh inputs/<input_file>.txt"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIM_DIR="$SCRIPT_DIR/sim"
OUTPUT_DIR="$SCRIPT_DIR/outputs_hw"
TB_NAME="fft128_4parallel_feedforward_tb"
TB_VVP="$SIM_DIR/${TB_NAME}.vvp"

INPUT_ARG="$1"

case "$INPUT_ARG" in
  /*) INPUT_PATH="$INPUT_ARG" ;;
  *)  INPUT_PATH="$SCRIPT_DIR/$INPUT_ARG" ;;
esac

if [ ! -f "$INPUT_PATH" ]; then
  echo "ERROR: input file not found: $INPUT_PATH"
  exit 1
fi

if [ ! -f "$TB_VVP" ]; then
  echo "ERROR: compiled simulation not found: $TB_VVP"
  echo "Please run ./compile_fft128_4parallel_feedforward_tb.sh first"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

BASE_NAME="$(basename "$INPUT_PATH")"
STEM_NAME="${BASE_NAME%.txt}"
OUTPUT_PATH="$OUTPUT_DIR/out_${STEM_NAME}.txt"

vvp "$TB_VVP" \
  +INPUT="$INPUT_PATH" \
  +OUTPUT="$OUTPUT_PATH"

echo "HW output written to: $OUTPUT_PATH"