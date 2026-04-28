#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIF_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="$(cd "$VERIF_DIR/.." && pwd)"

TB_DIR="$VERIF_DIR/testbench"
CORE_RTL_DIR="$PROJECT_DIR/FFT_Core_RTL"

TB_NAME="fft128_4parallel_feedforward_tb"
TB_SRC="$TB_DIR/${TB_NAME}.v"
TB_VVP="$TB_DIR/${TB_NAME}.vvp"

if [ ! -f "$TB_SRC" ]; then
  echo "ERROR: testbench file not found: $TB_SRC"
  exit 1
fi

if [ ! -d "$CORE_RTL_DIR" ]; then
  echo "ERROR: RTL directory not found: $CORE_RTL_DIR"
  exit 1
fi

iverilog -g2012 \
  -o "$TB_VVP" \
  -s "$TB_NAME" \
  "$TB_SRC" \
  "$CORE_RTL_DIR/"*.v

echo "Compile done: $TB_VVP"