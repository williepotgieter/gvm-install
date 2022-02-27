#! /bin/sh

# GVM Variables
export PATH=$PATH:/usr/local/sbin \
INSTALL_PREFIX=/usr/local \
SOURCE_DIR=$HOME/source \
BUILD_DIR=$HOME/build \
INSTALL_DIR=$HOME/install \
GVM_VERSION=21.4.4 \
GVM_LIBS_VERSION=$GVM_VERSION
# GVMD Variables
export GVMD_VERSION=21.4.5
echo "Finished setting up environment variables..."

######################################################## GVM ########################################################
# Creating a User and a Group
sudo useradd -r -M -U -G sudo -s /usr/sbin/nologin gvm
echo "Created user and group..."

# Adjusting the Current User
sudo usermod -aG gvm $USER
#su $USER
echo "Completed adjustment of current user..."

# Creating a Source, Build and Install Directory
mkdir -p $SOURCE_DIR
mkdir -p $BUILD_DIR
mkdir -p $INSTALL_DIR
echo "Created source, build & install directories..."

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

######################################################## GVMD ########################################################
# Required dependencies for gvmd
sudo apt install -y \
libpq-dev \
postgresql-server-dev-11 \
libical-dev \
xsltproc \
rsync

# Optional dependencies for gvmd
sudo apt install -y --no-install-recommends \
texlive-latex-extra \
texlive-fonts-recommended \
xmlstarlet \
zip \
rpm \
fakeroot \
dpkg \
nsis \
gnupg \
gpgsm \
wget \
sshpass \
openssh-client \
socat \
snmp \
smbclient \
python3-lxml \
gnutls-bin \
xml-twig-tools

# Downloading the gvmd sources
curl -f -L https://github.com/greenbone/gvmd/archive/refs/tags/v$GVMD_VERSION.tar.gz -o $SOURCE_DIR/gvmd-$GVMD_VERSION.tar.gz
curl -f -L https://github.com/greenbone/gvmd/releases/download/v$GVMD_VERSION/gvmd-$GVMD_VERSION.tar.gz.asc -o $SOURCE_DIR/gvmd-$GVMD_VERSION.tar.gz.asc

# Verifying the source file
gpg --verify $SOURCE_DIR/gvmd-$GVMD_VERSION.tar.gz.asc $SOURCE_DIR/gvmd-$GVMD_VERSION.tar.gz

# Extract taeball
tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/gvmd-$GVMD_VERSION.tar.gz

# Build gvmd
mkdir -p $BUILD_DIR/gvmd && cd $BUILD_DIR/gvmd

cmake $SOURCE_DIR/gvmd-$GVMD_VERSION \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
  -DCMAKE_BUILD_TYPE=Release \
  -DLOCALSTATEDIR=/var \
  -DSYSCONFDIR=/etc \
  -DGVM_DATA_DIR=/var \
  -DGVM_RUN_DIR=/run/gvm \
  -DOPENVAS_DEFAULT_SOCKET=/run/ospd/ospd-openvas.sock \
  -DGVM_FEED_LOCK_PATH=/var/lib/gvm/feed-update.lock \
  -DSYSTEMD_SERVICE_DIR=/lib/systemd/system \
  -DDEFAULT_CONFIG_DIR=/etc/default \
  -DLOGROTATE_DIR=/etc/logrotate.d

make -j$(nproc)

# Install gvmd
make DESTDIR=$INSTALL_DIR install

sudo cp -rv $INSTALL_DIR/* /

rm -rf $INSTALL_DIR/*