#! /bin/sh

# GVM Variables
export PATH=$PATH:/usr/local/sbin \
INSTALL_PREFIX=/usr/local \
SOURCE_DIR=$HOME/source \
BUILD_DIR=$HOME/build \
INSTALL_DIR=$HOME/install \
GVM_VERSION=21.4.4 \
GVM_LIBS_VERSION=$GVM_VERSION
echo "Finished setting up environment variables..."

# Creating a User and a Group
sudo useradd -r -M -U -G sudo -s /usr/sbin/nologin gvm
echo "Created user and group..."

# Adjusting the Current User
sudo usermod -aG gvm $USER
su $USER
echo "Completed adjustment of current user..."

# Creating a Source, Build and Install Directory
mkdir -p $SOURCE_DIR
mkdir -p $BUILD_DIR
mkdir -p $INSTALL_DIR

# Installing Common Build Dependencies
sudo apt update
sudo apt install --no-install-recommends --assume-yes \
build-essential \
curl \
cmake \
pkg-config \
python3 \
python3-pip \
gnupg

# Importing the Greenbone Signing Key
curl -O https://www.greenbone.net/GBCommunitySigningKey.asc
gpg --import GBCommunitySigningKey.asc
gpg --edit-key 9823FAA60ED1E580

# Building and Installing the Components
# gvm-libs
sudo apt install -y \
libglib2.0-dev \
libgpgme-dev \
libgnutls28-dev \
uuid-dev \
libssh-gcrypt-dev \
libhiredis-dev \
libxml2-dev \
libpcap-dev \
libnet1-dev \
libldap2-dev \
libradcli-dev

curl -f -L https://github.com/greenbone/gvm-libs/archive/refs/tags/v$GVM_LIBS_VERSION.tar.gz -o $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION.tar.gz
curl -f -L https://github.com/greenbone/gvm-libs/releases/download/v$GVM_LIBS_VERSION/gvm-libs-$GVM_LIBS_VERSION.tar.gz.asc -o $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION.tar.gz.asc

gpg --verify $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION.tar.gz.asc $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION.tar.gz

tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION.tar.gz

mkdir -p $BUILD_DIR/gvm-libs && cd $BUILD_DIR/gvm-libs

cmake $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION \
-DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
-DCMAKE_BUILD_TYPE=Release \
-DSYSCONFDIR=/etc \
-DLOCALSTATEDIR=/var \
-DGVM_PID_DIR=/run/gvm

make -j$(nproc)

make DESTDIR=$INSTALL_DIR install

sudo cp -rv $INSTALL_DIR/* /

rm -rf $INSTALL_DIR/*