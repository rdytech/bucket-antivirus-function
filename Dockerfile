FROM amazonlinux:2

# Set up working directories
RUN mkdir -p /opt/app/clamav

# Install packages
RUN yum update -y
RUN amazon-linux-extras install epel -y
RUN yum install -y cpio yum-utils zip

# Download libraries we need to run in lambda
WORKDIR /tmp
RUN yumdownloader -x \*i686 --archlist=x86_64 \
  clamav \
  clamav-lib \
  clamav-scanner-systemd \
  clamav-update \
  elfutils-libs \
  gnutls \
  json-c \
  lib64nettle \
  libprelude \
  libtasn1 \
  libtool-ltdl \
  nettle \
  lz4 \
  pcre2 \
  systemd-libs

RUN rpm2cpio clamav-0*.rpm | cpio -idmv
RUN rpm2cpio clamav-lib*.rpm | cpio -idmv
RUN rpm2cpio clamav-update*.rpm | cpio -idmv
RUN rpm2cpio clamd-0*.rpm | cpio -idmv
RUN rpm2cpio elfutils-libs*.rpm | cpio -idmv
RUN rpm2cpio gnutls*.rpm | cpio -idmv
RUN rpm2cpio nettle*.rpm | cpio -idmv
RUN rpm2cpio json-c*.rpm | cpio -idmv
RUN rpm2cpio libprelude*.rpm | cpio -idmv
RUN rpm2cpio libtasn1*.rpm | cpio -idmv
RUN rpm2cpio libtool*.rpm | cpio -idmv
RUN rpm2cpio lz4*.rpm | cpio -idmv
RUN rpm2cpio pcre*.rpm | cpio -idmv
RUN rpm2cpio systemd-libs*.rpm | cpio -idmv

# Copy over the binaries and libraries
RUN cp -r /usr/lib64/libpcre* \
       /usr/lib64/libxml2* \
       /usr/lib64/liblzma* \
       /usr/lib64/libgcrypt* \
       /usr/lib64/libgpg-error* \
       /usr/lib64/libelf* \
       /opt/app/clamav/

RUN cp -r /tmp/usr/bin/clamdscan \
       /tmp/usr/sbin/clamd \
       /tmp/usr/bin/freshclam \
       /tmp/usr/lib64/* \
       /opt/app/clamav/

RUN echo "DatabaseDirectory /tmp/clamav_defs" > /opt/app/clamav/scan.conf
RUN echo "PidFile /tmp/clamd.pid" >> /opt/app/clamav/scan.conf
RUN echo "LocalSocket /tmp/clamd.sock" >> /opt/app/clamav/scan.conf
RUN echo "LogFile /tmp/clamd.log" >> /opt/app/clamav/scan.conf

# Fix the freshclam.conf settings
RUN echo "DatabaseMirror database.clamav.net" > /opt/app/clamav/freshclam.conf
RUN echo "CompressLocalDatabase yes" >> /opt/app/clamav/freshclam.conf

RUN export PATH="$PATH:/usr/lib64"
