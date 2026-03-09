# =============================================
# Custom Bazzite KDE image with HDMI FRL kernel
# Uses sneed/kernel-hdmi-frl COPR
# =============================================
FROM ghcr.io/ublue-os/bazzite:stable

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
# kernel-modules-extra as swapped not deleted — keeps usbip satisfied.
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
