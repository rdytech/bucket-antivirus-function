# Builds the ClamAV binaries and shared libraries bundled into the lambda package.
# The base image must match the OS of the lambda runtime (python3.13 runs on
# Amazon Linux 2023). Build with `--platform linux/arm64` or `--platform linux/amd64`
# to match the lambda architecture (see ARCH in the Makefile).
FROM amazonlinux:2023

# ClamAV LTS release packaged by Amazon Linux 2023
ARG CLAMAV_VERSION=1.4

# Install packages
RUN dnf install -y \
      clamav${CLAMAV_VERSION} \
      clamd${CLAMAV_VERSION} \
      clamav${CLAMAV_VERSION}-freshclam \
      findutils \
  && dnf clean all

# Copy over the binaries
RUN mkdir -p /opt/app/clamav \
  && cp /usr/bin/clamdscan \
        /usr/sbin/clamd \
        /usr/bin/freshclam \
        /opt/app/clamav/

# Copy over every shared library the binaries link against, except glibc which
# is provided by the lambda runtime and must match its dynamic loader
RUN ldd /opt/app/clamav/clamdscan /opt/app/clamav/clamd /opt/app/clamav/freshclam \
  | awk '$2 == "=>" && $3 ~ /^\// {print $3}' \
  | sort -u \
  | grep -vE '/(libc|libm|libdl|libpthread|librt|libresolv|libutil)\.so\.[0-9]+$' \
  | xargs -I{} cp -L {} /opt/app/clamav/

RUN echo "DatabaseDirectory /tmp/clamav_defs" > /opt/app/clamav/scan.conf \
  && echo "PidFile /tmp/clamd.pid" >> /opt/app/clamav/scan.conf \
  && echo "LocalSocket /tmp/clamd.sock" >> /opt/app/clamav/scan.conf \
  && echo "LogFile /tmp/clamd.log" >> /opt/app/clamav/scan.conf

# Fix the freshclam.conf settings
RUN echo "DatabaseMirror database.clamav.net" > /opt/app/clamav/freshclam.conf \
  && echo "CompressLocalDatabase yes" >> /opt/app/clamav/freshclam.conf
