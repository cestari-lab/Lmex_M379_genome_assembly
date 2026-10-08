#!/bin/bash
#SBATCH --cpus-per-task=4
#SBATCH --mem=18G
#SBATCH --time=4:00:00
#SBATCH --job-name=ngsep_sort
#SBATCH --output=logs/ngsep_sort_%j.out
# Sort / orient SALSA2 scaffolds against the c9t7 reference (NGSEP AssemblyReferenceSorter)
# Used for synteny visualisation and as the fastANI comparison target.
set -euo pipefail
source "${SLURM_SUBMIT_DIR:-.}/config.sh"
setup_env ngsep

require_file "$REF_FULL" "$SALSA_FASTA" "$NGSEP_JAR"
OUTPUT="${SALSA_FASTA%.*}_genome_sorted.fasta"

java -jar "$NGSEP_JAR" AssemblyReferenceSorter \
  -i "$SALSA_FASTA" -r "$REF_FULL" -o "$OUTPUT" -rcp 2

echo "Sorted assembly: $OUTPUT"
