#!/usr/bin/env bash

# Rodar o Prokka no contig limpo
# --kingdom Viruses  → ajusta o banco de dados interno para vírus
# --proteins         → usa as proteínas da referência NC_045512.2 como âncora
# --prefix           → nome base de todos os arquivos de saída
# --outdir           → pasta de saída
# --force            → sobrescrever se rodar mais de uma vez
# --cpus 2           → número de núcleos disponíveis no Codespace
prokka \
    3.seqkit/sars_rc_genome.fasta \
    --kingdom Viruses \
    --proteins 1.genome_ref/ref_NC_045512.2_proteinas.faa \
    --prefix sars_anotado \
    --outdir 4.prokka/ \
    --force \
    --cpus 2
