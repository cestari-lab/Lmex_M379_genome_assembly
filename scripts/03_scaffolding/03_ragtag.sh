#!/bin/bash
#SBATCH --cpus-per-task=16
#SBATCH --mem=60G
#SBATCH --time=24:00:00
#SBATCH --job-name=ragtag
#SBATCH --output=logs/ragtag_%j.out
# Reference-guided scaffolding of SALSA2 scaffolds onto the 34 c9t7 chromosomes.
# RagTag orders/orients scaffolds, joins them with 100 N, and names them LmxM379c.XX_RagTag.
set -euo pipefail
source "${SLURM_SUBMIT_DIR:-.}/config.sh"
setup_env ragtag

require_file "$REF_FULL" "$SALSA_FASTA"

# Build the chromosomes-only reference (drop unplaced contigs) if missing
if [ ! -s "$REF_CHR" ]; then
    grep ">LmxM379c" "$REF_FULL" | sed 's/>//; s/ .*//' > "$(dirname "$REF_CHR")/chrom_list.txt"
    seqtk subseq "$REF_FULL" "$(dirname "$REF_CHR")/chrom_list.txt" > "$REF_CHR"
fi

ragtag.py scaffold -t "$THREADS" -o "$RAGTAG_DIR" "$REF_CHR" "$SALSA_FASTA"
echo "RagTag finished: $RAGTAG_FASTA"
