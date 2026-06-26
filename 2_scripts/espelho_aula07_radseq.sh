#!/bin/bash
# =============================================================================
# AULA 07 — RAD-seq & SNP Calling com Stacks
# Disciplina: CHS0007 Bioinformática — PPGSIS/UFC 2026.1
# Dataset: Hohenlohe et al. 2010 (PLoS Genetics) — Gasterosteus aculeatus
#          SRR034310 — 16 amostras, 2 populações (Bear Paw e Rabbit Slough)
# =============================================================================
# NOTA: Este espelho é um roteiro de codificação ao vivo — não executar como script.
# Cada comando é digitado junto com os alunos após a explicação conceitual.
# =============================================================================

cd 1_dados/aula_07_radseq/

# -----------------------------------------------------------------------------
# ESTRUTURA DE DIRETÓRIOS
# -----------------------------------------------------------------------------

ls
mkdir 1_seqs/   2_demux/   3_fastqc/   4_stacks/

# ----------------------------------------------------------------------------
# MÓDULO 1 — DOWNLOAD DOS DADOS
# -----------------------------------------------------------------------------

# O dataset SRR034310 contém reads de RAD-seq single-end (36bp)
# de 16 indivíduos de Gasterosteus aculeatus em 2 populações:
#   - Bear Paw (água doce, Alaska)
#   - Rabbit Slough (oceânico, Alaska)

# Baixar reads brutos multiplexados do SRA
fasterq-dump SRR034310 \
    --outdir 1_seqs \
    --threads 2 \
    --progress

# Baixar metadados com barcodes e nomes das amostras
wget https://zenodo.org/record/1134547/files/Details_Barcode_Population_SRR034310.txt \
    -O Details_Barcode_Population_SRR034310.txt

# Verificar o arquivo de metadados
head Details_Barcode_Population_SRR034310.txt
# formato: barcode  população  número  accession



# -----------------------------------------------------------------------------
# MÓDULO 2 — DEMULTIPLEXAÇÃO COM process_radtags
# -----------------------------------------------------------------------------

# O process_radtags aceita arquivo de barcodes com 2 colunas:
#   barcode <tab> nome_da_amostra
# Vamos gerar esse arquivo a partir dos metadados

awk '{print $1"\t"$2"_"$3"_"$4}' Details_Barcode_Population_SRR034310.txt > 1_seqs/barcodes_named.txt

# Verificar
head 1_seqs/barcodes_named.txt

# Verificar (tabs corretos = ^I)
cat -A 1_seqs/barcodes_named.txt
# CCCC^IBear_Paw_1$
# CCAA^IBear_Paw_2$
# ...

# Demultiplexar — enzima SbfI (CCTGCA^GG)
process_radtags \
    -f 1_seqs/SRR034310.fastq \
    -o 2_demux \
    -b 1_seqs/barcodes_named.txt \
    -e sbfI \
    -r -c -q \
    --len-limit 30 \
    2>&1 | tee 2_demux/process_radtags.log

# process_radtags is done.
# 8895289 total sequences
# 87.7% retained reads → Bear_Paw_1.fq, Bear_Paw_2.fq ... Rabbit_Slough_8.fq

# Ver reads por amostra
rm

# -----------------------------------------------------------------------------
# MÓDULO 3 — CONTROLE DE QUALIDADE
# -----------------------------------------------------------------------------

# FastQC em uma amostra representativa
fastqc 2_demux/Bear_Paw_6.fq \
       2_demux/Rabbit_Slough_5.fq \
       -o 3_fastqc \
       --threads 2

# MultiQC para visão geral
multiqc 3_fastqc -o 3_fastqc

# -----------------------------------------------------------------------------
# MÓDULO 4 — SUBSAMPLE (para viabilizar execução no Codespace)
# -----------------------------------------------------------------------------

# Instalar seqtk (se necessário)
mamba install -y -n bioinfo -c bioconda seqtk

# Subsample com seed reprodutível — 50.000 reads por amostra
mkdir -p 2_demux_sub

for f in 2_demux/Bear_Paw_*.fq 2_demux/Rabbit_Slough_*.fq; do
    sample=$(basename $f)
    echo "Subsampling $sample..."
    seqtk sample -s 42 $f 50000 > 2_demux_sub/$sample
done

