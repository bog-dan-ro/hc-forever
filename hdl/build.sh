#!/bin/sh

set -ex
cd $(dirname $0)
mkdir -p work

for f in src/*.vhdl ; do
	ghdl -a --workdir=work $f
done
for f in src/sim/*.vhdl ; do
	ghdl -a --workdir=work $f
done
for f in src/sim/tb_* ; do
	module=$(basename $f | sed -e 's/\.vhdl$//')
	ghdl -e --workdir=work $module
done


