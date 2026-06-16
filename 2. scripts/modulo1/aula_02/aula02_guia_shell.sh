#!/usr/bin/env bash
# =============================================================================
#  GUIA DE AULA — Módulos 1 e 2: Unix + Shell Avançado
#  CHS0007 · Bioinformática · PPGSIS/UFC · Aula 2
#
#  Biodiversidade temática: Arapaima gigas, Bothrops jararaca,
#                           Manacus manacus, Podocnemis expansa
# 
# =============================================================================


# =============================================================================
#  BLOCO 0 — ATUALIZAR REPOSITÓRIO
# =============================================================================

cd ~/Bioinfo_PPGSis_2026.1

git remote -v                    # confirmar: origin = seu fork, upstream = professor
git fetch upstream               # baixa as atualizações do professor sem aplicar ainda
git checkout main                # garante que estamos no branch principal
git merge upstream/main          # aplica as atualizações baixadas
git push origin main             # sobe as atualizações para o seu fork no GitHub

git status                       # deve estar limpo (nada para commitar)


# =============================================================================
#  BLOCO 1 — NAVEGANDO NO SISTEMA DE ARQUIVOS
# =============================================================================

# --- 1.1 Onde estou? O que tem aqui? ----------------------------------------
pwd                              # print working directory: mostra o caminho completo de onde você está
ls                               # lista o conteúdo do diretório atual
ls -lh                           # -l: formato longo (permissões, tamanho, data)  -h: tamanho legível (KB, MB)
ls -a                            # -a: mostra arquivos ocultos (os que começam com ponto, ex: .gitignore)
ls -lhF                          # combinar flags: F adiciona / em pastas e * em executáveis

# --- 1.2 Navegar na árvore de diretórios ------------------------------------
cd 1.dados/brutos/aula_02/       # cd (change directory): entra na pasta dos FASTQs da aula
pwd                              # confirmar onde estamos
ls                               # ver os arquivos disponíveis

cd ..                            # .. significa "pasta acima": sobe um nível
cd ../..                         # sobe dois níveis de uma vez
cd ~                             # ~ é o atalho para o home do usuário (/home/usuario)
cd -                             # volta à pasta anterior (muito útil para alternar entre duas pastas!)

# --- 1.3 Caminhos absolutos vs relativos ------------------------------------
# Relativo: começa de onde você está agora, muda se você mudar de pasta
ls ../../2.resultados/
# Absoluto: começa sempre da raiz (~), funciona de qualquer lugar
ls ~/Bioinfo_PPGSis_2026.1/2.resultados/

# --- 1.4 Criar estrutura de projeto -----------------------------------------
# -p cria pastas intermediárias se não existirem, e não dá erro se já existir
mkdir -p 2.resultados/qc
mkdir -p logs
ls                               # confirmar que as pastas foram criadas

# --- 1.5 Ver conteúdo de arquivos -------------------------------------------
cd 1.dados/brutos/aula_02/

# Arquivos .fastq.gz estão comprimidos: usar zcat em vez de cat
# zcat descomprime na memória e manda para o terminal sem criar arquivo temporário
# | (pipe) conecta a saída de um comando à entrada do próximo
zcat Arapaima_gigas_R1.fastq.gz | head -8    # primeiros 2 reads (cada read = 4 linhas)
zcat Arapaima_gigas_R1.fastq.gz | tail -4    # últimas 4 linhas

# --- 1.6 Wildcards (globbing) -----------------------------------------------
# Wildcards são padrões que o shell expande para nomes de arquivos antes de executar o comando
# * substitui qualquer sequência de caracteres (inclusive nenhum)
ls *.fastq.gz                    # todos os arquivos que terminam em .fastq.gz
ls *_R1*.fastq.gz                # só os R1 (forward reads)
ls Arapaima*                     # qualquer arquivo que começa com "Arapaima"
ls *expansa*                     # qualquer arquivo que contém "expansa" em qualquer posição

# --- 1.7 Copiar, mover, remover ---------------------------------------------
cp Arapaima_gigas_R1.fastq.gz /tmp/teste.fastq.gz     # cp: copia o arquivo para outro caminho
ls /tmp/teste.fastq.gz                                 # confirmar que a cópia existe
rm /tmp/teste.fastq.gz           # rm: remove permanentemente — não vai para lixeira, cuidado!
# mv arquivo.txt novo_nome.txt   # mv renomeia quando origem e destino estão na mesma pasta
# mv arquivo.txt outra_pasta/    # mv move quando o destino é uma pasta diferente

