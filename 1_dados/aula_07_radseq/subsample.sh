#!/usr/bin/env bash
for f in 2_demux/Bear_Paw_*.fq 2_demux/Rabbit_Slough_*.fq; do
    sample=$(basename $f)
    echo "Subsampling $sample..."
    seqtk sample -s 42 $f 50000 > 2_demux/subsample/$sample
done