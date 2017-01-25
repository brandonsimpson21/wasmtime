#!/bin/bash

# This is the top-level test script:
#
# - Build documentation for Rust code in 'src/tools/target/doc'.
# - Run unit tests for all Rust crates.
# - Make a debug build of all crates.
# - Make a release build of cton-util.
# - Run file-level tests with the release build of cton-util.
#
# All tests run by this script should be passing at all times.

# Exit immediately on errors.
set -e

# Repository top-level directory.
cd $(dirname "$0")
topdir=$(pwd)

function banner() {
    echo "======  $@  ======"
}

# Run rustfmt if we have it.
#
# Rustfmt is still immature enough that its formatting decisions can change
# between versions. This makes it difficult to enforce a certain style in a
# test script since not all developers will upgrade rustfmt at the same time.
# To work around this, we only verify formatting when a specific version of
# rustfmt is installed.
#
# This version should always be bumped to the newest version available.
RUSTFMT_VERSION="0.6.3"

if cargo install --list | grep -q "^rustfmt v$RUSTFMT_VERSION"; then
    banner "Rust formatting"
    $topdir/format-all.sh --write-mode=diff
else
    echo "Please install rustfmt v$RUSTFMT_VERSION to verify formatting."
    echo "If a newer version of rustfmt is available, update this script."
fi

banner "Python checks"
$topdir/lib/cretonne/meta/check.sh

PKGS="cretonne cretonne-reader cretonne-tools filecheck"
cd "$topdir"
for PKG in $PKGS
do
    banner "Rust $PKG unit tests"
    cargo test -p $PKG
done

# Build cton-util for parser testing.
cd "$topdir"
banner "Rust documentation"
echo "open $topdir/target/doc/cretonne/index.html"
cargo doc
banner "Rust release build"
cargo build --release

export CTONUTIL="$topdir/target/release/cton-util"

cd "$topdir"
banner "File tests"
"$CTONUTIL" test filetests

banner "OK"
