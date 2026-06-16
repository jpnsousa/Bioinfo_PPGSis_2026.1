# =============================================================================
#  ESPELHO — Módulos 4 e 5: Git Colaborativo e Formatos NGS
#  CHS0007 · Bioinformática · PPGSIS/UFC · Aula 2
#
#  Como usar: abra este arquivo ao lado do terminal e digite UMA linha por vez.
#  Os alunos digitam junto. Não rode tudo de uma vez.
# =============================================================================

cd ~/Bioinfo_PPGSis_2026.1
DADOS="1.dados/brutos/aula_02"


# =============================================================================
#  MÓDULO 4 — GIT COLABORATIVO
# =============================================================================


# --- 4.1. Garantir que estamos atualizados -----------------------------------
git checkout main
git pull origin main
git log --oneline -5            # ver os últimos commits


# --- 4.2. Criar branch de trabalho -------------------------------------------
git checkout -b feat/contagem-reads-aula2
git branch                      # confirmar em qual branch estamos


# --- 4.3. Criar o script que versionaremos -----------------------------------
mkdir -p scripts

cat > scripts/contar_reads.sh << 'SCRIPT'
#!/usr/bin/env bash
# Conta reads de cada amostra e salva em TSV
# CHS0007 · Bioinformática · PPGSIS/UFC · Aula 2
set -euo pipefail

DADOS="${1:-1.dados/brutos/aula_02}"
SAIDA="${2:-2.resultados/contagem_reads.tsv}"

mkdir -p "$(dirname $SAIDA)"

echo "amostra	reads	status" > "$SAIDA"

