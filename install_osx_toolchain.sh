#!/bin/bash

# environment           description                                 default
# variable
# ------------------------------------------------------------------------------------
# PREFIX                Directory where all the tools               /opt
#                       would be installed
# GCC_VERSION           GCC version that needs to be installed      7.2.0
# BINUTILS_VERSION      BINUTILS version that needs to be installed 2.29
# TARGET                Target architecture for which all the       x86_64-pc-elf
#                       tools would be build and installed

BINUTILS_VERSION=${BINUTILS_VERSION:="2.29"}
GCC_VERSION=${GCC_VERSION:="7.2.0"}

# check if brew is installed
command -v brew > /dev/null 2>&1 || { echo >&2 "It seems like brew is not installed on your machine! Head on over to http://brew.sh/ to install it."; exit 1; }

PREFIX=${PREFIX:="/opt"}
TARGET=${TARGET:="x86_64-pc-elf"}
export PATH="$PREFIX/bin:$PATH"

# gmp mpfr libmpc
brew install gmp mpfr libmpc autoconf automake nasm xorriso qemu

TEMPDIR=$(mktemp -d)

install_binutils () {
    cd $TEMPDIR
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
}

install_gcc () {
    cd $TEMPDIR
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
}

install_objconv () {
    cd $TEMPDIR
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
}

install_grub () {
    cd $TEMPDIR
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
}

BINUTILS_TOOLS=( addr2line ar as c++filt elfedit gprof ld ld.bfd nm objcopy objdump ranlib readelf size strings strip )

# install binutils
for i in "${BINUTILS_TOOLS[@]}"
do
    if ! [ -x "$(command -v ${TARGET}-${i})" ]; then
        install_binutils
        break
    fi
done

# install gcc
if ! [ -x "$(command -v ${TARGET}-gcc)" ]; then
    install_gcc
fi

# install objconv
if ! [ -x "$(command -v objconv)" ]; then
    install_objconv
fi

# install grub
if ! [ -x "$(command -v grub-mkrescue)" ]; then
    install_grub
fi
