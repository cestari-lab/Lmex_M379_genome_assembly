#!/bin/bash
#SBATCH --cpus-per-task=12
#SBATCH --mem-per-cpu=6G
#SBATCH --time=0-24:00
#SBATCH --job-name=Leishmania_depth_C9T7
#SBATCH --output=logs/depth_%j.out
# Per-chromosome read depth (MAPQ>=30, primary alignments) in 1 kb windows
# -> used for chromosome copy-number (somy) estimation.
set -euo pipefail
source "${SLURM_SUBMIT_DIR:-.}/config.sh"
setup_env mapping

BAM="${BAM:-$(dirname "$SEALER_FASTA")/C9T7_micepre.sorted.bam}"
WINDOW="${WINDOW:-1000}"
require_file "$BAM"
mkdir -p "$DEPTH_DIR"

prefix="$(basename "$BAM" .bam)"
FILT="$DEPTH_DIR/${prefix}.q30.primary.sorted.bam"

# MAPQ>=30, drop secondary (0x100) + supplementary (0x800)
samtools view -b -@ "$THREADS" -q 30 -F 2304 "$BAM" | samtools sort -@ "$THREADS" -o "$FILT" -
samtools index "$FILT"

samtools depth -a "$FILT" > "$DEPTH_DIR/${prefix}_depth_all.txt"

# Mean depth per chromosome and per window (chromosome names taken from the BAM header,
# e.g. LmxM379c.01_RagTag ... LmxM379c.34_RagTag)
awk -v w="$WINDOW" -v out="$DEPTH_DIR/${prefix}" -F'\t' '
  { bin = int(($2-1)/w)*w + 1; key = $1"\t"bin; s[key]+=$3; n[key]++;
    cs[$1]+=$3; cn[$1]++; if(!($1 in seen)){seen[$1]=1; order[++k]=$1} }
  END {
    for(i=1;i<=k;i++) printf "%s\t%.4f\n", order[i], cs[order[i]]/cn[order[i]] > (out"_chrom_mean_depth.tsv")
    for(key in s) printf "%s\t%.4f\n", key, s[key]/n[key] > (out"_window" w "_depth.unsorted.tsv")
  }' "$DEPTH_DIR/${prefix}_depth_all.txt"

sort -k1,1V -k2,2n "$DEPTH_DIR/${prefix}_window${WINDOW}_depth.unsorted.tsv" \
    > "$DEPTH_DIR/${prefix}_window${WINDOW}_depth.tsv"
rm "$DEPTH_DIR/${prefix}_window${WINDOW}_depth.unsorted.tsv"

# Somy estimate: chromosome depth / median chromosome depth x 2
sort -k2,2n "$DEPTH_DIR/${prefix}_chrom_mean_depth.tsv" | awk '{d[NR]=$2; c[NR]=$1}
  END{m=(NR%2)?d[(NR+1)/2]:(d[NR/2]+d[NR/2+1])/2;
      for(i=1;i<=NR;i++) printf "%s\t%.2f\t%.2f\n", c[i], d[i], 2*d[i]/m}' \
  | sort -k1,1V > "$DEPTH_DIR/${prefix}_somy.tsv"
echo "Outputs in $DEPTH_DIR"
