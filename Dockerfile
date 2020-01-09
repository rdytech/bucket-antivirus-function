FROM amazonlinux:2

# Set up working directories
RUN mkdir -p /opt/app/clamav

# Install packages
RUN yum update -y
RUN amazon-linux-extras install epel -y
RUN yum install -y cpio yum-utils zip

# Download libraries we need to run in lambda
WORKDIR /tmp
RUN yumdownloader -x \*i686 --archlist=x86_64 clamav clamav-lib clamav-update json-c pcre2
RUN rpm2cpio clamav-0*.rpm | cpio -idmv
RUN rpm2cpio clamav-lib*.rpm | cpio -idmv
RUN rpm2cpio clamav-update*.rpm | cpio -idmv
RUN rpm2cpio json-c*.rpm | cpio -idmv
RUN rpm2cpio pcre*.rpm | cpio -idmv

# Copy over the binaries and libraries
RUN cp /tmp/usr/bin/clamscan /tmp/usr/bin/freshclam /tmp/usr/lib64/* /opt/app/clamav/

# Fix the freshclam.conf settings
RUN echo "DatabaseMirror database.clamav.net" > /opt/app/clamav/freshclam.conf
RUN echo "CompressLocalDatabase yes" >> /opt/app/clamav/freshclam.conf

WORKDIR /opt/app

RUN zip -r9 /opt/app/clamav.zip .
