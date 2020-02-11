#!/bin/bash

# Set current folder as home
HOME="`cd $0 >/dev/null 2>&1; pwd`" >/dev/null 2>&1

# Clean build folder
#sudo rm -rf $HOME/qt514_build

# Create build folders
mkdir -p $HOME/qt514/src
mkdir -p $HOME/qt514_build

# Check source packages
cd $HOME/qt514
if ! [ -f qt-everywhere-src-5.14.1.tar.xz ]; then
    wget https://download.qt.io/official_releases/qt/5.14/5.14.1/single/qt-everywhere-src-5.14.1.tar.xz
fi

# Unpack source
cd $HOME/qt514/src
if ! [ -d qt-everywhere-src-5.14.1 ]; then
    echo "Unpacking archive..."
    pv -p -w 80 $HOME/qt514/qt-everywhere-src-5.14.1.tar.xz | tar -J -xf - -C $HOME/qt514/src
fi

# Switch to build directory and build
cd $HOME/qt514_build

PKG_CONFIG_LIBDIR=/usr/lib/arm-linux-gnueabihf/pkgconfig:/usr/share/pkgconfig \
$HOME/qt514/src/qt-everywhere-src-5.14.1/configure -device linux-rasp-pi3-vc4-g++ \
-device-option CROSS_COMPILE=arm-linux-gnueabihf- \
-sysroot / \
-v \
-opengl es2 -eglfs -linuxfb -kms \
-no-gtk \
-opensource -confirm-license -release \
-reduce-exports \
-force-pkg-config \
-nomake examples -no-compile-examples \
-skip qtscript \
-skip qtwayland \
-skip qtwebengine \
-no-feature-geoservices_mapboxgl \
-qt-pcre \
-no-pch \
-ssl \
-evdev \
-system-freetype \
-fontconfig \
-glib \
-prefix /usr/local/qt5 \
-qpa eglfs

if [ $? -eq 0 ]; then
    sudo make -j2

    if [ $? -eq 0 ]; then
        sudo rm -rf /usr/local/qt5
        sudo make install
    else
        echo "make failed"
    fi
else
    echo "configure failed"
fi

cd $HOME
