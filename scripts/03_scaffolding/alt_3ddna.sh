#!/bin/bash
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=08:00:00
#SBATCH --job-name=3d_scaffold
#SBATCH --output=logs/3d-scaffold_%j.out
# ALTERNATIVE (exploratory, not used in the final assembly):
# Juicer + 3D-DNA Hi-C scaffolding of the Racon assembly.
set -euo pipefail
source "${SLURM_SUBMIT_DIR:-.}/config.sh"
setup_env 3ddna

JUICER_DIR="${PROJECT}/HiC_juicer_output/juicer_output"
FASTQ_DIR="${JUICER_DIR}/fastq"
PREFIX="${RACON_FASTA%.fasta}"
require_file "$RACON_FASTA"

python3 "${JUICER_BASE}/misc/generate_site_positions.py" MboI "$PREFIX" "$RACON_FASTA"
awk '/^>/{if(n)print n"\t"l; n=substr($1,2); l=0; next}{l+=length($0)}END{print n"\t"l}' \
    "$RACON_FASTA" > "${PREFIX}.chrom.sizes"
[ -f "${RACON_FASTA}.bwt" ] || bwa index "$RACON_FASTA"

mkdir -p "$FASTQ_DIR"
ln -sf "$HIC_R1" "$FASTQ_DIR/merged_R1.fastq.gz"
ln -sf "$HIC_R2" "$FASTQ_DIR/merged_R2.fastq.gz"

bash "${JUICER_BASE}/CPU/juicer.sh" \
    -g assembly_racon1 -s MboI \
    -z "$RACON_FASTA" -p "${PREFIX}.chrom.sizes" -y "${PREFIX}_MboI.txt" \
    -D "$JUICER_BASE" -t "$THREADS" -d "$JUICER_DIR"

cd "$JUICER_DIR"
"$DNA3D_PIPELINE" "$RACON_FASTA" "${JUICER_DIR}/aligned/merged_nodups.txt"
echo "3D-DNA finished"
