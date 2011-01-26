#!/bin/sh

set -ex
cd $(dirname $0)
mkdir -p work

for f in src/*.vhdl ; do
	ghdl -a --workdir=work  $f
done
ghdl -e --workdir=work tb_hcount

