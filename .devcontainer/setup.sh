#!/usr/bin/env bash
# =============================================================================
#  setup.sh — Bioinformática PPGSIS 2026 · Dr. Yan Torres
#  Executado automaticamente após a criação do Codespace (postCreateCommand)
#  Tempo estimado: 15–25 min (primeira vez)
# =============================================================================
set -euo pipefail

RESET='\033[0m'; BOLD='\033[1m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'

log()  { echo -e "${CYAN}[BIOINFO]${RESET} $1"; }
ok()   { echo -e "${GREEN}[OK]${RESET} $1"; }
warn() { echo -e "${YELLOW}[AVISO]${RESET} $1"; }
fail() { echo -e "${RED}[ERRO]${RESET} $1"; }

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║   Bioinformática PPGSIS 2026 — Configuração do ambiente  ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════╝${RESET}"
echo ""

# ── 1. Dependências do sistema ─────────────────────────────────────────────
log "Instalando dependências do sistema..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
    wget curl git tree htop build-essential \
    libssl-dev libcurl4-openssl-dev libxml2-dev \
    libgdal-dev libproj-dev libgeos-dev \
    gdebi-core locales fonts-liberation

sudo locale-gen pt_BR.UTF-8
ok "Dependências do sistema instaladas"

# ── 2. Miniforge3 (Conda + Mamba) ─────────────────────────────────────────
CONDA_DIR="$HOME/miniforge3"
if [ ! -d "$CONDA_DIR" ]; then
    log "Instalando Miniforge3 (Conda + Mamba)..."
    wget -q "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh" \
        -O /tmp/miniforge.sh
    bash /tmp/miniforge.sh -b -p "$CONDA_DIR"
    rm /tmp/miniforge.sh
    ok "Miniforge3 instalado em $CONDA_DIR"
else
    ok "Miniforge3 já presente"
fi

# Inicializar conda para este shell
source "$CONDA_DIR/etc/profile.d/conda.sh"
source "$CONDA_DIR/etc/profile.d/mamba.sh"
conda config --set auto_activate_base false

# Adicionar ao .bashrc para sessões futuras
if ! grep -q "miniforge3" "$HOME/.bashrc" 2>/dev/null; then
    echo "" >> "$HOME/.bashrc"
    echo "# Conda / Mamba — Bioinformática PPGSIS 2026" >> "$HOME/.bashrc"
    echo "source \$HOME/miniforge3/etc/profile.d/conda.sh" >> "$HOME/.bashrc"
    echo "source \$HOME/miniforge3/etc/profile.d/mamba.sh" >> "$HOME/.bashrc"
    echo "conda activate bioinfo" >> "$HOME/.bashrc"
fi

# ── 3. Ambiente principal: bioinfo ─────────────────────────────────────────
log "Criando ambiente conda 'bioinfo' (pode levar 10–15 min)..."
if conda env list | grep -q "^bioinfo "; then
    warn "Ambiente 'bioinfo' já existe — atualizando..."
    mamba env update -n bioinfo -f .devcontainer/environment.yml --prune
else
    mamba env create -f .devcontainer/environment.yml
fi
ok "Ambiente 'bioinfo' pronto"

# ── 4. Ambiente QIIME2 (Módulo 4) ─────────────────────────────────────────
QIIME2_VERSION="2024.10"
log "Criando ambiente QIIME2 ${QIIME2_VERSION} (Módulo 4 — Metagenômica)..."
QIIME2_URL="https://data.qiime2.org/distro/amplicon/qiime2-amplicon-${QIIME2_VERSION}-py310-linux-conda.yml"

if conda env list | grep -q "^qiime2-amplicon "; then
    warn "Ambiente 'qiime2-amplicon' já existe — pulando"
else
    wget -q "$QIIME2_URL" -O /tmp/qiime2.yml
    mamba env create -n qiime2-amplicon -f /tmp/qiime2.yml
    rm /tmp/qiime2.yml
fi
ok "Ambiente 'qiime2-amplicon' pronto"

# ── 5. RStudio Server ──────────────────────────────────────────────────────
log "Instalando RStudio Server..."
RSTUDIO_VERSION="2024.09.1-394"
RSTUDIO_DEB="rstudio-server-${RSTUDIO_VERSION}-amd64.deb"
RSTUDIO_URL="https://download2.rstudio.org/server/jammy/amd64/${RSTUDIO_DEB}"

if ! command -v rstudio-server &>/dev/null; then
    wget -q "$RSTUDIO_URL" -O "/tmp/${RSTUDIO_DEB}"
    sudo gdebi -n "/tmp/${RSTUDIO_DEB}"
    rm "/tmp/${RSTUDIO_DEB}"
    # Configurar para usar R do ambiente conda
    echo "rsession-which-r=$HOME/miniforge3/envs/bioinfo/bin/R" | sudo tee /etc/rstudio/rserver.conf
    sudo rstudio-server start
    ok "RStudio Server instalado (porta 8787)"
else
    ok "RStudio Server já instalado"
fi

# ── 6. Estrutura de pastas do projeto ─────────────────────────────────────
log "Criando estrutura de pastas do projeto..."
mkdir -p dados/{brutos,limpos,resultados}
mkdir -p scripts/{modulo1,modulo2,modulo3,modulo4,modulo5}
mkdir -p projetos/grupo
mkdir -p figuras
mkdir -p relatorio

if [ ! -f "dados/.gitkeep" ]; then
    touch dados/brutos/.gitkeep dados/limpos/.gitkeep dados/resultados/.gitkeep
fi
ok "Estrutura de pastas criada"

# ── 7. Mensagem final ─────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}${BOLD}║          ✅  Ambiente configurado com sucesso!           ║${RESET}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${BOLD}Ambientes disponíveis:${RESET}"
echo -e "  • ${CYAN}bioinfo${RESET}          — ferramentas principais (ativo por padrão)"
echo -e "  • ${CYAN}qiime2-amplicon${RESET}  — QIIME2 para metagenômica (Módulo 4)"
echo ""
echo -e "  ${BOLD}Para ativar:${RESET}"
echo -e "  ${CYAN}conda activate bioinfo${RESET}"
echo -e "  ${CYAN}conda activate qiime2-amplicon${RESET}"
echo ""
echo -e "  ${BOLD}RStudio Server:${RESET} abra a aba 'PORTS' → porta 8787"
echo ""
echo -e "  ${BOLD}Verificar instalação:${RESET}"
echo -e "  ${CYAN}bash .devcontainer/verificar.sh${RESET}"
echo ""
