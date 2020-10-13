#!/bin/bash

# Set variables
QT_URL=https://download.qt.io/official_releases/qt/
QT_VERSION=$(curl -s $QT_URL | grep -oE -m1 href=\"[0-9\.]+ |  tr -d 'href="')
QT_FULL_VERSION=$(curl -s $QT_URL$QT_VERSION/ | grep -oE -m1 href=\"[0-9\.]+ |  tr -d 'href="')
QT_FILENAME=qt-everywhere-src-${QT_FULL_VERSION}.tar.xz
DEVICE_OPT=linux-rasp-pi4-v3d-g++
CPU_CORES_COUNT=`grep -c ^processor /proc/cpuinfo`

# Set current folder as home
HOME="`cd $0 >/dev/null 2>&1; pwd`" >/dev/null 2>&1

QT_FILE_VERSION=$(echo $QT_VERSION | tr -d '.')

echo "Building latest QT version: $QT_FULL_VERSION with EGL support"

# Clean build folder
#sudo rm -rf ${HOME}/qt${QT_FILE_VERSION}_build

# Create build folders
mkdir -p ${HOME}/qt${QT_FILE_VERSION}/src
mkdir -p ${HOME}/qt${QT_FILE_VERSION}_build

# Check source packages
cd ${HOME}/qt${QT_FILE_VERSION}
if ! [ -f ${QT_FILENAME} ]; then
    wget ${QT_URL}${QT_VERSION}/${QT_FULL_VERSION}/single/${QT_FILENAME}
fi

# Unpack source
cd ${HOME}/qt${QT_FILE_VERSION}/src

if ! [ -d qt-everywhere-src-${QT_FULL_VERSION} ]; then
    echo "Unpacking archive..."
    pv -p -w 80 ${HOME}/qt${QT_FILE_VERSION}/${QT_FILENAME} | tar -J -xf - -C ${HOME}/qt${QT_FILE_VERSION}/src
fi

# Switch to build directory and build
cd ${HOME}/qt${QT_FILE_VERSION}_build

PKG_CONFIG_LIBDIR=/usr/lib/arm-linux-gnueabihf/pkgconfig:/usr/share/pkgconfig \
${HOME}/qt${QT_FILE_VERSION}/src/qt-everywhere-src-${QT_FULL_VERSION}/configure -device ${DEVICE_OPT} \
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
    sudo make -j$CPU_CORES_COUNT
    if [ $? -eq 0 ]; then
        sudo rm -rf /usr/local/qt5
        sudo make install
        echo "Building of QT $QT_FULL_VERSION finished successfully."
    else
        echo "make failed"
    fi
else
    echo "configure failed"
fi

cd ${HOME}
