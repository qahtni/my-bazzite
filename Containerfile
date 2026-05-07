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
# Builds the r8125 driver from Realtek source
# against the installed kernel headers, installs
# the .ko, blacklists r8169, and disables EEE.
# =============================================

# Build and install r8125 driver from source
RUN dnf install -y kernel-devel make gcc git && \
    git clone --depth=1 https://github.com/awesometic/realtek-r8125-dkms.git /tmp/r8125 && \
    KVER=$(ls /lib/modules | tail -1) && \
    make -C /tmp/r8125/src KERNELDIR=/lib/modules/${KVER}/build && \
    install -D -m 644 /tmp/r8125/src/r8125.ko \
        /lib/modules/${KVER}/kernel/drivers/net/ethernet/realtek/r8125.ko && \
    depmod -a ${KVER} && \
    rm -rf /tmp/r8125 && \
    dnf remove -y make gcc git && \
    dnf clean all

# Blacklist r8169 so r8125 takes over for RTL8125
RUN echo "blacklist r8169" > /etc/modprobe.d/blacklist-r8169.conf

# Disable Energy Efficient Ethernet on boot via NetworkManager dispatcher
RUN printf '#!/bin/bash\n[ "$1" = "eno1" ] && [ "$2" = "up" ] && /sbin/ethtool --set-eee eno1 eee off\n' \
    > /etc/NetworkManager/dispatcher.d/99-disable-eee.sh && \
    chmod +x /etc/NetworkManager/dispatcher.d/99-disable-eee.sh

# Finalize the ostree layer
RUN ostree container commit
