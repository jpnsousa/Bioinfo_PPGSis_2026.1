#!/usr/bin/env bash
# =============================================================================
# CHS0007 · Bioinformática · PPGSIS/UFC · 2026.1
# SLURM SINGLE-NODE — Instalação e Configuração para GitHub Codespace
# Dr. Yan Torres <yan.torres@ufc.br>
#
# EXECUTAR COMO ROOT (sudo bash setup_slurm_codespace.sh)
# Tempo estimado: ~2 minutos
# =============================================================================

set -euo pipefail

VERDE="\033[1;32m"; AMARELO="\033[1;33m"; AZUL="\033[1;34m"
VERMELHO="\033[1;31m"; RESET="\033[0m"

ok()  { echo -e "${VERDE}[✓]${RESET} $*"; }
info(){ echo -e "${AZUL}[→]${RESET} $*"; }
aviso(){ echo -e "${AMARELO}[!]${RESET} $*"; }
erro(){ echo -e "${VERMELHO}[✗]${RESET} $*"; exit 1; }

echo -e "${AZUL}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║   SLURM Single-Node · GitHub Codespace              ║"
echo "║   CHS0007 Bioinformática · PPGSIS/UFC · 2026.1      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# ─── Verificar root ───────────────────────────────────────────────────────────
[ "$EUID" -eq 0 ] || erro "Execute com sudo: sudo bash $0"

# ─── Coleta de informações do ambiente ────────────────────────────────────────
HOSTNAME=$(hostname -s)
NCPUS=$(nproc)
MEMTOTAL_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
# Reservar 200 MB para o OS
SLURM_MEM=$(( (MEMTOTAL_KB / 1024) - 200 ))
[ "$SLURM_MEM" -lt 512 ] && SLURM_MEM=512

info "Detectado: hostname=$HOSTNAME  CPUs=$NCPUS  Memória SLURM=${SLURM_MEM}MB"

# ═══════════════════════════════════════════════════════════════════════════════
# ETAPA 1 — Instalar pacotes
# ═══════════════════════════════════════════════════════════════════════════════
info "Etapa 1/5 · Instalando pacotes SLURM e munge..."
apt-get update -qq
apt-get install -y -qq slurm-wlm munge 2>&1 | grep -E "^(Setting up|E:|W:)" || true
ok "Pacotes instalados (slurm-wlm + munge)"

# ═══════════════════════════════════════════════════════════════════════════════
# ETAPA 2 — Configurar munge (autenticação)
# ═══════════════════════════════════════════════════════════════════════════════
info "Etapa 2/5 · Configurando munge..."

pkill munged 2>/dev/null || true
sleep 1

# Chave de autenticação
dd if=/dev/urandom bs=1 count=1024 > /etc/munge/munge.key 2>/dev/null
chown -R munge:munge /etc/munge /var/lib/munge /var/log/munge
chmod 700 /etc/munge /var/lib/munge
chmod 400 /etc/munge/munge.key
chmod 755 /run/munge 2>/dev/null || mkdir -p /run/munge && chmod 755 /run/munge
chown munge:munge /run/munge

# Iniciar munged (--force: ignora avisos de segurança de container)
munged --force
sleep 2

# Validar
if munge -n | unmunge &>/dev/null; then
    ok "munge operacional"
else
    aviso "munge com aviso — continuando (normal em containers)"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# ETAPA 3 — Montar cgroup systemd (necessário para slurmd)
# ═══════════════════════════════════════════════════════════════════════════════
info "Etapa 3/5 · Configurando cgroup para slurmd..."

if [ ! -d /sys/fs/cgroup/systemd ]; then
    mkdir -p /sys/fs/cgroup/systemd
fi

# Montar cgroup systemd se não estiver montado
if ! mountpoint -q /sys/fs/cgroup/systemd 2>/dev/null; then
    mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd 2>/dev/null || true
fi
ok "cgroup configurado"

# ═══════════════════════════════════════════════════════════════════════════════
# ETAPA 4 — Criar configurações SLURM
# ═══════════════════════════════════════════════════════════════════════════════
info "Etapa 4/5 · Gerando slurm.conf para $HOSTNAME..."

mkdir -p /var/spool/slurmctld /var/spool/slurmd /var/log/slurm
chown slurm:slurm /var/spool/slurmctld /var/spool/slurmd /var/log/slurm 2>/dev/null || true

cat > /etc/slurm/slurm.conf << EOF
# ── slurm.conf · PPGSIS Bioinformática · single-node Codespace ──────────────
ClusterName=bioinfo_ppgsis
SlurmctldHost=${HOSTNAME}

# Autenticação
AuthType=auth/munge
CryptoType=crypto/munge

# Processos e plugins
MpiDefault=none
ProctrackType=proctrack/linuxproc
SwitchType=switch/none
TaskPlugin=task/none

# Accounting desabilitado (simplifica setup)
AccountingStorageType=accounting_storage/none
JobCompType=jobcomp/none

