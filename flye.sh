#!/bin/bash
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=1-00:00:00
#SBATCH --job-name=flye_assembly
#SBATCH --output=logs/flye_assembly_%j.out
# De novo long-read assembly with Flye (ONT raw reads)
set -euo pipefail
source "${SLURM_SUBMIT_DIR:-.}/config.sh"
setup_env flye

require_file "$ONT_FILT"
flye --nano-raw "$ONT_FILT" --out-dir "$FLYE_DIR" --threads "$THREADS"

cp "$FLYE_DIR/assembly.fasta" "$FLYE_FASTA"
echo "Flye assembly finished: $FLYE_FASTA"
