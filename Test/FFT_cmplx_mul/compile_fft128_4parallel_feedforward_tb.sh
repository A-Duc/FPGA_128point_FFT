#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIM_DIR="$SCRIPT_DIR/sim"
TB_NAME="fft128_4parallel_feedforward_tb"
TB_VVP="$SIM_DIR/${TB_NAME}.vvp"

mkdir -p "$SIM_DIR"

DESIGN_FILES=$(find "$SCRIPT_DIR" -maxdepth 1 -name "*.v" ! -name "${TB_NAME}.v" | sort)

iverilog -g2012 \
  -o "$TB_VVP" \
  -s "$TB_NAME" \
  "$SCRIPT_DIR/${TB_NAME}.v" \
  $DESIGN_FILES

echo "Compile done: $TB_VVP"