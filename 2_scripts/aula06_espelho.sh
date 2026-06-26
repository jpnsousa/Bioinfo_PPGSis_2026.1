#!/usr/bin/env bash
# =============================================================================
# CHS0007 — Bioinformática | PPGSIS | UFC
# Aula 06 — Metabarcoding: eDNA, amplicons e pipeline QIIME2
# Dataset : Atacama Soil Microbiome (Neilson et al. 2017)
#           16S rRNA V4 | EMP paired-end | 10% subset
# Primers : 515F (Caporaso) GTGCCAGCMGCCGCGGTAA
#           806R (Caporaso) GGACTACHVGGGTWTCTAAT  (reverse-barcoded)
# Ambiente: GitHub Codespaces (2 cores) | conda env: qiime2-2024.10
# Scripts auxiliares (comandos pesados):
#   run_cutadapt.sh   — remoção de primers
#   run_dada2.sh      — denoising + remoção de quimeras
#   run_diversity.sh  — filogenia + diversidade alfa e beta
# Pré-requisitos (preparar antes da aula):
#   ~/data/silva-138-99-seqs-515-806.qza  — classificador SILVA 138 V4
#   ~/data/silva-138-99-tax.qza           — taxonomia SILVA 138
# =============================================================================


# -----------------------------------------------------------------------------
# BLOCO 0 — Sincronizar repositório com o upstream do professor
# -----------------------------------------------------------------------------

git fetch upstream
# Busca as atualizações do repositório original sem aplicar ainda

git reset --hard upstream/main
# Descarta qualquer modificação local e alinha com o upstream

git push origin main --force-with-lease
# Atualiza o fork do aluno no GitHub com segurança


# -----------------------------------------------------------------------------
# BLOCO 1 — Ativar ambiente QIIME2
# -----------------------------------------------------------------------------

export TZ="UTC"  
# evita erro de timezone no Codespace

conda activate qiime2-amplicon
# Ativa o ambiente conda dedicado ao QIIME2 (instalação separada do bioinfo)

qiime info
# Mostra a versão do QIIME2 e todos os plugins disponíveis


# -----------------------------------------------------------------------------
# BLOCO 2 — Criar estrutura de diretórios e baixar os dados
# -----------------------------------------------------------------------------

mkdir -p ~/aula06/emp-paired-end-sequences
cd ~/aula06

# Baixar metadados das amostras
wget \
  --output-document sample-metadata.tsv \
  "https://data.qiime2.org/2024.10/tutorials/atacama-soils/sample_metadata.tsv"
# --output-document (-O): nome do arquivo de saída

# Inspecionar metadados: transecto, elevação, umidade relativa, profundidade
head -5 sample-metadata.tsv
# Colunas importantes: sample-id, barcode-sequence, transect-name,
#                      elevation, rainfall, relative-humidity, depth

wc -l sample-metadata.tsv
# Contar amostras (linhas - 1 cabeçalho)

# Baixar as 3 reads multiplexadas (todas as amostras juntas em um único arquivo)
wget \
  --output-document forward.fastq.gz \
  "https://data.qiime2.org/2024.10/tutorials/atacama-soils/10p/forward.fastq.gz"
# forward.fastq.gz : reads R1 de todas as amostras

wget \
  --output-document reverse.fastq.gz \
  "https://data.qiime2.org/2024.10/tutorials/atacama-soils/10p/reverse.fastq.gz"
# reverse.fastq.gz : reads R2 de todas as amostras

wget \
  --output-document barcodes.fastq.gz \
  "https://data.qiime2.org/2024.10/tutorials/atacama-soils/10p/barcodes.fastq.gz"
# barcodes.fastq.gz: índices de sequenciamento (identificam a amostra de origem)

# Verificar arquivos baixados
ls -lh 1_seqs/

# Inspecionar início das reads forward (4 linhas por read no FASTQ)
zcat 1_seqs/forward.fastq.gz | head -8

# Contar total de reads (cada read = 4 linhas)
zcat forward.fastq.gz | awk 'END{print NR/4, "reads"}'

zcat barcodes.fastq.gz | head -8

# -----------------------------------------------------------------------------
# BLOCO 3 — Importar dados para o formato QIIME2 (.qza)
# -----------------------------------------------------------------------------

# QIIME2 exige que todos os dados sejam convertidos em artefatos .qza
# Um .qza é um arquivo ZIP contendo: os dados + metadados de proveniência
# (rastreabilidade: cada artefato sabe exatamente como foi gerado)

qiime tools import \
  --type    'EMPPairedEndSequences' \
  --input-path  1_seqs \
  --output-path seqs.qza
# --type        : tipo semântico do artefato (define quais plugins podem usá-lo)
# --input-path  : diretório contendo forward.fastq.gz, reverse.fastq.gz, barcodes.fastq.gz
# --output-path : artefato de saída (.qza)

