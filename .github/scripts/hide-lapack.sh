#!/usr/bin/env bash
# Put BLAS/LAPACK where only LD_LIBRARY_PATH can reach it — the shape an HPC
# `module load` produces, and the precondition for the nbafrank/uvr#228 repro.
#
# The trap this replaces: on Ubuntu the real libraries live in the alternatives
# subdirectories (/usr/lib/x86_64-linux-gnu/lapack/, .../blas/), while
# /usr/lib/x86_64-linux-gnu/liblapack.so* are just update-alternatives symlinks.
# Moving the symlinks leaves the real file exactly where the loader finds it, so
# the repro passes for the wrong reason and reports the bug as fixed.
set -euo pipefail

ARCH_DIR=/usr/lib/$(uname -m)-linux-gnu
sudo apt-get install -y libblas-dev liblapack-dev gfortran
sudo mkdir -p /opt/blas

for d in lapack blas; do
  if [ -d "$ARCH_DIR/$d" ]; then
    # -a keeps the versioned file plus its relative soname symlink.
    sudo cp -a "$ARCH_DIR/$d/." /opt/blas/
    sudo rm -rf "${ARCH_DIR:?}/$d"
  fi
done
sudo rm -f "$ARCH_DIR"/liblapack.so* "$ARCH_DIR"/libblas.so*
sudo ldconfig

# Preconditions, both required. Without the first the repro proves nothing;
# without the second it fails for the trivial reason that LAPACK is simply gone.
if ldconfig -p | grep -qE 'lib(lapack|blas)\.so'; then
  echo "hide-lapack: still resolvable through the loader cache" >&2
  ldconfig -p | grep -E 'lib(lapack|blas)\.so' >&2
  exit 1
fi
test -e /opt/blas/liblapack.so.3 || { echo "hide-lapack: /opt/blas/liblapack.so.3 missing" >&2; exit 1; }

echo "hide-lapack: BLAS/LAPACK reachable only via LD_LIBRARY_PATH=/opt/blas"
