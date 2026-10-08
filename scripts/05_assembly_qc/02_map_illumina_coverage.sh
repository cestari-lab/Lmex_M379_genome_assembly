#!/bin/bash
#SBATCH --cpus-per-task=16
#SBATCH --mem=40G
#SBATCH --time=24:00:00
#SBATCH --job-name=map_coverage
#SBATCH --output=logs/map_coverage_%j.out
# Map Illumina reads back to the assembly; flagstat, breadth of coverage,
# N-gap table and zero-coverage regions (> 100 bp) for plotting with R/plot_gaps_vs_coverage.R
# Usage: ASM=/path/to.fasta sbatch ...   (default: Sealer output)
set -euo pipefail
source "${SLURM_SUBMIT_DIR:-.}/config.sh"
setup_env mapping

ASM="${ASM:-$SEALER_FASTA}"
require_file "$ASM" "$ILL_R1" "$ILL_R2"
cd "$(dirname "$ASM")"
BAM="C9T7_micepre.sorted.bam"
REPO="${SLURM_SUBMIT_DIR:-.}"

bwa index "$ASM"
samtools faidx "$ASM"
bwa mem -t "$THREADS" "$ASM" "$ILL_R1" "$ILL_R2" | samtools sort -@ "$THREADS" -o "$BAM" -
samtools index "$BAM"
samtools flagstat "$BAM" > "${BAM%.bam}.flagstat.txt"

# Breadth of coverage (% of bases with depth >= 1)
samtools depth -a "$BAM" | awk '{t++; if($3>0)c++} END{printf "Breadth of coverage: %.4f%%\n", 100*c/t}' \
    | tee breadth_of_coverage.txt

# Tables for plotting
cut -f1,2 "${ASM}.fai" > scaffold_lengths.tsv
awk -f "$REPO/utils/n_blocks.awk" "$ASM" > N_blocks.tsv
grep -v '^>' "$ASM" | tr -d '\n' | grep -o '[Nn]\+' | awk '{print length($0)}' > gap_sizes.txt || true
genomeCoverageBed -ibam "$BAM" -bga | awk '$4==0' > uncovered_regions.bed
awk '($3-$2) > 100 {print $1"\t"$2"\t"$3"\t"($3-$2)}' uncovered_regions.bed > uncovered_blocks.tsv
echo "Done. Now run the R scripts in $(pwd)"
