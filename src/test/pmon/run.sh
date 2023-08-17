#!/bin/bash
export CHIPLAB_HOME=/mnt/disk-1/chiplabs/chiplab_bin
cd ./sims/verilator/run_prog
make clean_all
./configure.sh --run bin_program --threads --dump-fst --slice-waveform --waveform-slice-size 10000000 --slice-simu-trace --trace-slice-size 10000000
make # > out.txt (可选)
