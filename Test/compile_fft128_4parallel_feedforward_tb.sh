#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIM_DIR="$SCRIPT_DIR/sim"
TB_NAME="fft128_4parallel_feedforward_tb"
TB_VVP="$SIM_DIR/${TB_NAME}.vvp"

mkdir -p "$SIM_DIR"

iverilog -g2012 \
  -o "$TB_VVP" \
  -s "$TB_NAME" \
  "$SCRIPT_DIR/${TB_NAME}.v" \
  "$SCRIPT_DIR/../Source_Code/"*.v

echo "Compile done: $TB_VVP"