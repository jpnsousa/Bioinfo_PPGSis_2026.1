# Exercícios — Shell Avançado
**CHS0007 · Bioinformática · PPGSIS/UFC · Aula 2**

> Tempo: ~30 minutos · Trabalhe individualmente ou em dupla

---

## Contexto

Você recebeu dados de um experimento clássico de evolução experimental com
*Escherichia coli* (experimento de Lenski, PRJNA294072). São duas amostras
sequenciadas em plataforma Illumina e uma tabela de metadados do SRA.

```
exercicio/
├── dados/
│   ├── SRR097977.fastq     ← amostra 1
│   ├── SRR098026.fastq     ← amostra 2
│   └── SraRunTable.txt     ← metadados das amostras
└── resultados/             ← salve seus resultados aqui
```

Antes de começar:

```bash
cd ~/Bioinfo_PPGSis_2026.1/exercicio
ls dados/
```

---

## Nível 1 — Explorar os arquivos (~ 10 min)

**E1.** Quantas linhas tem cada arquivo `.fastq`?
Dica: `wc -l`

**E2.** Mostre as primeiras 8 linhas do arquivo `SRR098026.fastq`.
O que você consegue identificar sobre a estrutura do arquivo?

**E3.** Quantos reads tem cada amostra?
Lembre: cada read ocupa 4 linhas.

**E4.** Quais são os nomes das colunas do arquivo `SraRunTable.txt`?
Mostre só a primeira linha.

**E5.** Quais tipos de `LibraryLayout` existem na tabela?
Dica: `cut` + `sort` + `uniq`

---

## Nível 2 — Filtrar e redirecionar (~ 10 min)

**E6.** Quantos reads do arquivo `SRR098026.fastq` começam com `N`?
(linhas de sequência que começam com base desconhecida)

**E7.** Extraia todos os cabeçalhos (`@`) do arquivo `SRR098026.fastq`
e salve em `resultados/cabecalhos_SRR098026.txt`.

**E8.** Quantas amostras foram carregadas em cada data (`LoadDate_s`)?
Use `cut`, `sort` e `uniq -c`.

**E9.** Ordene o `SraRunTable.txt` pelo tamanho em Megabases (`MBases_l`)
e salve em `resultados/amostras_ordenadas.txt`.
Dica: `sort -k6 -n`

---

## Nível 3 — Script (~ 10 min)

**E10.** Escreva um script `resultados/checar_qualidade.sh` que:

1. Para cada `.fastq` na pasta `dados/`:
   - Conta o total de reads
   - Conta quantos reads começam com `N`
   - Imprime uma linha como: `SRR098026: 12 reads, 5 com N`

2. Salva o resultado em `resultados/relatorio.txt`

Estrutura sugerida:

```bash
#!/usr/bin/env bash

DADOS="dados"

for FQ in $DADOS/*.fastq; do
    NOME=$(basename $FQ .fastq)
    # seu código aqui
done
```

Execute com:
```bash
bash resultados/checar_qualidade.sh
cat resultados/relatorio.txt
```