# --- 1.8 Primeiro loop ------------------------------------------------------
# O loop for percorre uma lista de itens, um por vez
# A cada volta, a variável $ARQUIVO recebe o próximo item da lista
# do ... done delimita o bloco de comandos que se repete
for ARQUIVO in especies.fasta amostras.tsv; do
    echo "Processando: $ARQUIVO"
done

# --- 1.9 Atalhos de teclado essenciais --------------------------------------
# Tab         → autocompletar nome de arquivo ou comando
# Ctrl+A      → ir para o início da linha
# Ctrl+E      → ir para o final da linha
# Ctrl+C      → cancelar o comando atual
# Ctrl+L      → limpar a tela (equivale a clear)
# ↑ ↓         → navegar no histórico de comandos
# Ctrl+R      → buscar no histórico


# =============================================================================
#  BLOCO 2 — MANIPULAÇÃO DE TEXTO: cut · sort · uniq · sed · awk
# =============================================================================

# --- 2.1 cut + sort + uniq — resumir colunas --------------------------------
# cut recorta colunas de um arquivo; -f 2 seleciona a 2ª coluna (field)
# por padrão, cut usa Tab como separador (ideal para arquivos .tsv)
cut -f 2 amostras.tsv                    # extrai só a 2ª coluna (espécie)
cut -f 2 amostras.tsv | sort             # passa para sort: ordena alfabeticamente
cut -f 2 amostras.tsv | sort | uniq      # uniq remove linhas duplicadas consecutivas
cut -f 2 amostras.tsv | sort | uniq -c   # -c: conta quantas vezes cada valor aparece

# --- 2.2 sed — substituir em fluxo -----------------------------------------
# sed processa o texto linha a linha sem alterar o arquivo original
# s/padrão/substituto/ é a sintaxe de substituição
sed 's/onca/onça/' especies.fasta        # substitui a primeira ocorrência por linha
sed '1d' amostras.tsv                    # d de delete: remove a linha 1 (o cabeçalho)

# --- 2.3 awk — trabalhar por colunas ----------------------------------------
# awk divide cada linha em campos ($1, $2, $3...)
# -F'\t' define Tab como separador de campos
# NR é o número da linha atual; $4 é o valor da 4ª coluna
awk -F'\t' '{print $1}' amostras.tsv                    # imprime só a 1ª coluna (id)
awk -F'\t' '{print $2, $4}' amostras.tsv                # imprime espécie e nº de reads
awk -F'\t' 'NR>1 && $4 > 1000000' amostras.tsv          # NR>1 pula o cabeçalho; filtra reads > 1 M
awk -F'\t' '$3 == "solo"' amostras.tsv                  # filtra linhas onde a 3ª coluna é "solo"

# --- 2.4 Salvar resultados com redirecionamento -----------------------------
# grep busca linhas que contêm um padrão
# em FASTA, linhas de cabeçalho começam com >
# > redireciona a saída para um arquivo (cria ou sobrescreve)
grep ">" especies.fasta > cabecalhos.txt
cat cabecalhos.txt                       # cat imprime o conteúdo do arquivo no terminal

# --- 2.5 Combinando tudo: amostras por local com > 1 M de reads ------------
# {print $3} imprime só a coluna de local para as linhas filtradas
# o resultado é então ordenado e contado
awk -F'\t' 'NR>1 && $4 > 1000000 {print $3}' amostras.tsv | sort | uniq -c


# =============================================================================
#  BLOCO 3 — INSPECIONAR E CONTAR READS
# =============================================================================

# --- 3.1 Estrutura de um arquivo FASTQ --------------------------------------
# Cada read ocupa exatamente 4 linhas:
#   Linha 1: cabeçalho (começa com @)
#   Linha 2: sequência de bases (A, T, C, G, N)
#   Linha 3: separador (sempre +)
#   Linha 4: qualidades Phred (um caractere por base)
#
# NR%4==1 é verdadeiro apenas para as linhas 1, 5, 9, 13... (os cabeçalhos)
# wc -l conta o número de linhas que chegam — cada uma é um read
zcat Arapaima_gigas_R1.fastq.gz     | awk 'NR%4==1' | wc -l
zcat Bothrops_jararaca_R1.fastq.gz  | awk 'NR%4==1' | wc -l
zcat Manacus_manacus_R1.fastq.gz    | awk 'NR%4==1' | wc -l
zcat Podocnemis_expansa_R1.fastq.gz | awk 'NR%4==1' | wc -l

