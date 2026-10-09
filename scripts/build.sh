#!/usr/bin/env bash
set -euo pipefail
revision=d3b18f7f7a8866aad231555bdedf056b4780f564
mkdir -p output .cache/cargo .cache/ccache
export CARGO_HOME="$PWD/.cache/cargo"
export CCACHE_DIR="$PWD/.cache/ccache"
export CCACHE_BASEDIR="$PWD" CCACHE_MAXSIZE=2G
export VCPKG_MAX_CONCURRENCY=3 CARGO_BUILD_JOBS=3
git init source
git -C source remote add origin https://github.com/LadybirdBrowser/ladybird.git
git -C source fetch --depth 1 origin "$revision"
git -C source checkout --detach FETCH_HEAD
git -C source apply ../patches/*.patch
cd source
python3 Meta/ladybird.py vcpkg --preset Release --jobs 3
cmake --preset Release \
    -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
    -DLAGOM_USE_LINKER=mold -DLAGOM_LINK_POOL_SIZE=1 \
    -DENABLE_CI_BASELINE_CPU=ON \
    -DENABLE_LTO_FOR_RELEASE=OFF -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_PREFIX=/opt/ladybird \
    -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=OFF \
    2>&1 | tee ../output/configure.log
/usr/bin/time -v cmake --build Build/release --target ladybird --parallel 3 \
    2>&1 | tee ../output/build.log
ccache --show-stats
cmake --install Build/release --strip --component ladybird_Runtime --prefix ../package

# Bundle only the third-party libraries built by vcpkg; use Fedora's system Qt.
mkdir -p ../package/lib ../package/licenses/vcpkg
find Build/release/vcpkg_installed -path '*/lib/*.so*' -maxdepth 4 \
    -exec cp -a -t ../package/lib -- {} +
for copyright in Build/release/vcpkg_installed/*/share/*/copyright; do
    [[ -f "$copyright" ]] || continue
    port="$(basename "$(dirname "$copyright")")"
    cp "$copyright" "../package/licenses/vcpkg/$port.txt"
done
cp LICENSE ../package/licenses/Ladybird.txt

# Keep the install package relocatable; helper processes use the same lib directory.
while IFS= read -r -d '' binary; do
    if file -b "$binary" | grep -q '^ELF'; then
        patchelf --set-rpath '$ORIGIN:$ORIGIN/../lib' "$binary"
    fi
done < <(find ../package/bin ../package/libexec ../package/lib -type f -print0)
QT_QPA_PLATFORM=offscreen ../package/bin/Ladybird --help > ../output/smoke.log 2>&1
QT_QPA_PLATFORM=offscreen timeout 60 ../package/bin/Ladybird \
    --headless=text --temporary-profile --force-cpu-painting \
    "file://$PWD/../regression/empty-display.html" > ../output/empty-display.log 2>&1
cat ../output/empty-display.log
python3 - <<'PY'
from pathlib import Path
result = Path('../output/empty-display.log').read_text()
assert 'FAIL:' not in result, result
assert result.count('PASS:') == 10, result
PY
QT_QPA_PLATFORM=offscreen timeout 60 ../package/bin/Ladybird \
    --headless=text --temporary-profile --force-cpu-painting \
    "file://$PWD/../regression/default-chinese.html" > ../output/default-chinese.log 2>&1
cat ../output/default-chinese.log
python3 - <<'PYLANG'
from pathlib import Path
result = Path('../output/default-chinese.log').read_text()
assert 'FAIL:' not in result and 'PASS: default language is zh-CN' in result, result
PYLANG
printf '%s\n' "$revision" > ../package/SOURCE-REVISION
cp ../PACKAGE-README.txt ../package/README.txt
cd ..
tar -czf output/ladybird-fedora44-x86_64.tar.gz -C package .
