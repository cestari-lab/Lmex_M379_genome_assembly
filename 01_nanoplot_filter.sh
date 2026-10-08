#!/bin/bash
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=06:00:00
#SBATCH --job-name=nanoplot_filter
#SBATCH --output=logs/nanoplot_filter_%j.out
# ONT read QC (NanoPlot) -> filtering (NanoFilt q>=7, length>=1 kb) -> QC again
set -euo pipefail
source "${SLURM_SUBMIT_DIR:-.}/config.sh"
setup_env nanoplot

require_file "$ONT_RAW"
cd "$RAW"

NanoPlot --fastq "$ONT_RAW" -o "$(basename "$ONT_RAW" .fastq.gz)" -t "$THREADS"

zcat "$ONT_RAW" | NanoFilt -q 7 -l 1000 > "$ONT_FILT"

NanoPlot --fastq "$ONT_FILT" -o "$(basename "$ONT_FILT" .fastq)" -t "$THREADS"
echo "Filtered reads: $ONT_FILT"
