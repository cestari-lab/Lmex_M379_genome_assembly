#!/bin/bash
#SBATCH --cpus-per-task=16
#SBATCH --mem=120G
#SBATCH --time=24:00:00
#SBATCH --job-name=pilon_gapfill
#SBATCH --output=logs/pilon_gapfill_%j.out
# Final Pilon rounds on the Sealer output (polishing + local gap filling).
# Last round is copied to $FINAL_FASTA (the released assembly).
set -euo pipefail
source "${SLURM_SUBMIT_DIR:-.}/config.sh"
unset JAVA_TOOL_OPTIONS _JAVA_OPTIONS
setup_env pilon

PILON_JAR="$(find_pilon_jar)"
require_file "$SEALER_FASTA" "$ILL_R1" "$ILL_R2"
mkdir -p "$GAPFILL_DIR"; cd "$GAPFILL_DIR"

CURRENT="$SEALER_FASTA"
for i in $(seq 1 "$GAPFILL_ROUNDS"); do
    echo "=== Pilon gap-fill round $i : $(date)"
    BAM="$GAPFILL_DIR/illumina_vs_round${i}.sorted.bam"
    if [ ! -s "$BAM" ]; then
        bwa index "$CURRENT"
        bwa mem -t "$THREADS" "$CURRENT" "$ILL_R1" "$ILL_R2" \
            | samtools sort -@ "$THREADS" -o "$BAM" -
        samtools index "$BAM"
    fi
    java -Xmx96G -jar "$PILON_JAR" \
        --genome "$CURRENT" --frags "$BAM" \
        --output "pilon_round${i}" --outdir "$GAPFILL_DIR" \
        --changes --vcf --verbose --threads "$THREADS"
    CURRENT="$GAPFILL_DIR/pilon_round${i}.fasta"
    echo "Round $i changes: $(wc -l < "pilon_round${i}.changes")"
done

# Pilon appends "_pilon" to every header each round; strip it for the release
sed -E '/^>/ s/(_pilon)+$//' "$CURRENT" > "$FINAL_FASTA"
echo "Final assembly: $FINAL_FASTA"