# --- 3.2 grep — buscar padrões ----------------------------------------------
# ^ significa "começa com" (âncora de início de linha)
# -c conta as linhas que combinam em vez de imprimi-las
zcat Arapaima_gigas_R1.fastq.gz | grep '^@' | head -5   # mostra os 5 primeiros cabeçalhos
zcat Arapaima_gigas_R1.fastq.gz | grep -c '^@'           # conta todos os cabeçalhos
zcat Controle_negativo_R1.fastq.gz | grep -c '^N'        # conta linhas de sequência que começam com N


# =============================================================================
#  BLOCO 4 — REDIRECIONAMENTO E PIPES
# =============================================================================

# --- 4.1 Redirecionar saída para arquivo ------------------------------------
# >   cria o arquivo (ou apaga e recria se já existir)
# >>  abre o arquivo e adiciona ao final, sem apagar o que já estava
#
# \t dentro de $'...' é um Tab real — necessário para criar um .tsv válido
echo "amostra	reads" > ~/Bioinfo_PPGSis_2026.1/2.resultados/contagem.tsv

# basename remove o caminho e o sufixo, deixando só o nome da amostra
# ex: 1.dados/brutos/aula_02/Arapaima_gigas_R1.fastq.gz → Arapaima_gigas
for FQ in *_R1.fastq.gz; do
    NOME=$(basename $FQ _R1.fastq.gz)
    N=$(zcat $FQ | awk 'NR%4==1' | wc -l)
    echo "$NOME	$N" >> ~/Bioinfo_PPGSis_2026.1/2.resultados/contagem.tsv
done

cat ~/Bioinfo_PPGSis_2026.1/2.resultados/contagem.tsv    # ver resultado

# --- 4.2 Redirecionar erros (stderr) ----------------------------------------
# Todo comando tem dois canais de saída:
#   stdout (1): saída normal — o que o comando produziu
#   stderr (2): erros e avisos — separado para não misturar com os resultados
# fastqc amostra.fastq.gz -o qc/  2>> logs/fastqc.err   # grava só os erros no log
# comando > saida.txt 2>&1        # 2>&1 junta stderr no mesmo destino que stdout

# --- 4.3 sort e cut — ordenar e selecionar colunas --------------------------
# -k2 ordena pelo 2º campo (coluna de reads)   -n ordena numericamente (não alfabeticamente)
sort -k2 -n ~/Bioinfo_PPGSis_2026.1/2.resultados/contagem.tsv
# -f1 extrai só a primeira coluna (nomes das amostras)
cut -f1 ~/Bioinfo_PPGSis_2026.1/2.resultados/contagem.tsv


# =============================================================================
#  BLOCO 5 — SHELL AVANÇADO: VARIÁVEIS, LOOPS E CONDICIONAIS
# =============================================================================

# --- 5.1 Variáveis ----------------------------------------------------------
cd ~/Bioinfo_PPGSis_2026.1

# Variáveis guardam valores para reusar — sem espaço em volta do =
DADOS="1.dados/brutos/aula_02"
RESULTADOS="2.resultados"
THREADS=4

echo "Dados em: $DADOS"
echo "Resultados em: $RESULTADOS"

