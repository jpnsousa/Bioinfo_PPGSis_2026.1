#! /usr/bin/env bash
# Função para contar o número de reads
echo "especie reads" > ./contagem.tsv
for SAMPLE in *R1.fastq.gz; do
	NOME=$(basename $SAMPLE _R1.fastq.gz)
	N=$(zcat $SAMPLE | grep -c "^@")
	echo "$NOME $N" >> ./contagem.tsv
	echo "$NOME: $N reads"
done 
