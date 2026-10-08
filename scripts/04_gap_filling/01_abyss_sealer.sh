#!/bin/bash
#SBATCH --cpus-per-task=16
#SBATCH --mem=120G
#SBATCH --time=24:00:00
#SBATCH --job-name=abyss_sealer
#SBATCH --output=logs/abyss_sealer_%j.out
# Illumina k-mer gap closing of the RagTag scaffolds with ABySS-Sealer (k = 60, 80, 100)
set -euo pipefail
source "${SLURM_SUBMIT_DIR:-.}/config.sh"
setup_env sealer

require_file "$RAGTAG_FASTA" "$ILL_R1" "$ILL_R2"
command -v abyss-sealer >/dev/null
mkdir -p "$SEALER_DIR"; cd "$SEALER_DIR"

abyss-sealer \
  -S "$RAGTAG_FASTA" \
  -b 40G -k 60 -k 80 -k 100 -j "$THREADS" \
  -o pilo3_salsa_scaffolds_sealer \
  "$ILL_R1" "$ILL_R2"

count_n() { grep -v '^>' "$1" | tr -cd 'Nn' | wc -c; }
echo "N bases before: $(count_n "$RAGTAG_FASTA")"
echo "N bases after:  $(count_n "$SEALER_FASTA")"
