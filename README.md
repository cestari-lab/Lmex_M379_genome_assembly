# *Leishmania mexicana* M379 — chromosome-level genome assembly (2026)

Scripts and documentation for a chromosome-scale assembly of *Leishmania mexicana*
(MNYC/BZ/62/M379) built from Oxford Nanopore long reads, Illumina short reads and Hi-C,
then ordered against the *L. mexicana* c9t7 reference and annotated for repeats.

Cestari Lab · McGill University · Lissa Cruz-Saavedra

---

## Pipeline

```
ONT reads (SRR20123517) ──NanoPlot/NanoFilt (Q≥7, ≥1 kb)
        │
        ▼
     Flye  ──►  Racon ×1 (ONT)  ──►  Pilon ×4 (Illumina SRR21208582)
                                            │  round 3
                                            ▼
                         SALSA2 (Hi-C, MboI, mis-assembly correction)
                                            │
                                            ▼
                  RagTag scaffold onto c9t7 chromosomes (34 chr)
                                            │
                                            ▼
                  ABySS-Sealer (k 60/80/100)  ──►  Pilon gap filling ×3
                                            │
                                            ▼
                         FINAL: L.mexicana_m927_c9t7_2026.fasta
                                            │
              ┌─────────────────────────────┼──────────────────────────┐
              ▼                             ▼                          ▼
   BUSCO · fastANI · coverage     RepeatModeler + RepeatMasker      TRF
```

## Repository layout

```
config.sh                       ← all paths, read files and software locations (edit this)
run_pipeline.sh                 ← submits the main pipeline as dependent SLURM jobs
scripts/
  00_read_qc/01_nanoplot_filter.sh
  01_assembly/flye.sh
  02_polishing/01_racon.sh
  02_polishing/02_pilon_rounds.sh
  03_scaffolding/01_salsa2.sh
  03_scaffolding/02_ngsep_sort.sh
  03_scaffolding/03_ragtag.sh
  03_scaffolding/alt_3ddna.sh             (exploratory, not in final assembly)
  04_gap_filling/01_abyss_sealer.sh
  04_gap_filling/02_pilon_gapfill.sh
  04_gap_filling/alt_ratatosk_correct.sh  (exploratory)
  04_gap_filling/alt_lr_gapcloser.sh      (exploratory)
  04_gap_filling/alt_tgs_gapcloser.sh     (exploratory, no output)
  05_assembly_qc/01_busco_fastani.sh
  05_assembly_qc/02_map_illumina_coverage.sh
  05_assembly_qc/03_depth_windows.sh
  06_repeats/01_repeatmodeler_masker.sh
  06_repeats/02_trf.sh
utils/                          ← assembly_stats.sh
envs/                           ← software versions, conda environment
```

## Usage

All scripts read paths from `config.sh` and must be submitted **from the repository root**
(they locate the config through `$SLURM_SUBMIT_DIR`).

```bash
git clone https://github.com/<user>/Lmex_M379_genome_assembly.git
cd Lmex_M379_genome_assembly
nano config.sh                       # check PROJECT and read paths
mkdir -p logs

# whole pipeline as a chain of dependent jobs
bash run_pipeline.sh
# …or resume from a given step (e.g. 10 = repeats only)
bash run_pipeline.sh 10

# or single steps
sbatch scripts/06_repeats/01_repeatmodeler_masker.sh
sbatch scripts/06_repeats/02_trf.sh

# QC on any assembly
ASM=/path/to/assembly.fasta sbatch scripts/05_assembly_qc/01_busco_fastani.sh
bash utils/assembly_stats.sh /path/to/assembly.fasta


```

## Data

| Data | Accession / file |
|---|---|
| ONT long reads | SRR20123517 — BioProject [PRJNA853937](https://www.ebi.ac.uk/ena/browser/view/PRJNA853937) |
| Illumina paired-end | SRR21208582 |
| Hi-C (3 replicates merged, MboI) | `L.mex_M379_HiC_R1/R2.fastq.gz` (lab data) |
| Reference | *L. mexicana* c9t7 (`c9t7_sequences.fasta`) |

Sequence data and assemblies are not stored in this repository (see `.gitignore`).

## Requirements

SLURM cluster with Lmod modules (Alliance Canada `StdEnv/2023`), conda, Java 17/21, R ≥ 4.2
with `tidyverse` and `scales`. Tool versions: [`envs/software_versions.md`](envs/software_versions.md).
