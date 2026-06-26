#!/usr/bin/env bash

for f in 2_demux/subsample/*.fq; do
    n=$(cat "$f" | wc -l)
    echo "$(basename $f .fq): $(( n/4 )) reads"
done
