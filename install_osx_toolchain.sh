#!/bin/bash

BINUTILS_VERSION=2.29
GCC_VERSION=7.2.0

# check if brew is installed
command -v brew > /dev/null 2>&1 || { echo >&2 "It seems like brew is not installed on your machine! Head on over to http://brew.sh/ to install it."; exit 1; }

export PREFIX="/opt"
export TARGET=x86_64-pc-elf

# gmp mpfr libmpc
brew install gmp mpfr libmpc autoconf automake nasm xorriso qemu

TEMPDIR=$(mktemp -d)
cd $TEMPDIR

BINUTILS_TOOLS="addr2line ar as c++filt elfedit gprof ld ld.bfd nm objcopy objdump ranlib readelf size strings strip"

BINUTILS_TOOLS_ARRAY=($BINUTILS_TOOLS)

# install binutils
if [ ! -d "binutils-${BINUTILS_VERSION}" ]; then
    echo ""
    echo "Installing \`binutils\`"
    echo ""
    curl http://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz > binutils-${BINUTILS_VERSION}.tar.gz
    tar xfz binutils-${BINUTILS_VERSION}.tar.gz
    rm binutils-${BINUTILS_VERSION}.tar.gz
    mkdir -p build-binutils
    cd build-binutils
    ../binutils-${BINUTILS_VERSION}/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror
    make
    sudo make install
fi

cd $TEMPDIR

# install gcc
if [ ! -d "gcc-${GCC_VERSION}" ]; then
    echo ""
    echo "Installing \`gcc-${GCC_VERSION}\`"
    echo ""
    curl -L http://ftpmirror.gnu.org/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz > gcc-${GCC_VERSION}.tar.gz
    tar xfz gcc-${GCC_VERSION}.tar.gz
    rm gcc-${GCC_VERSION}.tar.gz
    mkdir -p build-gcc
    cd build-gcc
    ../gcc-${GCC_VERSION}/configure --target="$TARGET" --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --without-headers --with-gmp="$(brew --prefix gmp)" --with-mpfr="$(brew --prefix mpfr)" --with-mpc="$(brew --prefix libmpc)"
    make all-gcc
    make all-target-libgcc
    sudo make install-gcc
    sudo make install-target-libgcc
fi

cd $TEMPDIR

# install objconv
if [ ! -d "objconv"  ]; then
    echo ""
    echo "Installing \`objconv\`"
    echo ""
    curl http://www.agner.org/optimize/objconv.zip > objconv.zip
    mkdir -p build-objconv
    unzip objconv.zip -d build-objconv
    cd build-objconv
    unzip source.zip -d src
    g++ -o objconv -O2 src/*.cpp --prefix="$PREFIX"
    sudo cp objconv "$PREFIX/bin"
fi

cd $TEMPDIR

# install grub
if [ ! -d "grub"  ]; then
    echo ""
    echo "Installing \`grub\`"
    echo ""
    git clone --depth 1 git://git.savannah.gnu.org/grub.git
    cd grub
    sh autogen.sh
    mkdir -p build-grub
    cd build-grub
    ../configure --disable-werror TARGET_CC=$TARGET-gcc TARGET_OBJCOPY=$TARGET-objcopy \
        TARGET_STRIP=$TARGET-strip TARGET_NM=$TARGET-nm TARGET_RANLIB=$TARGET-ranlib --target=$TARGET --prefix="$PREFIX"
    make
    sudo make install
fi
