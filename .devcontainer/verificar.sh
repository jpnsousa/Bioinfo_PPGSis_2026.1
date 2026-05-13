#!/usr/bin/env bash
# =============================================================================
#  verificar.sh — testa se todas as ferramentas estão instaladas
#  Uso: bash .devcontainer/verificar.sh
# =============================================================================

source "$HOME/miniforge3/etc/profile.d/conda.sh" 2>/dev/null
conda activate bioinfo 2>/dev/null

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'
PASS=0; FAIL=0

check() {
    local name="$1"; local cmd="$2"
    if command -v "$cmd" &>/dev/null; then
        local ver
        ver=$(eval "$cmd --version 2>&1 | head -1" 2>/dev/null || echo "ok")
        echo -e "  ${GREEN}✔${RESET} ${name} — ${ver}"
        ((PASS++))
    else
        echo -e "  ${RED}✘${RESET} ${name} — NÃO ENCONTRADO"
        ((FAIL++))
    fi
}

check_r() {
    local pkg="$1"
    if Rscript -e "library($pkg)" &>/dev/null 2>&1; then
        echo -e "  ${GREEN}✔${RESET} R::${pkg}"
        ((PASS++))
    else
        echo -e "  ${RED}✘${RESET} R::${pkg} — não instalado"
        ((FAIL++))
    fi
}

echo ""
echo -e "${BOLD}═══════════════════════════════════════════════${RESET}"
echo -e "${BOLD}  Verificação do ambiente — Bioinformática 2026 ${RESET}"
echo -e "${BOLD}═══════════════════════════════════════════════${RESET}"
echo ""

echo -e "${BOLD}── Módulo 1/2: Utilitários e QC ───────────────${RESET}"
check "seqkit"     "seqkit"
check "FastQC"     "fastqc"
check "MultiQC"    "multiqc"
check "fastp"      "fastp"
check "Trimmomatic" "trimmomatic"

echo ""
echo -e "${BOLD}── Módulo 2/3: Simulação e montagem ───────────${RESET}"
check "ART (art_illumina)" "art_illumina"
check "SPAdes"     "spades.py"
check "QUAST"      "quast.py"
check "BUSCO"      "busco"
check "Prokka"     "prokka"

echo ""
echo -e "${BOLD}── Módulo 3/5: Alinhamento ─────────────────────${RESET}"
check "BWA-MEM2"   "bwa-mem2"
check "Bowtie2"    "bowtie2"
check "samtools"   "samtools"
check "bcftools"   "bcftools"

echo ""
echo -e "${BOLD}── Módulo 5: SNP Calling ───────────────────────${RESET}"
check "Stacks (denovo_map)" "denovo_map.pl"
check "VCFtools"   "vcftools"
check "SRA Toolkit (fasterq-dump)" "fasterq-dump"

echo ""
echo -e "${BOLD}── R e pacotes ─────────────────────────────────${RESET}"
check "R"          "Rscript"
check_r "tidyverse"
check_r "ggplot2"
check_r "vegan"
check_r "phyloseq"
check_r "adegenet"
check_r "poppr"
check_r "ape"

echo ""
echo -e "${BOLD}── QIIME2 (ambiente separado) ──────────────────${RESET}"
if conda env list | grep -q "qiime2-amplicon"; then
    echo -e "  ${GREEN}✔${RESET} Ambiente 'qiime2-amplicon' presente"
    ((PASS++))
else
    echo -e "  ${RED}✘${RESET} Ambiente 'qiime2-amplicon' não encontrado"
    ((FAIL++))
fi

echo ""
echo -e "${BOLD}── Git e GitHub ────────────────────────────────${RESET}"
check "git"        "git"
check "gh (GitHub CLI)" "gh"

echo ""
echo -e "${BOLD}═══════════════════════════════════════════════${RESET}"
echo -e "  Resultado: ${GREEN}${PASS} OK${RESET} / ${RED}${FAIL} falhas${RESET}"
if [ "$FAIL" -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}✅ Tudo pronto! Pode começar.${RESET}"
else
    echo -e "  ${YELLOW}⚠  Rode: bash .devcontainer/setup.sh para reinstalar${RESET}"
fi
echo ""
