# =============================================
# Custom Bazzite KDE image with HDMI FRL kernel
# Uses sneed/kernel-hdmi-frl COPR (no compilation needed)
# =============================================
FROM ghcr.io/ublue-os/bazzite:stable

# Enable the COPR repo that ships pre-built hdmi_frl kernel RPMs for fc43
RUN curl --fail -fsSL \
    https://copr.fedorainfracloud.org/coprs/sneed/kernel-hdmi-frl/repo/fedora-43/sneed-kernel-hdmi-frl-fedora-43.repo \
    -o /etc/yum.repos.d/sneed-kernel-hdmi-frl.repo

# Step 1: Remove packages that hard-pin to the stock kernel version
# kernel-devel-matched requires kernel-core = <exact stock version>
# kernel-modules-akmods requires kernel-modules-uname-r = <exact stock version>
RUN rpm-ostree override remove \
    kernel-devel \
    kernel-devel-matched \
    kernel-modules-akmods

# Step 2: Replace the stock kernel with hdmi_frl version from COPR
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