# $() executa o comando dentro e captura a saída como valor
DATA=$(date +%Y-%m-%d)
NSAMPLES=$(ls $DADOS/*_R1.fastq.gz | wc -l)

echo "Data: $DATA — $NSAMPLES amostras"

export THREADS                   # export faz a variável ser herdada por subprocessos

# --- 5.2 Loop for sobre os FASTQs -------------------------------------------
# basename remove o caminho completo e o sufixo passado como 2º argumento:
#   1.dados/brutos/aula_02/Arapaima_gigas_R1.fastq.gz → Arapaima_gigas
for FQ in $DADOS/*_R1.fastq.gz; do
    NOME=$(basename $FQ _R1.fastq.gz)
    N=$(zcat $FQ | awk 'NR%4==1' | wc -l)
    echo "$NOME: $N reads"
done

# --- 5.3 Loop while lendo lista de amostras ---------------------------------
# xargs -I{} substitui {} pelo nome de cada arquivo e executa basename
# o resultado é salvo em lista_amostras.txt, um nome por linha
ls $DADOS/*_R1.fastq.gz | xargs -I{} basename {} _R1.fastq.gz \
    > lista_amostras.txt

cat lista_amostras.txt           # conferir

# IFS= read -r lê uma linha por vez sem modificar espaços ou barras invertidas
# < lista_amostras.txt alimenta o while com o conteúdo do arquivo
while IFS= read -r AMOSTRA; do
    FQ="$DADOS/${AMOSTRA}_R1.fastq.gz"
    N=$(zcat $FQ | awk 'NR%4==1' | wc -l)
    echo "$AMOSTRA → $N reads"
done < lista_amostras.txt

# --- 5.4 Condicionais (if / elif / else) ------------------------------------
# Shell usa operadores por extenso para comparar números (não < > como em Python/R):
# -lt   less than        (menor que)
# -gt   greater than     (maior que)
# -le   less or equal    (menor ou igual)
# -ge   greater or equal (maior ou igual)
# -eq   equal            (igual)
# -ne   not equal        (diferente)
#
# [ ] é onde a condição fica — os espaços internos são obrigatórios
# ; then fecha a linha do if quando está na mesma linha que a condição

for FQ in $DADOS/*_R1.fastq.gz; do
    NOME=$(basename $FQ _R1.fastq.gz)
    N=$(zcat $FQ | awk 'NR%4==1' | wc -l)

    if [ $N -lt 1000 ]; then
        echo "REPROVADA  $NOME: apenas $N reads — não usar"
    elif [ $N -lt 1500 ]; then
        echo "ATENÇÃO    $NOME: $N reads — baixa cobertura"
    else
        echo "OK         $NOME: $N reads"
    fi
done


# =============================================================================
#  BLOCO 6 — FUNÇÕES
# =============================================================================

# Uma função agrupa comandos com um nome reutilizável
# $1 é o primeiro argumento passado na chamada da função
# local limita a variável ao escopo da função — ela não vaza para o script
contar_reads() {
    local N=$(zcat $1 | awk 'NR%4==1' | wc -l)
    echo "$1 tem $N reads"
}

# Agora adicionando timestamp: date '+%Y-%m-%d %H:%M:%S' formata data e hora
# local ARQ=$1 dá um nome legível ao argumento em vez de usar $1 direto
contar_reads() {
    local ARQ=$1
    local N=$(zcat $ARQ | awk 'NR%4==1' | wc -l)
    local DATA=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$DATA] $ARQ tem $N reads"
}

# Usando a função com loop: a cada iteração, $FQ é passado como $1 para a função
for FQ in $DADOS/*_R1.fastq.gz; do
    contar_reads $FQ
done

# O resultado é o mesmo, mas agora a lógica de contar reads está encapsulada na função,o que torna o código mais organizado e reutilizável.
# Criando arquivo executável para permitir reproduzir facilmente sem precisar copiar e colar o código da função toda vez:

nano contar_reads.sh
#!/usr/bin/env bash
# contar_reads.sh — conta reads em arquivos FASTQ comprimidos
# Uso: bash contar_reads.sh caminho/para/pasta/

DADOS=${1:-"1.dados/brutos/aula_02"}

contar_reads() {
    local ARQUIVO=$1
    local N=$(zcat $ARQUIVO | awk 'NR%4==1' | wc -l)
    echo "$ARQUIVO tem $N reads"
}

for FQ in $DADOS/*_R1.fastq.gz; do
    contar_reads "$FQ"
done

bash contar_reads.sh  # executa o script passando a pasta como argumento


# =============================================================================
#  RESUMO RÁPIDO — Referência de comandos
# -----------------------------------------------------------------------------
#  Sistema de arquivos:   pwd · ls · cd · mkdir · cp · mv · rm
#  Inspecionar arquivos:  head · tail · less · zcat · wc
#  Wildcards:             * ? [abc]
#  Redirecionamento:      > (sobrescreve) · >> (acrescenta) · 2> (stderr)
#  Pipes:                 | conecta stdout de um ao stdin do próximo
#  Filtrar:               grep (padrão) · sed (substituir) · awk (colunas)
#  Ordenar/resumir:       sort · cut · uniq · uniq -c
#  Variável:              NOME=valor · $NOME · $(comando) · $((expressão))
#  Loop for:              for X in lista; do ... done
#  Loop while:            while IFS= read -r X; do ... done < arquivo
#  Condicional:           if [ cond ]; then ... elif ... else ... fi
#  Função:                nome() { local X=$1; ... }
# =============================================================================