# Confirmar criação do artefato
ls -lh 1_seqs/seqs.qza

# Um .qza é na prática um ZIP — podemos inspecionar seu conteúdo
unzip -l 1_seqs/seqs.qza | head -15


# -----------------------------------------------------------------------------
# BLOCO 4 — Demultiplexagem: separar reads por amostra
# -----------------------------------------------------------------------------

# As reads chegam todas misturadas. O barcode (sequência-índice) identifica
# a qual amostra pertence cada read. Este passo separa por amostra.

qiime demux emp-paired \
  --i-seqs               seqs.qza \
  --m-barcodes-file      sample-metadata.tsv \
  --m-barcodes-column    barcode-sequence \
  --p-rev-comp-mapping-barcodes \
  --o-per-sample-sequences demux-full.qza \
  --o-error-correction-details demux-details.qza
# --i-seqs                      : artefato com as reads multiplexadas
# --m-barcodes-file             : arquivo de metadados com os barcodes por amostra
# --m-barcodes-column           : coluna do TSV que contém as sequências de barcode
# --p-rev-comp-mapping-barcodes : os barcodes no arquivo estão no complemento reverso
#                                 em relação ao arquivo de metadados (padrão EMP)
# --o-per-sample-sequences      : reads separadas por amostra (artefato principal)
# --o-error-correction-details  : estatísticas de correção de erro de barcode

# Subamostrar para agilizar as etapas seguintes em sala (30% das reads por amostra)
qiime demux subsample-paired \
  --i-sequences  demux-full.qza \
  --p-fraction   0.3 \
  --o-subsampled-sequences demux.qza
# --i-sequences : artefato demultiplexado completo
# --p-fraction  : proporção de reads a manter por amostra (0.0 a 1.0)
# --o-subsampled-sequences: artefato subamostrado para uso em aula

# Gerar visualização interativa da qualidade (.qzv = QIIME Zipped Visualization)
qiime demux summarize \
  --i-data    demux.qza \
  --o-visualization demux.qzv
# --i-data          : artefato demultiplexado
# --o-visualization : arquivo .qzv para abrir em view.qiime2.org
#
# >>> Abrir demux.qzv em view.qiime2.org
# Observar: gráfico de qualidade por posição (forward e reverse)
#           número de reads por amostra
#           essas informações guiam os parâmetros de truncagem do DADA2


# -----------------------------------------------------------------------------
# BLOCO 5 — Remoção de primers (Cutadapt) — ver run_cutadapt.sh
# -----------------------------------------------------------------------------

# Os primers EMP (515F/806R) devem ser removidos antes do DADA2
# Se mantidos, contaminam as ASVs geradas e prejudicam a atribuição taxonômica
#
# Primers utilizados neste dataset (versão original Caporaso, reverse-barcoded):
#   515F: GTGCCAGCMGCCGCGGTAA   (forward)
#   806R: GGACTACHVGGGTWTCTAAT  (reverse)
#
# Nota: o dataset Atacama já foi processado sem primers na versão tutorial.
# Executamos o comando para fixar o conceito — em dados reais é obrigatório.
#
# Comando completo em: run_cutadapt.sh
# Executar em background pois pode demorar alguns minutos:

bash run_cutadapt.sh

# Após concluir, verificar resultado:
qiime demux summarize \
  --i-data    demux-trimmed.qza \
  --o-visualization demux-trimmed.qzv
# >>> Abrir demux-trimmed.qzv em view.qiime2.org
# Comparar qualidade antes e após remoção dos primers


# -----------------------------------------------------------------------------
# BLOCO 6 — Denoising com DADA2 — ver run_dada2.sh
# -----------------------------------------------------------------------------

# DADA2 realiza em uma única etapa:
#   1. Filtragem por qualidade (baseada nos parâmetros de truncagem)
#   2. Aprendizado do modelo de erro (específico para cada run de sequenciamento)
#   3. Denoising: corrige erros e infere ASVs (Amplicon Sequence Variants)
#   4. Merging: une as reads R1 e R2 (overlap mínimo necessário)
#   5. Remoção de quimeras (método: consensus por default)
#
# Parâmetros de truncagem definidos pela inspeção do demux.qzv:
#   --p-trunc-len-f : posição onde qualidade forward cai abaixo de Q30
#   --p-trunc-len-r : posição onde qualidade reverse cai abaixo de Q30
#   Atenção: R1 + R2 truncados precisam ter overlap suficiente para merge
#            Para amplicon V4 (~253 bp): trunc-f + trunc-r > 253 + 20 (overlap mínimo)
#
# Saídas principais:
#   table.qza    : tabela ASV × amostra (frequência de cada ASV por amostra)
#   rep-seqs.qza : sequência representativa de cada ASV
#
# Comando completo em: run_dada2.sh
# DADA2 demora ~8-10 min com 2 cores — iniciar e explicar a teoria enquanto roda:

