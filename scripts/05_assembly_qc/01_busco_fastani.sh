#!/bin/bash
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=06:00:00
#SBATCH --job-name=busco_fastani
#SBATCH --output=logs/busco_fastani_%j.out
# Completeness (BUSCO 5, euglenozoa_odb10) and identity to reference (fastANI)
# Usage: ASM=/path/to.fasta sbatch scripts/05_assembly_qc/01_busco_fastani.sh  (default: RagTag)
set -euo pipefail
source "${SLURM_SUBMIT_DIR:-.}/config.sh"
setup_env busco

ASM="${ASM:-$RAGTAG_FASTA}"
require_file "$ASM"
mkdir -p "$QC_DIR"; cd "$QC_DIR"
NAME="$(basename "${ASM%.*}")"

busco -i "$ASM" -o "busco_${NAME}" -m genome -l euglenozoa_odb10 --cpu "$THREADS"

for REF in "${SALSA_FASTA%.*}_genome_sorted.fasta" "$REF_CHR" "$REF_FULL"; do
    [ -s "$REF" ] || continue
    fastANI -q "$ASM" -r "$REF" -t "$THREADS" -o "fastani_${NAME}_vs_$(basename "${REF%.*}").txt"
done
cat fastani_"${NAME}"_vs_*.txt
