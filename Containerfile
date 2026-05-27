# Start from the official Rocky UBI 9 base image
FROM rockylinux/rockylinux:9-ubi

ARG MAINTAINER_LABEL="Cody Chapman <cody.chapman@gmail.com>"
LABEL org.opencontainers.image.authors="$MAINTAINER_LABEL" \
      org.opencontainers.image.title="CUPS print server image - Rocky/UBI" \
      org.opencontainers.image.description="Docker image including CUPS print server and printing drivers based on UBI 9 and Rocky Linux repositories."

# 1. Inject Rocky Linux 9 repositories to get full access to printer drivers and filters
RUN dnf install -y https://dl.rockylinux.org/pub/rocky/9/BaseOS/x86_64/os/Packages/r/rocky-release-9.5-1.1.el9.noarch.rpm \
                   https://dl.rockylinux.org/pub/rocky/9/BaseOS/x86_64/os/Packages/r/rocky-repos-9.5-1.1.el9.noarch.rpm \
                   https://dl.rockylinux.org/pub/rocky/9/BaseOS/x86_64/os/Packages/r/rocky-gpg-keys-9.5-1.1.el9.noarch.rpm \
    && dnf install -y epel-release

# 2. Install fundamental tools, CUPS, and available printer drivers/backends
# Note: RHEL/Rocky packages combine many individual printer drivers into comprehensive suites 
# (e.g., cups-filters, foomatic-db-ppds, and gutenprint).
RUN dnf update -y && \
    dnf install -y \
        sudo \
        util-linux \
        usbutils \
        cups \
        cups-client \
        cups-filters \
        cups-ipptool \
        foomatic \
        foomatic-db \
        foomatic-db-ppds \
        gutenprint \
        gutenprint-cups \
        hpijs \
        hplip \
        samba-client \
        avahi \
    && dnf clean all \
    && rm -rf /var/cache/dnf/*

# This container maps to the standard CUPS interface port
EXPOSE 631

# 3. Create the 'print' administrative user.
# RHEL/Rocky systems traditionally grant administrative CUPS access to the 'sys' or 'wheel' group.
# 'cups-passwd' or standard shadows-utils handles encrypted password parsing differently than Debian's mkpasswd.
RUN useradd \
        --groups sys,wheel,lp \
        --create-home \
        --home-dir /home/print \
        --shell /bin/bash \
        print \
    && echo "print:print" | chpasswd \
    && sed -i 's/%wheel\s\+ALL=(ALL)\s\+ALL/%wheel\tALL=(ALL)\tNOPASSWD:ALL/' /etc/sudoers

# 4. Copy the custom configurations.
# Ensure you have your custom `cupsd.conf` in the same directory as this Dockerfile.
COPY --chown=root:lp cupsd.conf /etc/cups/cupsd.conf

# Default executable behavior to keep CUPS in the foreground
CMD ["/usr/sbin/cupsd", "-f"]
