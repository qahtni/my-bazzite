# =============================================
# Custom Bazzite KDE image with HDMI FRL kernel
# Uses sneed/kernel-hdmi-frl COPR (no compilation needed)
# =============================================
FROM ghcr.io/ublue-os/bazzite:stable

# Enable the COPR repo that ships pre-built hdmi_frl kernel RPMs for fc43
RUN curl --fail -fsSL \
    https://copr.fedorainfracloud.org/coprs/sneed/kernel-hdmi-frl/repo/fedora-43/sneed-kernel-hdmi-frl-fedora-43.repo \
    -o /etc/yum.repos.d/sneed-kernel-hdmi-frl.repo && \
    cat /etc/yum.repos.d/sneed-kernel-hdmi-frl.repo

# Replace the stock kernel with the hdmi_frl version from COPR
# override replace --from repo= swaps packages atomically without needing to name what to remove
RUN rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:sneed:kernel-hdmi-frl \
    kernel \
    kernel-core \
    kernel-modules \
    kernel-modules-core \
    kernel-modules-extra && \
    rm /etc/yum.repos.d/sneed-kernel-hdmi-frl.repo

# Finalize the ostree layer
RUN ostree container commit
