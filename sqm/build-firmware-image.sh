#!/usr/bin/env bash
# Build a JCOW414 firmware image with SQM (Cake) preinstalled.
# Self-contained: clones the pinned OpenWrt source on first run.
# Run inside a Linux-native dir, e.g.:
#   mkdir -p ~/jcow414-build && cd ~/jcow414-build && /path/to/build-firmware-image.sh
set -euo pipefail

COMMIT="c4526c7d56d571994609340f8ae894dd10e13bcd"
REPO="https://github.com/Sirherobrine23/openwrt.git"
# Short revision, matching the v1.1 release. The full-clone revision string
# (r0+NNNNN-hash) overflows the TRX header version field in tclinux-trx.sh.
REVISION="r0-c4526c7"

case "$PWD/" in
  /mnt/*) echo "ERROR: run from WSL-native filesystem, not $PWD"; exit 1 ;;
esac
case "$(uname -r)" in
  *icrosoft*|*WSL2*) export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" ;;
esac

DEPS=(build-essential clang flex bison g++ gawk gcc-multilib gettext git
      libncurses-dev libssl-dev python3 rsync unzip zlib1g-dev file wget ca-certificates)
missing=()
for d in "${DEPS[@]}"; do dpkg -s "$d" >/dev/null 2>&1 || missing+=("$d"); done
if [[ ${#missing[@]} -gt 0 ]]; then
  echo "Installing missing build dependencies (needs root)..."
  sudo apt-get update -y && sudo apt-get install -y "${missing[@]}"
fi

if [[ ! -d openwrt/.git ]]; then
  echo "Cloning OpenWrt (airoha tree)..."
  git clone --filter=blob:none "$REPO" openwrt
fi
cd openwrt
git fetch --all --quiet 2>/dev/null || true
git checkout --detach "$COMMIT"
./scripts/feeds update -a
./scripts/feeds install -a

# First-boot SQM defaults: configured but disabled, wan, piece_of_cake, 28/28
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99_sqm_defaults <<'EOF'
#!/bin/sh
[ -f /etc/config/sqm ] || touch /etc/config/sqm
# Tolerant deletes: sqm-scripts' build-time postinst bakes a default 'eth1'
# section into the image; uci batch aborts if asked to delete a missing
# section, so delete outside the batch and ignore errors.
uci -q delete sqm.queue 2>/dev/null || true
uci -q delete sqm.eth1 2>/dev/null || true
uci -q batch <<-'UCI'
		set sqm.queue=queue
		set sqm.queue.enabled='0'
		set sqm.queue.interface='wan'
		set sqm.queue.download='28000'
		set sqm.queue.upload='28000'
		set sqm.queue.script='piece_of_cake.qos'
		set sqm.queue.qdisc='cake'
		set sqm.queue.link_layer='none'
		set sqm.queue.verbosity='5'
UCI
uci commit sqm
exit 0
EOF

cat > .config <<'EOF'
CONFIG_TARGET_econet=y
CONFIG_TARGET_econet_en7528=y
CONFIG_TARGET_econet_en7528_DEVICE_jiofiber_jcow414=y
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-ssl=y
CONFIG_PACKAGE_luci-theme-bootstrap=y
CONFIG_PACKAGE_kmod-sched-core=y
CONFIG_PACKAGE_kmod-ifb=y
CONFIG_PACKAGE_kmod-sched-cake=y
CONFIG_PACKAGE_tc-tiny=y
CONFIG_PACKAGE_ip-tiny=y
CONFIG_PACKAGE_sqm-scripts=y
CONFIG_PACKAGE_luci-app-sqm=y
CONFIG_IMAGEOPT=y
CONFIG_VERSIONOPT=y
CONFIG_VERSION_DIST="OpenWrt-Asjohn720"
CONFIG_VERSION_NUMBER="1.1-sqm"
CONFIG_VERSION_CODE="JCOW414"
EOF
make defconfig

for p in luci luci-ssl luci-theme-bootstrap kmod-sched-core kmod-ifb kmod-sched-cake tc-tiny ip-tiny sqm-scripts luci-app-sqm; do
  grep -q "CONFIG_PACKAGE_${p}=y" .config || { echo "ERROR: $p not selected"; exit 1; }
done

# If a previous release-kmod build re-stamped the kernel ABI hash, restore native.
KDIR="build_dir/target-mipsel_24kc_musl/linux-econet_en7528/linux-6.18.55"
if [ -f "$KDIR/.config.set" ]; then
  NATIVE="$(grep -e '=y' -e '=m' "$KDIR/.config.set" | LC_ALL=C sort | md5sum | cut -d' ' -f1)"
  printf '%s' "$NATIVE" > "$KDIR/.vermagic"
  echo "native kernel ABI hash: $NATIVE"
fi

echo "--- Downloading and building (first run: 1-2+ hours) ---"
make download -j"$(nproc)"
# REVISION pin keeps the TRX header version string within its length limit.
make -j"$(nproc)" REVISION="$REVISION"

echo "=============================="
ls -lh bin/targets/econet/en7528/*jiofiber_jcow414*.trx
echo "=============================="
sha256sum bin/targets/econet/en7528/*jiofiber_jcow414*.trx
