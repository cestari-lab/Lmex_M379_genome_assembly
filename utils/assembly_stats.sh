#!/bin/bash
# Quick assembly summary without QUAST: sequences, total length, N50, largest, Ns, gaps, GC.
# Usage: bash utils/assembly_stats.sh assembly.fasta
awk '/^>/{if(l)print l; l=0; next}{l+=length($0)}END{print l}' "$1" | sort -nr > .len.$$
awk -v f="$1" '{L[NR]=$1; t+=$1} END{
  h=t/2; c=0; for(i=1;i<=NR;i++){c+=L[i]; if(c>=h){n50=L[i]; l50=i; break}}
  printf "file\t%s\nsequences\t%d\ntotal_bp\t%d\nlargest\t%d\nN50\t%d\nL50\t%d\n", f, NR, t, L[1], n50, l50}' .len.$$
rm -f .len.$$
grep -v '^>' "$1" | tr -d '\n' | awk '{n=gsub(/[Nn]/,"&"); gc=gsub(/[GCgc]/,"&");
  printf "N_bases\t%d\nGC_percent\t%.2f\n", n, 100*gc/(length($0)-n)}'
printf "N_gaps\t%d\n" "$(awk -f "$(dirname "$0")/n_blocks.awk" "$1" | wc -l)"
