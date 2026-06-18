# =============================================================================
# ESPELHO — AULA 04: Montagem de Genomas
# CHS0007 Bioinformática · PPGSIS/UFC · Junho 2026
# Dr. Yan Torres
#
# USO: Este arquivo é um GUIA DE AULA, não um script executável.
#      Execute cada bloco manualmente no terminal junto com os alunos.
#      Os comentários são as explicações que você fala em voz alta.
# =============================================================================


# =============================================================================
# PARTE 0 — Sincronizar o repositório com o do professor
# =============================================================================

# Garantir que estamos no branch principal
git checkout main

# Buscar as atualizações do repositório do professor
git fetch upstream

# Resetar o main local para ficar idêntico ao do professor
git reset --hard upstream/main

# Publicar no fork pessoal no GitHub
git push origin main --force-with-lease


# =============================================================================
# PARTE 1 — Preparação do ambiente
# =============================================================================

# Confirmar que estamos na raiz do repositório
pwd

# Verificar que o dataset já está baixado
ls -lh 1.dados/brutos/aula_04/

# Criar todos os diretórios que vamos usar hoje
mkdir -p 2.resultados/aula_04/fastqc_raw/
mkdir -p 2.resultados/aula_04/spades/
mkdir -p 2.resultados/aula_04/quast/


# =============================================================================
# PARTE 2 — Conhecendo o dataset
# =============================================================================

# Quantos reads temos no R1?
# awk lê o arquivo linha a linha e no final (END) imprime NR (número de linhas) dividido por 4
# NR = Number of Records = total de linhas lidas
# Dividimos por 4 porque cada read FASTQ ocupa exatamente 4 linhas:
#   linha 1: cabeçalho (@)
#   linha 2: sequência
#   linha 3: separador (+)
#   linha 4: qualidade
zcat 1.dados/brutos/aula_04/SRR13510367_1.fastq.gz | awk 'END{print NR/4}'

# Alternativa com wc -l (contar linhas e dividir por 4 manualmente):
zcat 1.dados/brutos/aula_04/SRR13510367_1.fastq.gz | wc -l | awk '{print $1/4}'

# Ver as primeiras entradas: cabeçalho, sequência, +, qualidade
zcat 1.dados/brutos/aula_04/SRR13510367_1.fastq.gz | head -8

# Qual é o tamanho dos reads?
zcat 1.dados/brutos/aula_04/SRR13510367_1.fastq.gz | awk 'NR==2{print length($0); exit}'


# =============================================================================
# PARTE 3 — Controle de qualidade com FastQC
# =============================================================================

# Verificar versão do FastQC
fastqc --version

# Rodar FastQC nos dois arquivos R1 e R2
fastqc \
    1.dados/brutos/aula_04/SRR13510367_1.fastq.gz \
    1.dados/brutos/aula_04/SRR13510367_2.fastq.gz \
    --outdir 2.resultados/aula_04/fastqc_raw/ \
    --threads 2

# Listar os arquivos gerados
ls -lh 2.resultados/aula_04/fastqc_raw/

# Abrir o relatório .html no navegador e analisar com a turma.
# Ver quais módulos falharam:
unzip -p 2.resultados/aula_04/fastqc_raw/SRR13510367_1_fastqc.zip \
    SRR13510367_1_fastqc/summary.txt

# Módulos que importam para a decisão de trimar:
#   Per base sequence quality  → PASS = qualidade boa, não precisa trimar
#   Adapter Content            → PASS = sem adaptadores, não precisa trimar
#   Per base N content         → PASS = sem Ns, não precisa trimar
#
# Módulos que FALHAM por design neste dataset (protocolo ARTIC) — ignorar:
#   Sequence Duplication Levels → FAIL esperado — primers amplificam as mesmas regiões
#   Per base sequence content   → FAIL esperado — bias nos primers no início dos reads
#
# DECISÃO: qualidade boa, sem adaptadores → prosseguir direto para o SPAdes


# =============================================================================
# PARTE 4 — Montagem de novo com SPAdes
# =============================================================================

# Verificar versão do SPAdes
spades.py --version

# Rodar SPAdes com cov-cutoff 100 para eliminar contigs de baixa cobertura
# (contigs com cobertura < 100x são provavelmente ruído ou contaminação)
spades.py \
    -1 1.dados/brutos/aula_04/SRR13510367_1.fastq.gz \
    -2 1.dados/brutos/aula_04/SRR13510367_2.fastq.gz \
    -o 2.resultados/aula_04/spades/ \
    --threads 2 \
    --cov-cutoff 100

# Quantos contigs foram montados?
grep -c ">" 2.resultados/aula_04/spades/contigs.fasta

# Ver nome, tamanho e cobertura de cada contig
# O SPAdes codifica essas informações no cabeçalho: NODE_X_length_Y_cov_Z
grep ">" 2.resultados/aula_04/spades/contigs.fasta


# =============================================================================
# PARTE 5 — Avaliação da montagem com QUAST
# =============================================================================

# Verificar versão do QUAST
quast.py --version

# Rodar QUAST nos contigs montados
quast.py \
    2.resultados/aula_04/spades/contigs.fasta \
    --output-dir 2.resultados/aula_04/quast/ \
    --threads 2

# Ver o relatório em texto no terminal
cat 2.resultados/aula_04/quast/report.txt

# Métricas esperadas para este dataset:
#   Maior contig   → 29.078 bp  (genoma quase completo)
#   Total length   → ~30.097 bp
#   N50            → 29.078 bp  (1 contig domina o assembly)
#   L50            → 1          (melhor valor possível)
#   GC%            → ~38,1%     (compatível com SARS-CoV-2)
#   N's per 100kbp → 0          (sem gaps)

# O relatório HTML (report.html) é mais visual — abrir no navegador


# =============================================================================
# PARTE 6 — Salvar e versionar os resultados
# =============================================================================

# Verificar o que foi gerado
ls -lh 2.resultados/aula_04/

# Adicionar ao git
git add 2.resultados/aula_04/
git add 1.dados/brutos/aula_04/

# Commit com mensagem descritiva
git commit -m "aula04: FastQC + SPAdes (cov-cutoff 100) + QUAST · SARS-CoV-2 SRR13510367"

# Enviar para o fork pessoal no GitHub
git push origin main


# =============================================================================
# FIM DO ESPELHO — AULA 04
# =============================================================================
