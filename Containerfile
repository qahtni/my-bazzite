# =============================================
# Custom Bazzite KDE image with HDMI FRL kernel
# Uses sneed/kernel-hdmi-frl COPR (no compilation needed)
# =============================================
FROM ghcr.io/ublue-os/bazzite:stable

# Enable the COPR repo that ships pre-built hdmi_frl kernel RPMs for fc43
RUN curl -fsSL \
    https://copr.fedorainfracloud.org/coprs/sneed/kernel-hdmi-frl/repo/fedora-43/sneed-kernel-hdmi-frl-fedora-43.repo \
    -o /etc/yum.repos.d/sneed-kernel-hdmi-frl.repo

# Remove stock kernel packages and replace with hdmi_frl versions from COPR
RUN rpm-ostree cliwrap install-to-root / && \
    rpm-ostree override remove \
        kernel \
        kernel-common \
        kernel-core \
        kernel-modules \
        kernel-modules-core \
        kernel-modules-extra \
        kernel-modules-akmods \
    --install kernel \
    --install kernel-core \
    --install kernel-modules \
    --install kernel-modules-core \
    --install kernel-modules-extra && \
    rm /etc/yum.repos.d/sneed-kernel-hdmi-frl.repo

# Finalize the ostree layer
RUN ostree container commit
