#!/bin/bash
#SBATCH --cpus-per-task=16
#SBATCH --mem=120G
#SBATCH --time=24:00:00
#SBATCH --job-name=tgs_gapclose
#SBATCH --output=logs/tgs_gapclose_%j.out
# ALTERNATIVE (exploratory; produced no output in our run): TGS-GapCloser with Racon correction.
set -euo pipefail
source "${SLURM_SUBMIT_DIR:-.}/config.sh"
setup_env tgs_gapcloser

OUT="$SALSA_DIR/tgsgapcloser"
require_file "$SALSA_FASTA" "$ONT_FILT"
mkdir -p "$OUT"; cd "$OUT"

# TGS-GapCloser expects FASTA reads
sed -n '1~4s/^@/>/p;2~4p' "$ONT_FILT" > long_reads.fasta

"$TGS_GAPCLOSER" \
  --scaff "$SALSA_FASTA" --reads long_reads.fasta \
  --output "$OUT/tgs" --thread "$THREADS" \
  --racon "$(command -v racon)"
echo "Output: $OUT/tgs.scaff_seqs"
