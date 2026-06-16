# =============================================================================
#  ESPELHO — Shell para Bioinformática (digitar junto em aula)
#  CHS0007 · Bioinformática · PPGSIS/UFC · Aula 2
#
#  Como usar: rode UMA VEZ o bloco de preparação abaixo; depois digite os
#  demais comandos UM POR VEZ, observando a saída antes de seguir.
# =============================================================================


# --- 1. Navegar entre pastas (antes de manipular os dados) -------------------
pwd                                      # onde estou?
ls                                       # o que há aqui? (deve listar os arquivos criados)
ls -la                                   # com detalhes e itens ocultos
mkdir -p projeto/dados projeto/scripts   # criar uma estrutura de pastas
ls projeto                               # conferir as subpastas
tree -L 2 projeto || ls -R projeto       # ver em árvore (se faltar tree, usa ls -R)
cd projeto/dados                         # entrar numa subpasta (caminho relativo)
pwd                                      # confirmar que mudei de lugar
cd ../..                                 # subir dois níveis, de volta ao início
pwd                                      # de volta onde estão os dados


# --- 2. Espiar os arquivos sem abri-los --------------------------------------
head especies.fasta            # primeiras 10 linhas
head -n 4 especies.fasta       # só as 4 primeiras
wc -l especies.fasta           # quantas linhas?
cat amostras.tsv               # ver a tabela inteira (é pequena)


# --- 3. grep: encontrar padrões ----------------------------------------------
grep ">" especies.fasta        # só os cabeçalhos
grep -c ">" especies.fasta     # CONTAR sequências (= número de cabeçalhos)
grep -v ">" especies.fasta     # o inverso: só as linhas de sequência
grep -i "onca" especies.fasta  # ignorando maiúsculas/minúsculas


# --- 4. Pipes |: encadear comandos -------------------------------------------
grep ">" especies.fasta | head      # cabeçalhos, e então os primeiros
grep ">" especies.fasta | wc -l     # contar cabeçalhos (mesmo que grep -c)


# --- 5. cut + sort + uniq: resumir colunas -----------------------------------
cut -f 2 amostras.tsv                    # a 2ª coluna (espécie)
cut -f 2 amostras.tsv | sort             # ordenada
cut -f 2 amostras.tsv | sort | uniq      # valores únicos
cut -f 2 amostras.tsv | sort | uniq -c   # quantas amostras por espécie


# --- 6. sed: substituir em fluxo ---------------------------------------------
sed 's/onca/onça/' especies.fasta        # substitui (não altera o arquivo)
sed '1d' amostras.tsv                     # imprime sem a 1ª linha (cabeçalho)


# --- 7. awk: trabalhar por colunas -------------------------------------------
awk -F'\t' '{print $1}' amostras.tsv             # 1ª coluna (id)
awk -F'\t' '{print $2, $4}' amostras.tsv         # espécie e nº de reads
awk -F'\t' 'NR>1 && $4 > 1000000' amostras.tsv   # reads > 1 milhão (NR>1 pula o cabeçalho)
awk -F'\t' '$3 == "solo"' amostras.tsv           # filtrar por local = solo


# --- 8. Redirecionamento: salvar resultados ----------------------------------
grep ">" especies.fasta > cabecalhos.txt   # >  cria/sobrescreve
cat cabecalhos.txt                          # conferir o que foi salvo


# --- 9. Loop for: repetir em vários arquivos ---------------------------------
for arquivo in *.fasta
do
  echo "Sequências em $arquivo:"
  grep -c ">" "$arquivo"
done


# --- 10. Juntando tudo: uma análise numa linha -------------------------------
# Quantas amostras de cada local têm mais de 1 milhão de reads?
awk -F'\t' 'NR>1 && $4 > 1000000 {print $3}' amostras.tsv | sort | uniq -c


# =============================================================================
#  Pense: cada peça é simples; o poder vem de combiná-las com pipes.
#  navegar → ver → grep · cut · sort · uniq · sed · awk · for  →  qualquer análise.
# =============================================================================