# Scheduler
SchedulerType=sched/backfill
SelectType=select/cons_tres
SelectTypeParameters=CR_CPU

# Timeouts e limites
InactiveLimit=0
KillWait=30
MinJobAge=300
SlurmctldTimeout=120
SlurmdTimeout=300
ReturnToService=2

# Arquivos PID e spool
SlurmctldPidFile=/run/slurmctld.pid
SlurmdPidFile=/run/slurmd.pid
SlurmdSpoolDir=/var/spool/slurmd
SlurmUser=slurm
StateSaveLocation=/var/spool/slurmctld

# Portas
SlurmctldPort=6817
SlurmdPort=6818

# Memória padrão por CPU
DefMemPerCPU=512

# ── Nó único (detectado automaticamente) ─────────────────────────────────────
NodeName=${HOSTNAME} CPUs=${NCPUS} RealMemory=${SLURM_MEM} \\
    Sockets=1 CoresPerSocket=${NCPUS} ThreadsPerCore=1 State=UNKNOWN

# ── Partições ─────────────────────────────────────────────────────────────────
PartitionName=bioinfo   Nodes=${HOSTNAME} Default=YES MaxTime=INFINITE State=UP
PartitionName=expresso  Nodes=${HOSTNAME} MaxTime=00:10:00 State=UP
EOF

# cgroup.conf mínimo (desabilita restrições — container não suporta)
cat > /etc/slurm/cgroup.conf << 'EOF'
ConstrainCores=no
ConstrainDevices=no
ConstrainRAMSpace=no
ConstrainSwapSpace=no
EOF

ok "slurm.conf e cgroup.conf criados"

# ═══════════════════════════════════════════════════════════════════════════════
# ETAPA 5 — Iniciar serviços
# ═══════════════════════════════════════════════════════════════════════════════
info "Etapa 5/5 · Iniciando slurmctld e slurmd..."

# Matar instâncias anteriores
pkill slurmctld 2>/dev/null || true
pkill slurmd    2>/dev/null || true
sleep 2

# Iniciar controller
slurmctld 2>/var/log/slurm/slurmctld.log &
sleep 5

# Verificar controller
if ! pgrep slurmctld &>/dev/null; then
    erro "slurmctld não iniciou. Verifique: cat /var/log/slurm/slurmctld.log"
fi
ok "slurmctld iniciado"

# Iniciar daemon do nó
slurmd 2>/var/log/slurm/slurmd.log &
sleep 6

if ! pgrep slurmd &>/dev/null; then
    # Tentar uma segunda vez (às vezes o PID anterior demora a limpar)
    sleep 3
    slurmd 2>>/var/log/slurm/slurmd.log &
    sleep 5
fi

if pgrep slurmd &>/dev/null; then
    ok "slurmd iniciado"
else
    aviso "slurmd pode estar rodando como daemon. Verificando sinfo..."
fi

# ═══════════════════════════════════════════════════════════════════════════════
# VALIDAÇÃO FINAL
# ═══════════════════════════════════════════════════════════════════════════════
echo ""
info "Validando cluster..."
sleep 3

SINFO_OUT=$(sinfo 2>&1)
echo "$SINFO_OUT"

if echo "$SINFO_OUT" | grep -q "idle\|alloc"; then
    echo ""
    echo -e "${VERDE}══════════════════════════════════════════════════${RESET}"
    echo -e "${VERDE}  ✅ SLURM FUNCIONANDO — cluster bioinfo_ppgsis${RESET}"
    echo -e "${VERDE}══════════════════════════════════════════════════${RESET}"
    echo ""
    echo -e "  Partições disponíveis:"
    echo -e "    ${AZUL}bioinfo${RESET}   → sem limite de tempo (análises longas)"
    echo -e "    ${AZUL}expresso${RESET}  → máx 10 minutos (testes rápidos)"
    echo ""
    echo -e "  Próximo passo:"
    echo -e "    ${AMARELO}bash aula2_gabarito_professor.sh${RESET}"
    echo ""
else
    aviso "Nó ainda em estado 'unk' — aguarde alguns segundos e execute: sinfo"
    aviso "Se persistir: scontrol update NodeName=${HOSTNAME} State=RESUME"
fi

# ─── Criar script de reinício rápido ─────────────────────────────────────────
cat > /usr/local/bin/slurm-restart << 'RESTART'
#!/usr/bin/env bash
# Reinicia SLURM + munge no Codespace (útil após reboot do container)
pkill slurmctld munged slurmd 2>/dev/null || true; sleep 2
munged --force 2>/dev/null
mkdir -p /sys/fs/cgroup/systemd 2>/dev/null
mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd 2>/dev/null || true
slurmctld; sleep 4; slurmd; sleep 4
sinfo
echo "✅ SLURM reiniciado"
RESTART
chmod +x /usr/local/bin/slurm-restart

ok "Script de reinício criado: slurm-restart"
echo ""
info "Dica: após reiniciar o Codespace, execute: sudo slurm-restart"
