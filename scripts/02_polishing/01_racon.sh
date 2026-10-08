#!/bin/bash
#SBATCH --cpus-per-task=8
#SBATCH --mem=8G
#SBATCH --time=04:00:00
#SBATCH --job-name=racon_polish
#SBATCH --output=logs/racon_polish_%j.out
# One round of long-read polishing with Racon
set -euo pipefail
source "${SLURM_SUBMIT_DIR:-.}/config.sh"
setup_env racon

require_file "$ONT_FILT" "$FLYE_FASTA"
mkdir -p "$RACON_DIR"

minimap2 -x map-ont -t "$THREADS" "$FLYE_FASTA" "$ONT_FILT" > "$RACON_DIR/reads_to_contigs.paf"
racon -t "$THREADS" "$ONT_FILT" "$RACON_DIR/reads_to_contigs.paf" "$FLYE_FASTA" > "$RACON_FASTA"

echo "Racon polishing finished: $RACON_FASTA"
