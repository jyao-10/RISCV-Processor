#!/bin/bash
ECE411_SOFTWARE=/class/ece411/software
export PATH=$PATH:$ECE411_SOFTWARE/riscv-tools/bin:$ECE411_SOFTWARE/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ECE411_SOFTWARE/lib64:$ECE411_SOFTWARE/riscv-tools/lib
export PYTHONPATH=$PYTHONPATH:$ECE411_SOFTWARE/python2.7/site-packages
module load altera/13.1
quartus >/dev/null 2>/dev/null &

