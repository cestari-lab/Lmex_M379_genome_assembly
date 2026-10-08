#!/bin/bash
#SBATCH --cpus-per-task=32
#SBATCH --mem=48G
#SBATCH --time=60:00:00
#SBATCH --job-name=salsa_scaffold
#SBATCH --output=logs/salsa_scaffold_%j.out
# Hi-C scaffolding with SALSA2 (all three Hi-C replicates merged)
# Input: Pilon round-3 assembly
set -euo pipefail
source "${SLURM_SUBMIT_DIR:-.}/config.sh"
setup_env salsa2

ASSEMBLY="$PILON_FOR_SCAFFOLDING"
require_file "$ASSEMBLY" "$HIC_R1" "$HIC_R2"
mkdir -p "$SALSA_DIR"

[ -f "${ASSEMBLY}.bwt" ] || bwa index "$ASSEMBLY"
[ -f "${ASSEMBLY}.fai" ] || samtools faidx "$ASSEMBLY"

# -5SP: Hi-C aware mapping; -F 3844: drop unmapped/secondary/QC-fail/dup/supplementary; MAPQ>=10
bwa mem -5SP -t "$THREADS" "$ASSEMBLY" "$HIC_R1" "$HIC_R2" \
  | samtools view -@ "$THREADS" -F 3844 -q 10 -u - \
  | samtools sort -@ "$THREADS" -n -o "$SALSA_DIR/hic_mapped_sorted.bam"

bedtools bamtobed -i "$SALSA_DIR/hic_mapped_sorted.bam" > "$SALSA_DIR/hic_reads.bed"

# -m yes: mis-assembly detection (important for repeat-rich Leishmania regions)
python "$SALSA_BIN" \
  -a "$ASSEMBLY" -l "${ASSEMBLY}.fai" \
  -b "$SALSA_DIR/hic_reads.bed" \
  -e "$HIC_ENZYME" -m yes -o "$SALSA_DIR"

cp "$SALSA_DIR/scaffolds_FINAL.fasta" "$SALSA_FASTA"
echo "SALSA2 finished: $SALSA_FASTA"
