#!/usr/bin/env bash
set -euo pipefail
dnf install -y \
    clang gcc gcc-c++ mold rust cargo python3 autoconf autoconf-archive automake \
    ccache cmake curl git libdrm-devel liberation-sans-fonts libglvnd-devel \
    libtool nasm ncurses-devel ninja-build patchelf perl-FindBin perl-IPC-Cmd \
    perl-lib perl-Time-Piece pulseaudio-libs-devel qt6-qtbase-private-devel \
    qt6-qtpositioning-devel qt6-qttools-devel qt6-qtwayland-devel \
    tar unzip zip zlib-ng-compat-static pkgconf-pkg-config glslang \
    which findutils file time shadow-utils util-linux
useradd --create-home builder
chown -R builder:builder /work
exec runuser -u builder -- bash scripts/build.sh
