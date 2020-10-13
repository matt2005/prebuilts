#!/bin/bash

# Set variables
QT_URL=https://download.qt.io/official_releases/qt/
QT_VERSION=$(curl -s $QT_URL | grep -oE -m1 href=\"[0-9\.]+ |  tr -d 'href="')
QT_FULL_VERSION=$(curl -s $QT_URL$QT_VERSION/ | grep -oE -m1 href=\"[0-9\.]+ |  tr -d 'href="')
QT_FILENAME=qt-everywhere-src-${QT_FULL_VERSION}.tar.xz
DEVICE_OPT=linux-rasp-pi3-g++
CPU_CORES_COUNT=`grep -c ^processor /proc/cpuinfo`
# Lookup for PI version
PIVERSION=`grep ^Model /proc/cpuinfo` 
if [[ ${PIVERSION} =~ 'Raspberry Pi 3' ]]; then
   DEVICE_OPT=linux-rasp-pi3-g++
   KMS=''
fi
if [[ ${PIVERSION} =~ 'Raspberry Pi 4' ]]; then
   DEVICE_OPT=linux-rasp-pi4-v3d-g++
   KMS='-kms'
fi
# Set current folder as home
HOME="`cd $0 >/dev/null 2>&1; pwd`" >/dev/null 2>&1

QT_FILE_VERSION=$(echo $QT_VERSION | tr -d '.')

echo "Building latest QT version: $QT_FULL_VERSION with EGL support"

# Clean build folder
#sudo rm -rf ${HOME}/qt${QT_FILE_VERSION}_build

# Install Packages
sudo apt-get -y update
sudo apt-get -y upgrade
echo "Install needed packages"
sudo apt-get install git -y
sudo apt-get install -y sense-hat libatspi-dev build-essential libfontconfig1-dev libdbus-1-dev libfreetype6-dev libicu-dev libinput-dev libxkbcommon-dev libsqlite3-dev libssl-dev libpng-dev libjpeg-dev libglib2.0-dev libraspberrypi-dev
sudo apt-get install -y bluez libbluetooth-dev
sudo apt-get install -y libasound2-dev pulseaudio libpulse-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-plugins-bad gstreamer1.0-pulseaudio gstreamer1.0-tools gstreamer1.0-alsa gstreamer-tools
sudo apt-get install -y libpq-dev libmariadbclient-dev clang
sudo apt-get install -y libegl1-mesa-dev libgbm-dev libgles2-mesa-dev mesa-common-dev
sudo apt-get install -y clang
sudo apt-get install -y libclang-dev
sudo apt autoremove -y

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

QT_QPA_EGLFS_KMS_CONFIG=${HOME}/eglfs.json
PKG_CONFIG_LIBDIR=/usr/lib/arm-linux-gnueabihf/pkgconfig:/usr/share/pkgconfig \
${HOME}/qt${QT_FILE_VERSION}/src/qt-everywhere-src-${QT_FULL_VERSION}/configure -device ${DEVICE_OPT} \
-device-option CROSS_COMPILE=arm-linux-gnueabihf- \
-sysroot / \
-opengl es2 -eglfs -linuxfb ${KMS} \
-prefix /usr/local/qt5 \
-opensource -confirm-license \
-release -v \
-nomake examples -no-compile-examples \
-no-use-gold-linker \
-recheck-all \
-skip qtwebengine \
-skip qtwayland \
-no-gtk \
-reduce-exports \
-force-pkg-config \
-qt-pcre \
-no-pch \
-ssl \
-evdev \
-system-freetype \
-fontconfig \
-glib \
-qpa eglfs \
-make libs -optimized-qmake  -skip qt3d -skip qtandroidextras -skip qtcanvas3d -skip qtcharts \
-skip qtdatavis3d -skip qtdoc -skip qtgamepad -skip qtlocation -skip qtmacextras -skip qtpurchasing -skip qtscript -skip qtscxml \
-skip qtspeech -skip qtsvg -skip qttools -skip qttranslations -skip qtwebchannel -skip qtwebsockets \
-skip qtwebview -skip qtwinextras -skip qtxmlpatterns -no-feature-textodfwriter -no-feature-dom -no-feature-calendarwidget \
-no-feature-printpreviewwidget -no-feature-keysequenceedit -no-feature-colordialog -no-feature-printpreviewdialog \
-no-feature-wizard -no-feature-datawidgetmapper -no-feature-imageformat_ppm -no-feature-imageformat_xbm \
-no-feature-image_heuristic_mask -no-feature-cups -no-feature-translation -no-feature-ftp \
-no-feature-socks5 -no-feature-bearermanagement -no-feature-fscompleter -no-feature-desktopservices -no-feature-mimetype \
-no-feature-undocommand -no-feature-undostack -no-feature-undogroup -no-feature-undoview -no-feature-statemachine \
2>&1 | tee ../configure$(date +"%Y-%m-%d_%H-%M").log

if [ $? -eq 0 ]; then
    sudo make -j$CPU_CORES_COUNT 2>&1 | tee ../make$(date +"%Y-%m-%d_%H-%M").log
    if [ $? -eq 0 ]; then
        sudo rm -rf /usr/local/qt5
        sudo make install 2>&1 | tee ../install$(date +"%Y-%m-%d_%H-%M").log
        echo "Building of QT $QT_FULL_VERSION finished successfully."
    else
        echo "make failed"
    fi
else
    echo "configure failed"
fi

cd ${HOME}