for FQ in $DADOS/*_R1.fastq.gz; do
    NOME=$(basename $FQ _R1.fastq.gz)
    N=$(zcat $FQ | awk 'NR%4==1' | wc -l)
    STATUS="ok"
    [ $N -lt 1000 ] && STATUS="baixa_cobertura"
    echo "$NOME	$N	$STATUS" >> "$SAIDA"
    echo "  $NOME: $N reads [$STATUS]"
done

echo "Salvo em: $SAIDA"
SCRIPT

chmod +x scripts/contar_reads.sh
bash scripts/contar_reads.sh    # testar antes de commitar


# --- 4.4. Versionar -----------------------------------------------------------
git status                      # novo arquivo em vermelho
git add scripts/contar_reads.sh
git status                      # verde: pronto para commitar
git commit -m "feat: script de contagem de reads por amostra"
git log --oneline               # novo commit nesta branch


# --- 4.5. Modificar e commitar novamente -------------------------------------
# Adicionar comentário com a versão dos dados usados
echo "" >> scripts/contar_reads.sh
echo "# Dados: Arapaima/Bothrops/Manacus/Podocnemis — FASTQs sintéticos Aula 2" >> scripts/contar_reads.sh

git diff scripts/contar_reads.sh   # ver o que mudou
git add scripts/contar_reads.sh
git commit -m "docs: registrar origem dos dados de exemplo"
git log --oneline               # dois commits nesta branch


# --- 4.6. Subir e abrir PR ---------------------------------------------------
git push origin feat/contagem-reads-aula2

# No GitHub.com:
# 1. "Compare & pull request"
# 2. Título: "feat: script contagem reads – Aula 2 [grupo]"
# 3. Descrição: o que faz o script, como testar (bash scripts/contar_reads.sh)
# 4. Reviewers: adicionar colega do lado
# 5. Submit pull request


# --- 4.7. Revisar o PR do colega (GitHub.com) --------------------------------
# Files changed → ver linhas + e -
# Clicar numa linha → comentário inline
# Approve ou Request changes
# Merge só após aprovação


# --- 4.8. Após merge: limpar -------------------------------------------------
git checkout main
git pull origin main
git branch -d feat/contagem-reads-aula2
git branch                      # só main


# =============================================================================
#  MÓDULO 5 — FORMATOS NGS
# =============================================================================


# --- 5.1. Inspecionar os FASTQs da aula --------------------------------------
cd $DADOS

# Estrutura de 4 linhas
zcat Arapaima_gigas_R1.fastq.gz | head -8

# Comparar boa qualidade vs ruim
echo "=== Arapaima (qualidade alta) ==="
zcat Arapaima_gigas_R1.fastq.gz | awk 'NR%4==0' | head -3   # linha de qualidade

echo "=== Controle negativo (qualidade ruim) ==="
zcat Controle_negativo_R1.fastq.gz | awk 'NR%4==0' | head -3


# --- 5.2. Contar reads de todas as amostras ----------------------------------
for FQ in *_R1.fastq.gz; do
    echo -n "$(basename $FQ _R1.fastq.gz): "
    zcat $FQ | awk 'NR%4==1' | wc -l
done


# --- 5.3. Detectar Ns (bases não determinadas) --------------------------------
echo "=== Podocnemis: primeiros reads ==="
zcat Podocnemis_expansa_R1.fastq.gz | awk 'NR%4==2' | head -5   # sequências

echo "=== Por que há Ns? ==="
# N = base não determinada (sinal ambíguo no sequenciador)
# Aparece no início do read quando o fluxo ainda não estabilizou
# # na qualidade = Q2 = ASCII 35 = 37% acurácia — base inutilizável
# → será removido pelo Trimmomatic na Aula 3


# --- 5.4. SAM/BAM — criar exemplo e inspecionar ------------------------------
cd ~/Bioinfo_PPGSis_2026.1
mkdir -p 2.resultados/alignment

cat > 2.resultados/alignment/exemplo.sam << 'SAM'
@HD	VN:1.6	SO:coordinate
@SQ	SN:Chr01_Batrox	LN:248956422
@RG	ID:A01	SM:Bothrops_jararaca	PL:ILLUMINA	LB:RADseq
read001	0	Chr01_Batrox	10050	60	75M	*	0	0	ATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGA	IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII	RG:Z:A01	NM:i:0
read002	16	Chr01_Batrox	10125	60	75M	*	0	0	GCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTA	HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH	RG:Z:A01	NM:i:2
SAM

grep '^@' 2.resultados/alignment/exemplo.sam       # só cabeçalho
grep -v '^@' 2.resultados/alignment/exemplo.sam    # só alinhamentos

# Campos: QNAME FLAG RNAME POS MAPQ CIGAR RNEXT PNEXT TLEN SEQ QUAL
# FLAG 0 = forward   FLAG 16 = reverso   FLAG 4 = não mapeado
# CIGAR: 75M = 75 matches · 2D = 2 deleções · 3I = 3 inserções

# Converter para BAM (se samtools disponível)
samtools view -bS 2.resultados/alignment/exemplo.sam \
    | samtools sort -o 2.resultados/alignment/exemplo.bam
samtools index 2.resultados/alignment/exemplo.bam
samtools flagstat 2.resultados/alignment/exemplo.bam


# --- 5.5. VCF — criar exemplo e inspecionar ----------------------------------
mkdir -p 2.resultados/variants

cat > 2.resultados/variants/exemplo.vcf << 'VCF'
##fileformat=VCFv4.2
##source=GATK_HaplotypeCaller
##INFO=<ID=DP,Number=1,Type=Integer,Description="Read Depth">
##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	Batrox_01	Batrox_02	Batrox_03
Chr01_Batrox	105340	.	A	G	120	PASS	DP=45	GT:DP	0/1:23	0/0:22	1/1:18
Chr01_Batrox	230110	.	GTC	G	89	PASS	DP=30	GT:DP	1/1:15	1/1:9	1/1:11
Chr02_Batrox	89023	.	A	T	28	LowQual	DP=8	GT:DP	./.:3	0/1:3	0/1:2
VCF

grep '^##' 2.resultados/variants/exemplo.vcf          # metadados
grep '^#CHROM' 2.resultados/variants/exemplo.vcf      # cabeçalho das colunas
grep -v '^#' 2.resultados/variants/exemplo.vcf         # variantes

# Genótipos (campo GT):
# 0/0 = homozigoto ref · 0/1 = heterozigoto · 1/1 = homozigoto alt · ./. = faltante

# Filtrar só variantes PASS com awk
grep -v '^#' 2.resultados/variants/exemplo.vcf | awk '$7=="PASS"'
grep -v '^#' 2.resultados/variants/exemplo.vcf | awk '$6>=30'   # QUAL >= 30

# Com bcftools (se disponível)
bcftools stats 2.resultados/variants/exemplo.vcf | grep '^SN'
bcftools view -f PASS 2.resultados/variants/exemplo.vcf


# =============================================================================
#  RESUMO DO PIPELINE NGS
#
#  FASTQ   → mapeamento (BWA/Bowtie2/Minimap2)   → SAM/BAM
#  SAM/BAM → variant calling (GATK/FreeBayes)    → VCF
#  VCF     → análise populacional (PCA, Fst, filogenia)
#
#  Ferramentas por etapa:
#    QC:       FastQC · MultiQC · seqkit
#    Trim:     Trimmomatic · fastp
#    Mapear:   BWA-MEM2 · Bowtie2 · Minimap2
#    BAM:      samtools
#    Variantes:GATK · FreeBayes · bcftools
#
#  Aula 3: vamos rodar FastQC nos 4 FASTQs e comparar os relatórios!
# =============================================================================
