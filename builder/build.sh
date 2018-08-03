#!/bin/bash
set -e

export CXX="/usr/lib/ccache/clang++"
export CC="/usr/lib/ccache/clang"

cd /src
autoconf
./configure --prefix /usr/local
make

ccache -M10G
make install
mkdir -p /usr/local/bin
cp tinyows /usr/local/bin/
ccache -s
