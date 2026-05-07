# =============================================
# Custom Bazzite Deck image with HDMI FRL kernel
# Uses sneed/kernel-hdmi-frl COPR
# =============================================
FROM ghcr.io/ublue-os/bazzite-deck:stable

# Download the hdmi_frl kernel RPMs from COPR as local files
RUN curl --fail -fsSL \
    https://copr.fedorainfracloud.org/coprs/sneed/kernel-hdmi-frl/repo/fedora-43/sneed-kernel-hdmi-frl-fedora-43.repo \
    -o /etc/yum.repos.d/sneed-kernel-hdmi-frl.repo && \
    mkdir -p /tmp/kernel-rpms && \
    dnf download -y \
        --repo=copr:copr.fedorainfracloud.org:sneed:kernel-hdmi-frl \
        --destdir=/tmp/kernel-rpms \
        --best \
        kernel \
        kernel-core \
        kernel-modules \
        kernel-modules-core \
        kernel-modules-extra && \
    rm /etc/yum.repos.d/sneed-kernel-hdmi-frl.repo

# Replace the stock kernel atomically using local RPM files.
# Using override replace (not remove+install) so the dep solver sees
# kernel-modules-extra as swapped not deleted - keeps usbip satisfied.
# --remove handles packages that hard-pin to the stock kernel version.
RUN rpm-ostree override replace \
    --remove=kernel-common \
    --remove=kernel-devel \
    --remove=kernel-devel-matched \
    --remove=kernel-modules-akmods \
    /tmp/kernel-rpms/*x86_64.rpm \
    && rm -rf /tmp/kernel-rpms

# Finalize the ostree layer
RUN ostree container commit

# =============================================
# RTL8125 2.5GbE Ethernet stability fix
# Tunes the r8169 driver (which handles RTL8125
# on this kernel) to prevent link speed downshifts
# and disables Energy Efficient Ethernet (EEE)
# which is the primary cause of random 100Mbps drops.
# =============================================

# Disable ASPM for the r8169 driver and set S5 wakeup
# aspm=0 prevents PCIe power state transitions that cause
# the RTL8125 to drop link speed under load or after idle.
RUN echo "options r8169 aspm=0" > /etc/modprobe.d/r8169-rtl8125.conf

# Disable Energy Efficient Ethernet on every boot via NetworkManager dispatcher.
# EEE causes the link to renegotiate during idle and can land on 100Mbps.
RUN mkdir -p /etc/NetworkManager/dispatcher.d && \
    printf '#!/bin/bash\n[ "$1" = "eno1" ] && [ "$2" = "up" ] && /sbin/ethtool --set-eee "$1" eee off\n' \
    > /etc/NetworkManager/dispatcher.d/99-disable-eee.sh && \
    chmod +x /etc/NetworkManager/dispatcher.d/99-disable-eee.sh

# Finalize the ostree layer
RUN ostree container commit
