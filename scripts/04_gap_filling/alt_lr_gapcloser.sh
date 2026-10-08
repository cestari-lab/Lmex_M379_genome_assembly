#!/bin/bash
#SBATCH --cpus-per-task=16
#SBATCH --mem=120G
#SBATCH --time=24:00:00
#SBATCH --job-name=LR_gapclose
#SBATCH --output=logs/LR_gapclose_%j.out
# ALTERNATIVE (exploratory): long-read gap closing of SALSA2 scaffolds with LR_Gapcloser.
# Usage:  sbatch scripts/04_gap_filling/alt_lr_gapcloser.sh            # filtered ONT reads
#         READS=corrected sbatch scripts/04_gap_filling/alt_lr_gapcloser.sh   # Ratatosk reads
set -euo pipefail
source "${SLURM_SUBMIT_DIR:-.}/config.sh"
setup_env lr_gapcloser

if [ "${READS:-raw}" = "corrected" ]; then
    LONG="$ONT_CORR_DIR/ont.fasta"; OUT="$SALSA_DIR/LR_closer_ratatosk"
else
    LONG="$ONT_FILT";               OUT="$SALSA_DIR/LR_closer"
fi
require_file "$SALSA_FASTA" "$LONG"
mkdir -p "$OUT"

"$LR_GAPCLOSER" -i "$SALSA_FASTA" -l "$LONG" -s n -t "$THREADS" -o "$OUT"
echo "LR_Gapcloser finished: $OUT"
