#!/bin/bash
# Submit the main (final-assembly) pipeline as a chain of dependent SLURM jobs.
# Run from the repository root:  bash run_pipeline.sh
# Start from a later step:       bash run_pipeline.sh 5    (skips steps 1-4)
set -euo pipefail
mkdir -p logs
START="${1:-1}"

STEPS=(
  scripts/00_read_qc/01_nanoplot_filter.sh       # 1
  scripts/01_assembly/flye.sh                    # 2
  scripts/02_polishing/01_racon.sh               # 3
  scripts/02_polishing/02_pilon_rounds.sh        # 4
  scripts/03_scaffolding/01_salsa2.sh            # 5
  scripts/03_scaffolding/02_ngsep_sort.sh        # 6
  scripts/03_scaffolding/03_ragtag.sh            # 7
  scripts/04_gap_filling/01_abyss_sealer.sh      # 8
  scripts/04_gap_filling/02_pilon_gapfill.sh     # 9
  scripts/06_repeats/01_repeatmodeler_masker.sh  # 10
  scripts/06_repeats/02_trf.sh                   # 11 (runs in parallel with 10)
)

prev=""; last_gapfill=""
for i in "${!STEPS[@]}"; do
  n=$((i+1)); [ "$n" -lt "$START" ] && continue
  s="${STEPS[$i]}"
  dep=""
  if [ "$n" -eq 11 ] && [ -n "$last_gapfill" ]; then dep="--dependency=afterok:${last_gapfill}"
  elif [ -n "$prev" ]; then dep="--dependency=afterok:${prev}"; fi
  id=$(sbatch --parsable $dep "$s")
  echo "Step $n  job $id  $s"
  [ "$n" -eq 9 ] && last_gapfill="$id"
  [ "$n" -ne 11 ] && prev="$id"
done