bash run_dada2.sh

# Após concluir, visualizar estatísticas do denoising
qiime metadata tabulate \
  --m-input-file denoising-stats.qza \
  --o-visualization denoising-stats.qzv
# --m-input-file    : artefato com estatísticas (input → filtered → denoised
#                     → merged → non-chimeric)
# --o-visualization : tabela interativa em view.qiime2.org

# Resumo da tabela de features (ASVs)
qiime feature-table summarize \
  --i-table    4_qza/table.qza \
  --m-sample-metadata-file sample-metadata.tsv \
  --o-visualization 5_qzv/table.qzv
# --i-table                : tabela ASV × amostra
# --m-sample-metadata-file : metadados para colorir amostras por grupo
# --o-visualization        : histograma de reads por amostra + detalhes por feature

# Tabela das sequências das ASVs
qiime feature-table tabulate-seqs \
  --i-data    4_qza/rep-seqs.qza \
  --o-visualization 5_qzv/rep-seqs.qzv
# --i-data          : artefato com sequências representativas
# --o-visualization : tabela clicável — cada ASV abre BLAST no NCBI
#ta
# >>> Abrir table.qzv para definir profundidade de rarefação no Bloco 8


# -----------------------------------------------------------------------------
# BLOCO 7 — Classificação taxonômica com SILVA 138
# -----------------------------------------------------------------------------

# Classificador Naive Bayes pré-treinado na região V4 (515F/806R) do SILVA 138
# Já disponível em ~/data/ (pré-baixado antes da aula para economizar tempo)

qiime feature-classifier classify-sklearn \
  --i-classifier  3_ref_SILVA/silva-138-99-nb-classifier.qza \
  --i-reads       4_qza/rep-seqs.qza \
  --p-n-jobs      1 \
  --o-classification 4_qza/taxonomy.qza
# --i-classifier   : classificador Naive Bayes pré-treinado (SILVA 138, V4)
# --i-reads        : sequências das ASVs a classificar
# --p-n-jobs       : número de núcleos paralelos (2 = limite do Codespace)
# --o-classification: artefato com taxonomia atribuída a cada ASV

# Visualizar a tabela de taxonomia
qiime metadata tabulate \
  --m-input-file taxonomy.qza \
  --o-visualization taxonomy.qzv
# Mostra: ASV ID | taxonomia completa | confiança da classificação

# Barplot interativo de composição taxonômica
qiime taxa barplot \
  --i-table    table.qza \
  --i-taxonomy taxonomy.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization taxa-bar-plots.qzv
# --i-table         : tabela ASV × amostra (frequências)
# --i-taxonomy      : classificação taxonômica das ASVs
# --m-metadata-file : metadados para agrupar e colorir amostras
# --o-visualization : barplot interativo (explorar por nível taxonômico)
#
# >>> Abrir taxa-bar-plots.qzv em view.qiime2.org
# Explorar: nível 2 (filo), nível 5 (família), nível 6 (gênero)
# Comparar composição entre transectos (Baquedano vs Yungay)


# -----------------------------------------------------------------------------
# BLOCO 8 — Diversidade alfa e beta — ver run_diversity.sh
# -----------------------------------------------------------------------------

# Antes de rodar: verificar no table.qzv a profundidade mínima de reads
# por amostra. A rarefação padroniza todas as amostras para o mesmo número
# de reads (amostras com menos reads são descartadas).
#
# Escolher --p-sampling-depth que:
#   - esteja acima do mínimo observado
#   - preserve o máximo de amostras possível
#
# Comando completo (filogenia + core-metrics + alpha + beta) em: run_diversity.sh

bash run_diversity.sh

# Listar todos os .qzv gerados para visualização
ls -lh *.qzv
ls -lh core-metrics-results/*.qzv


# =============================================================================
# ARQUIVOS PARA ABRIR EM view.qiime2.org (em ordem de aula)
# =============================================================================
# demux.qzv                  qualidade das reads + reads por amostra
# demux-trimmed.qzv          qualidade após remoção dos primers
# denoising-stats.qzv        % reads preservadas em cada etapa do DADA2
# table.qzv                  ASVs por amostra + definir profundidade rarefação
# rep-seqs.qzv               sequências ASVs (link para BLAST no NCBI)
# taxonomy.qzv               taxonomia + confiança por ASV
# taxa-bar-plots.qzv         composição taxonômica interativa por amostra
# core-metrics-results/
#   ├── faith_pd_vector.qza              diversidade alfa filogenética
#   ├── bray_curtis_emperor.qzv          PCoA beta-diversidade (3D interativo)
#   ├── unweighted_unifrac_emperor.qzv   PCoA UniFrac não-ponderado
#   └── ...
# faith-pd-group-significance.qzv       teste estatístico alfa por transecto
# unweighted-unifrac-significance.qzv   teste estatístico beta por transecto
# =============================================================================
