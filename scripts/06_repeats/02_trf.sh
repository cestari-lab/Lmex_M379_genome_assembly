#!/bin/bash
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=0-20:00
#SBATCH --job-name=trf
#SBATCH --output=logs/trf_%j.out
# Tandem Repeats Finder on the final assembly.
# Parameters (recommended defaults): Match=2 Mismatch=7 Delta=7 PM=80 PI=10 Minscore=50 MaxPeriod=500
#   -m  masked FASTA   -d  .dat file   -h  no HTML output
# TRF is single-threaded, so 1 CPU is enough.
set -euo pipefail
source "${SLURM_SUBMIT_DIR:-.}/config.sh"
setup_env trf

require_file "$FINAL_FASTA"
mkdir -p "$TRF_DIR"; cd "$TRF_DIR"

# TRF returns a non-zero exit code even on success, so do not let set -e stop the job
trf "$FINAL_FASTA" 2 7 7 80 10 50 500 -m -d -h || true

DAT="$(basename "$FINAL_FASTA").2.7.7.80.10.50.500.dat"
require_file "$DAT"

# Convert .dat -> BED (chrom, start0, end, period, copies, consensus)
awk '/^Sequence:/{chr=$2; next}
     NF>=14 && $1 ~ /^[0-9]+$/ {print chr"\t"($1-1)"\t"$2"\t"$3"\t"$4"\t"$14}' \
     "$DAT" > trf_repeats.bed
echo "Tandem repeats: $(wc -l < trf_repeats.bed)  (bp covered: $(awk '{s+=$3-$2}END{print s}' trf_repeats.bed))"
