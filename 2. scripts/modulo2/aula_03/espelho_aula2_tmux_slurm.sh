# =============================================================================
#  ESPELHO — Módulo 3: tmux e SLURM
#  CHS0007 · Bioinformática · PPGSIS/UFC · Aula 2
#
#  Como usar: abra este arquivo ao lado do terminal e digite UMA linha por vez.
#  Os alunos digitam junto. Não rode tudo de uma vez.
# =============================================================================

sudo bash setup_slurm_codespace.sh   # instala e configura o SLURM no Codespace
cd ~/Bioinfo_PPGSis_2026.1
DADOS="1.dados/brutos/aula_02"


# =============================================================================
#  PARTE A — tmux
# =============================================================================

# tmux é um multiplexador de terminal: permite abrir várias sessões e painéis
# dentro de uma única janela, e deixar processos rodando mesmo após fechar o terminal


# --- A.1. Abrir sessão tmux --------------------------------------------------
# -s dá um nome para a sessão (facilita reconectar depois)
tmux new -s aula2

# A barra verde no fundo confirma que estamos dentro do tmux


# --- A.2. Dividir a tela para monitorar ao vivo ------------------------------
# Ctrl+b é o prefixo do tmux: pressione Ctrl+b, solte, depois pressione a tecla
# Ctrl+b  %     → divide a tela verticalmente (painel esquerdo / direito)
# Ctrl+b  →     → move o cursor para o painel direito

# No painel direito, rodar:
# watch repete um comando em intervalos regulares e atualiza a tela
# -n 2 significa: atualizar a cada 2 segundos
watch -n 2 squeue

# Ctrl+b  ←     → voltar para o painel esquerdo
# Assim dá para submeter jobs à esquerda e ver a fila atualizar à direita ao vivo


# --- A.3. Atalhos essenciais (Ctrl+b = prefixo) ------------------------------
# Ctrl+b  d     → detach: sai da sessão sem matar o que está rodando
# Ctrl+b  "     → divide horizontalmente (painel de cima / baixo)
# Ctrl+b  x     → fecha o painel atual
# Ctrl+b  ,     → renomeia a janela atual


# --- A.4. Sair e reconectar --------------------------------------------------
# Ctrl+b  d     → detach (pode fechar o terminal ou o laptop agora)

tmux ls                        # fora do tmux: lista todas as sessões ativas
tmux attach -t aula2           # reconecta à sessão "aula2" — tudo exatamente onde parou


# --- A.5. Uso real: análise longa --------------------------------------------
tmux new -s fastqc             # sessão dedicada para o FastQC
# fastqc 1.dados/brutos/aula_02/*.fastq.gz -o 2.resultados/qc/ -t $THREADS
# Ctrl+b  d                    # sair sem matar — feche o laptop!
tmux attach -t fastqc          # horas depois: reconectar e ver o progresso


# --- A.6. Encerrar sessão ----------------------------------------------------
# (dentro do tmux):  exit
# (de fora):
tmux kill-session -t aula2     # encerra a sessão e todos os processos dentro dela


# =============================================================================
#  PARTE B — SLURM
# =============================================================================

# SLURM é um agendador de jobs para clusters: você descreve os recursos que precisa
# (CPUs, memória, tempo) e ele decide quando e onde rodar o seu script


# --- B.1. Verificar o cluster ------------------------------------------------
sinfo                          # mostra partições disponíveis e estado dos nós (idle/alloc/down)
squeue                         # mostra todos os jobs na fila agora
scontrol show node             # detalhes completos de CPU e memória de cada nó


# --- B.2. Variáveis automáticas injetadas pelo SLURM -------------------------
# O SLURM preenche essas variáveis automaticamente quando o job começa a rodar
# Use-as dentro dos scripts em vez de fixar valores no código

# $SLURM_JOB_ID          → ID único do job (ex: 42)
# $SLURM_CPUS_PER_TASK   → número de CPUs alocados — use isso no lugar de um número fixo
# $SLURM_SUBMIT_DIR      → pasta de onde sbatch foi chamado — útil para cd no início do job
# $SLURM_ARRAY_TASK_ID   → índice da tarefa atual quando usando job array (1, 2, 3...)


# --- B.3. Criar estrutura de jobs e logs -------------------------------------
mkdir -p scripts/slurm logs    # scripts/slurm: onde ficam os .sh  |  logs: onde o SLURM salva saída


# --- B.4. Primeiro job: contar reads das amostras ----------------------------

# O heredoc (<<'SLURM' ... SLURM) escreve tudo entre as marcas diretamente no arquivo
# As aspas simples em 'SLURM' são importantes: impedem que o shell expanda $VARIÁVEIS
# durante a escrita — elas devem ser expandidas quando o job rodar, não agora

cat > scripts/slurm/01_contar_reads.sh << 'SLURM'
#!/usr/bin/env bash

# Linhas #SBATCH são instruções para o SLURM — lidas antes do script rodar
# O SLURM as interpreta mesmo sendo comentários para o bash

#SBATCH --job-name=contar_reads      # nome que aparece no squeue
#SBATCH --output=logs/%j_contar.out  # %j é substituído pelo SLURM_JOB_ID
#SBATCH --error=logs/%j_contar.err   # erros vão para um arquivo separado
#SBATCH --partition=expresso         # fila a usar (expresso = jobs curtos no Codespace)
#SBATCH --ntasks=1                   # número de tarefas MPI (para scripts normais: sempre 1)
#SBATCH --cpus-per-task=1            # CPUs por tarefa (aumentar para ferramentas multi-thread)
#SBATCH --mem=256M                   # memória total reservada para o job
#SBATCH --time=00:03:00              # tempo máximo: HH:MM:SS — job é cancelado se exceder

