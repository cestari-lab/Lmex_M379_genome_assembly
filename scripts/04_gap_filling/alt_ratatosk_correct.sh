#!/bin/bash
#SBATCH --cpus-per-task=16
#SBATCH --mem=120G
#SBATCH --time=24:00:00
#SBATCH --job-name=ratatosk_correct
#SBATCH --output=logs/ratatosk_%j.out
# ALTERNATIVE (exploratory): hybrid correction of ONT reads with Illumina (Ratatosk),
# used as input for LR_Gapcloser.
set -euo pipefail
source "${SLURM_SUBMIT_DIR:-.}/config.sh"
setup_env ratatosk

require_file "$ILL_R1" "$ILL_R2" "$ONT_FILT"
mkdir -p "$ONT_CORR_DIR"

"$RATATOSK_BIN" correct -c "$THREADS" \
  -s "$ILL_R1" "$ILL_R2" -l "$ONT_FILT" -o "$ONT_CORR_DIR/ont"

# FASTQ -> FASTA for LR_Gapcloser
sed -n '1~4s/^@/>/p;2~4p' "$ONT_CORR_DIR/ont.fastq" > "$ONT_CORR_DIR/ont.fasta"
echo "Corrected reads: $ONT_CORR_DIR/ont.fastq (+ .fasta)"