# Verificar contagens
for f in 2_demux_sub/*.fq; do
    echo -n "$(basename $f): "
    awk 'END{print NR/4}' $f
done
# todas as amostras: 50000

# -----------------------------------------------------------------------------
# MÓDULO 5 — PIPELINE STACKS (denovo_map.pl)
# -----------------------------------------------------------------------------
nano 1_seqs/popmap.txt
# digitar:
# Bear_Paw_1    Bear_Paw   (tab entre colunas)
# Bear_Paw_2    Bear_Paw
# ...
# Rabbit_Slough_8   Rabbit_Slough

# Verificar tabs e conteúdo
cat -A 1_seqs/popmap.txt | head -3
# Bear_Paw_1^IBear_Paw$
# O popmap associa cada amostra à sua população
cat 1_seqs/popmap.txt
# Bear_Paw_1    Bear_Paw
# Bear_Paw_2    Bear_Paw
# ...
# Rabbit_Slough_8   Rabbit_Slough

# NOTA IMPORTANTE sobre o parâmetro --kmer-length:
# O gstacks usa kmer padrão de 31bp para montar contigs.
# Com reads de 36bp (dataset antigo), sobram apenas 5bp de margem — insuficiente.
# Solução: reduzir o kmer para 15 via -X "gstacks:--kmer-length 15"

# Rodar o pipeline completo
denovo_map.pl \
    -M 2 \
    -n 1 \
    -T 2 \
    --samples 2_demux_sub \
    --popmap 1_seqs/popmap_completo.txt \
    -o 4_stacks \
    -X "gstacks:--kmer-length 15" \
    2>&1 | tee 4_stacks/denovo_map.log

# denovo_map.pl is done.
# O wrapper executa sequencialmente:
#   1. ustacks  — monta loci de cada amostra individualmente
#   2. cstacks  — constrói catálogo de loci da metapopulação
#   3. sstacks  — mapeia amostras contra o catálogo
#   4. tsv2bam  — reorganiza dados por locus (por-amostra → por-locus)
#   5. gstacks  — genotyping: chama SNPs e haplótipos
#   6. populations — estatísticas populacionais

# Ver cobertura das amostras
grep "loci assembled" 4_stacks/denovo_map.log
# Bear_Paw_6; loci assembled: ~2600; depth: ~4.5x

# -----------------------------------------------------------------------------
# MÓDULO 6 — populations SEPARADO (controle explícito de filtros)
# -----------------------------------------------------------------------------

# Rodar populations com filtros para análise exploratória
# -r 0.8 → locus presente em ≥80% dos indivíduos por população
# --vcf  → gera arquivo VCF com os SNPs

populations \
    -P 4_stacks \
    --popmap 1_seqs/popmap_completo.txt \
    -O 4_stacks/populations_res_final \
    --threads 2 \
    -r 0.5 \
    -p 2 \
    --min-maf 0.05 \
    --max-obs-het 0.80 \
    --write-single-snp \
    --fstats \
    --vcf \
    --plink \
    --genepop \
    2>&1 | tee 4_stacks/populations_final_r80.log

# Ver resumo
tail -20 4_stacks/populations_r80.log

# Arquivos gerados:
ls -lh 4_stacks/populations*
# populations.snps.vcf    → SNPs em formato VCF
# populations.sumstats.tsv → diversidade por locus por população
# populations.hapstats.tsv → estatísticas de haplótipos
# populations.fst_summary.tsv → diferenciação entre populações (se ≥2 pops)

# Ver primeiros SNPs
grep -v "^#" 4_stacks/populations.snps.vcf | head -5

# Estatísticas de diversidade
head -5 4_stacks/populations.sumstats_summary.tsv

# =============================================================================
# RESUMO DO PIPELINE
# =============================================================================
# process_radtags → demultiplexação + QC das reads
# seqtk sample    → subsample reprodutível (seed 42, 50k reads)
# denovo_map.pl   → ustacks + cstacks + sstacks + tsv2bam + gstacks
# populations     → filtros + estatísticas + outputs (VCF, sumstats)
#
# Parâmetros-chave:
#   -M 2           → mismatches dentro do indivíduo (ustacks)
#   -n 1           → mismatches entre indivíduos (cstacks)
#   --kmer-length 15 → necessário para reads curtas (36bp)
#   -r 0.8         → filtro de completude (populations)
# =============================================================================