# cd para a pasta de onde sbatch foi chamado (evita problema de caminho relativo)
cd $SLURM_SUBMIT_DIR

DADOS="1.dados/brutos/aula_02"

echo "Job $SLURM_JOB_ID iniciado em $(date)"
echo "amostra	reads" > 2.resultados/contagem_slurm.tsv

for FQ in $DADOS/*_R1.fastq.gz; do
    NOME=$(basename $FQ _R1.fastq.gz)
    N=$(zcat $FQ | awk 'NR%4==1' | wc -l)
    echo "$NOME	$N" >> 2.resultados/contagem_slurm.tsv
    echo "  $NOME: $N reads"
done

echo "Concluído em $(date)"
SLURM

cat scripts/slurm/01_contar_reads.sh     # revisar o arquivo antes de submeter


# --- B.5. Submeter e acompanhar ----------------------------------------------
# sbatch lê o arquivo, valida os #SBATCH e coloca o job na fila
# retorna: Submitted batch job <ID>
sbatch scripts/slurm/01_contar_reads.sh

squeue                         # ST: R = rodando   PD = aguardando na fila
squeue -u $USER                # filtra: mostra só os seus jobs


# --- B.6. Ver output quando terminar (aguardar ~20 s) -----------------------
ls logs/                               # os arquivos .out e .err aparecem aqui
cat logs/*_contar.out                  # tudo que o script imprimiu com echo
cat 2.resultados/contagem_slurm.tsv   # o arquivo de resultado gerado pelo job


# --- B.7. Job com $SLURM_CPUS_PER_TASK (boa prática) ------------------------

# Usando $SLURM_CPUS_PER_TASK no script em vez de fixar o número de threads:
# se você mudar --cpus-per-task lá em cima, o resto se ajusta automaticamente

cat > scripts/slurm/02_fastqc.sh << 'SLURM'
#!/usr/bin/env bash
#SBATCH --job-name=fastqc_ppgsis
#SBATCH --output=logs/%j_fastqc.out
#SBATCH --error=logs/%j_fastqc.err
#SBATCH --partition=bioinfo         # partição com mais recursos para análises maiores
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=512M                  # FastQC precisa de mais memória que o contador de reads
#SBATCH --time=00:10:00

cd $SLURM_SUBMIT_DIR

# $SLURM_CPUS_PER_TASK garante que FastQC use exatamente os CPUs alocados
echo "FastQC com $SLURM_CPUS_PER_TASK CPUs"

# fastqc 1.dados/brutos/aula_02/*.fastq.gz \
#     -o 2.resultados/qc/ \
#     --threads $SLURM_CPUS_PER_TASK

# Versão simulada para o Codespace (sleep 1 imita o tempo de processamento)
for FQ in 1.dados/brutos/aula_02/*_R1.fastq.gz; do
    echo "  [simulado] FastQC: $(basename $FQ)"
    sleep 1
done

echo "FastQC concluído em $(date)"
SLURM

sbatch scripts/slurm/02_fastqc.sh
squeue


# --- B.8. Job array: uma tarefa por amostra ----------------------------------

# Job array: o SLURM cria N cópias do mesmo script, cada uma com um índice diferente
# Útil para processar várias amostras em paralelo sem submeter jobs manualmente

cat > scripts/slurm/03_array_qc.sh << 'SLURM'
#!/usr/bin/env bash
#SBATCH --job-name=qc_array
#SBATCH --output=logs/array_%A_%a.out  # %A = ID do array  %a = índice da tarefa
#SBATCH --error=logs/array_%A_%a.err
#SBATCH --array=1-4                    # cria 4 tarefas: SLURM_ARRAY_TASK_ID vai de 1 a 4
#SBATCH --partition=expresso
#SBATCH --cpus-per-task=1
#SBATCH --mem=256M
#SBATCH --time=00:02:00

cd $SLURM_SUBMIT_DIR

# sed -n "Np" imprime só a linha N do arquivo
# SLURM_ARRAY_TASK_ID é 1 para a 1ª tarefa, 2 para a 2ª, etc.
# resultado: cada tarefa pega uma amostra diferente de lista_amostras.txt
AMOSTRA=$(sed -n "${SLURM_ARRAY_TASK_ID}p" lista_amostras.txt)
FQ="1.dados/brutos/aula_02/${AMOSTRA}_R1.fastq.gz"

echo "Tarefa $SLURM_ARRAY_TASK_ID → $AMOSTRA"
N=$(zcat $FQ | awk 'NR%4==1' | wc -l)
echo "  $N reads"
SLURM

sbatch scripts/slurm/03_array_qc.sh
squeue                         # 4 jobs aparecem na fila ao mesmo tempo

# Cada tarefa gera seu próprio arquivo de log
ls logs/array_*.out
cat logs/array_*_1.out         # output da tarefa 1 (Arapaima)
cat logs/array_*_3.out         # output da tarefa 3 (Manacus)


# --- B.9. Controlar e monitorar jobs -----------------------------------------
sacct                          # histórico de todos os jobs desta sessão
sacct --format=JobID,JobName,State,ExitCode,Elapsed   # colunas úteis para diagnóstico

# scancel <JOB_ID>             → cancela um job específico
# scancel -u $USER             → cancela todos os seus jobs de uma vez


# =============================================================================
#  QUANDO USAR CADA UM
#
#  tmux  → Codespace / servidor próprio / sessão interativa
#           watch -n2 squeue · htop · processo longo sem scheduler
#
#  SLURM → Cluster compartilhado (Archaea/UFC, LNCC Santos Dumont)
#           Jobs pesados · múltiplas amostras em paralelo · controle de recursos
#
#  Nesta aula: tmux para organizar a tela + SLURM single-node no Codespace
# =============================================================================