#!/bin/bash
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --job-name=pilon_polish
#SBATCH --output=logs/pilon_polish_%j.out
# Iterative short-read polishing of the Racon assembly with Pilon.
# Reads are re-mapped to the newest assembly every round.
# Output: assembly_pilon{1..N}.fasta ; round 3 was used for scaffolding.
set -euo pipefail
source "${SLURM_SUBMIT_DIR:-.}/config.sh"
unset JAVA_TOOL_OPTIONS _JAVA_OPTIONS
setup_env pilon

PILON_JAR="$(find_pilon_jar)"
require_file "$RACON_FASTA" "$ILL_R1" "$ILL_R2"
mkdir -p "$PILON_DIR"; cd "$PILON_DIR"

CURRENT="$RACON_FASTA"
for i in $(seq 1 "$PILON_ROUNDS"); do
    echo "=== Pilon polishing round $i : $(date)"
    BAM="$PILON_DIR/illumina_round${i}.sorted.bam"
    bwa index "$CURRENT"
    bwa mem -t "$THREADS" "$CURRENT" "$ILL_R1" "$ILL_R2" \
        | samtools sort -@ "$THREADS" -o "$BAM" -
    samtools index "$BAM"

    java -Xmx60G -jar "$PILON_JAR" \
        --genome "$CURRENT" --frags "$BAM" \
        --output "assembly_pilon${i}" --outdir "$PILON_DIR" \
        --changes --vcf --threads "$THREADS"

    CURRENT="$PILON_DIR/assembly_pilon${i}.fasta"
    echo "Round $i changes: $(wc -l < "$PILON_DIR/assembly_pilon${i}.changes")"
done
echo "Pilon polishing finished. Last round: $CURRENT"
