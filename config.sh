#!/bin/bash
# =====================================================================
# Central configuration — every SLURM script sources this file.
# Submit all jobs FROM THE REPOSITORY ROOT, e.g.:
#     sbatch scripts/01_assembly/flye.sh
# Edit paths here once instead of in every script.
# =====================================================================

# ---- Project root (edit) -------------------------------------------
PROJECT="/path/to/project/L.mex_M379"
RAW="${PROJECT}/rawdata"

# ---- Raw reads ------------------------------------------------------
ONT_RAW="${RAW}/SRR20123517_1.fastq.gz"                       # ONT, PRJNA853937
ONT_FILT="${RAW}/SRR20123517_1_filtered_q7_len1000.fastq"     # NanoFilt q7 / 1 kb
ONT_CORR_DIR="${RAW}/ratatosk_corrected"                      # Ratatosk output
ILL_R1="${RAW}/SRR21208582_1.fastq.gz"                        # Illumina PE
ILL_R2="${RAW}/SRR21208582_2.fastq.gz"
HIC_R1="${RAW}/L.mex_M379_HiC_R1.fastq.gz"                     # 3 Hi-C reps merged
HIC_R2="${RAW}/L.mex_M379_HiC_R2.fastq.gz"
HIC_ENZYME="GATC"                                             # MboI

# ---- Reference (L. mexicana c9t7) -----------------------------------
REF_FULL="${PROJECT}/Genome/c9t7_sequences.fasta"
REF_CHR="${PROJECT}/Genome/c9t7_sequences.chromosomes_only.fasta"

# ---- Step output directories (match the original run) ---------------
NANOPLOT_DIR="${RAW}"
FLYE_DIR="${PROJECT}/output"
FLYE_FASTA="${FLYE_DIR}/L.mex_M927_flye.fasta"                # renamed assembly.fasta
RACON_DIR="${PROJECT}/racon_polish"
RACON_FASTA="${RACON_DIR}/assembly_racon1.fasta"
PILON_DIR="${PROJECT}/pilon_polish"
PILON_ROUNDS=4                                                # rounds of Illumina polishing
PILON_FOR_SCAFFOLDING="${PILON_DIR}/assembly_pilon3.fasta"    # round chosen for SALSA2
SALSA_DIR="${PROJECT}/salsa_output_optimized_pilon3"
SALSA_FASTA="${SALSA_DIR}/pilo3_salsa_scaffolds_FINAL.fasta"  # renamed scaffolds_FINAL.fasta
RAGTAG_DIR="${SALSA_DIR}/ragtag_output"
RAGTAG_FASTA="${RAGTAG_DIR}/ragtag.scaffold.fasta"
SEALER_DIR="${RAGTAG_DIR}/abyss_sealer"
SEALER_FASTA="${SEALER_DIR}/pilo3_salsa_scaffolds_sealer_scaffold.fa"
GAPFILL_DIR="${SEALER_DIR}/pilon_gapcloser"
GAPFILL_ROUNDS=3
FINAL_FASTA="${GAPFILL_DIR}/L.mexicana_m927_c9t7_2026.fasta"  # FINAL ASSEMBLY
QC_DIR="${PROJECT}/qc"
DEPTH_DIR="${PROJECT}/depth"
REPEAT_DIR="${GAPFILL_DIR}/Lmex_M379"
TRF_DIR="${GAPFILL_DIR}/trf"

# ---- Tools installed from source (edit) -----------------------------
SOFTWARE="/path/to/software"
SALSA_BIN="${SOFTWARE}/SALSA/run_pipeline.py"
JUICER_BASE="${SOFTWARE}/juicer"
DNA3D_PIPELINE="${SOFTWARE}/3d-dna/run-asm-pipeline.sh"
NGSEP_JAR="${SOFTWARE}/NGSEPcore.jar"
PILON_JAR_FALLBACK="${SOFTWARE}/pilon-1.24.jar"
RATATOSK_BIN="${SOFTWARE}/Ratatosk/build/src/Ratatosk"
LR_GAPCLOSER="${SOFTWARE}/LR_Gapcloser/src/LR_Gapcloser.sh"
TGS_GAPCLOSER="${SOFTWARE}/TGS-GapCloser/tgsgapcloser"

# ---- Software environment (edit for your system) --------------------
# Each script calls `setup_env <step>` before running its tools.
# By default nothing is loaded and every tool must already be on $PATH.
# Add your own `module load ...` or `conda activate ...` lines per step, e.g.
#     flye)   conda activate flye ;;
#     racon)  module load racon minimap2 ;;
setup_env() {
    case "$1" in
        nanoplot)      : ;;   # NanoPlot, NanoFilt
        flye)          : ;;   # Flye
        racon)         : ;;   # Racon, minimap2
        pilon)         : ;;   # BWA, SAMtools, Java 17, Pilon
        salsa2)        : ;;   # SALSA2 (python 2.7), BWA, SAMtools, bedtools
        3ddna)         : ;;   # Java, BWA, SAMtools, Juicer, 3D-DNA
        ngsep)         : ;;   # Java 21, NGSEP
        ragtag)        : ;;   # RagTag, minimap2, seqtk
        sealer)        : ;;   # ABySS (abyss-sealer)
        ratatosk)      : ;;   # Ratatosk
        lr_gapcloser)  : ;;   # LR_Gapcloser
        tgs_gapcloser) : ;;   # TGS-GapCloser, Racon
        busco)         : ;;   # BUSCO 5, fastANI
        mapping)       : ;;   # BWA, SAMtools, bedtools
        repeats)       : ;;   # RepeatModeler 2, RepeatMasker 4
        trf)           : ;;   # TRF
    esac
}

# ---- Helpers ---------------------------------------------------------
THREADS="${SLURM_CPUS_PER_TASK:-4}"

# Find a Pilon jar in the active conda env, else use the fallback path
find_pilon_jar() {
    local jar=""
    if [ -n "${CONDA_PREFIX:-}" ]; then
        jar="$(find "$CONDA_PREFIX" -maxdepth 5 -type f -name 'pilon*.jar' -print -quit 2>/dev/null || true)"
    fi
    jar="${jar:-$PILON_JAR_FALLBACK}"
    [ -f "$jar" ] || { echo "ERROR: Pilon jar not found ($jar)" >&2; return 1; }
    echo "$jar"
}

require_file() {
    for f in "$@"; do
        [ -s "$f" ] || { echo "ERROR: required file missing or empty: $f" >&2; exit 1; }
    done
}
