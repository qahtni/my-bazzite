# =============================================
# Custom Bazzite KDE image with HDMI FRL kernel
# Uses sneed/kernel-hdmi-frl COPR
# =============================================
FROM ghcr.io/ublue-os/bazzite:stable

# Enable COPR repo and download the kernel RPMs as local files
# This avoids rpm-ostree depsolve issues with --from repo=
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
    ls -la /tmp/kernel-rpms/ && \
    rm /etc/yum.repos.d/sneed-kernel-hdmi-frl.repo

# Remove all packages that pin to the stock kernel version,
# then install the downloaded hdmi_frl kernel RPMs
RUN rpm-ostree override remove \
        kernel \
        kernel-core \
        kernel-modules \
        kernel-modules-core \
        kernel-modules-extra \
        kernel-common \
        kernel-devel \
        kernel-devel-matched \
        kernel-modules-akmods \
    && rpm-ostree install /tmp/kernel-rpms/*.rpm \
    && rm -rf /tmp/kernel-rpms

# Finalize the ostree layer
RUN ostree container commit
