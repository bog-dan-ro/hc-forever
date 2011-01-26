#!/bin/sh

set -ex
cd $(dirname $0)
mkdir -p work

for f in src/*.vhdl ; do
	ghdl -a --workdir=work  $f
done
for module in tb_hcount tb_vcount tb_syncgen ; do
	ghdl -e --workdir=work $module
done


