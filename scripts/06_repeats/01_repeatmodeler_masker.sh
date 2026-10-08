#!/bin/bash
#SBATCH --cpus-per-task=16
#SBATCH --mem=120G
#SBATCH --time=24:00:00
#SBATCH --job-name=repeats
#SBATCH --output=logs/repeats_%j.out
# De novo repeat library (RepeatModeler 2 + LTRStruct) and soft-masking (RepeatMasker)
# of the final assembly.
set -euo pipefail
source "${SLURM_SUBMIT_DIR:-.}/config.sh"
setup_env repeats

DB=Lmex_M379
require_file "$FINAL_FASTA"
mkdir -p "$REPEAT_DIR"; cd "$REPEAT_DIR"

# 1. Build the database (written to the current directory)
BuildDatabase -name "$DB" "$FINAL_FASTA"

# 2. Repeat discovery; -LTRStruct adds the LTR structural pipeline (retrotransposons)
RepeatModeler -database "$DB" -threads "$THREADS" -LTRStruct

# 3. Soft-mask the genome with the custom library
LIB="${DB}-families.fa"
require_file "$LIB"
RepeatMasker -threads "$THREADS" \
             -lib "$LIB" \
             -xsmall \
             -gff \
             -dir "$REPEAT_DIR" \
             "$FINAL_FASTA"

echo "Done. Summary table: $REPEAT_DIR/$(basename "$FINAL_FASTA").tbl"
