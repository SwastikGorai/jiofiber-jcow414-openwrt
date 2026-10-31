# SQM (Cake) for JioFiber JCOW414, firmware build

An **OpenWrt-Asjohn720 1.1-sqm** firmware image with SQM (Cake QoS) preinstalled,
built from the exact source commit of the v1.1 release.

## Why a firmware (and not standalone packages)

The stock v1.1 kernel does **not** export the traffic-classifier symbols Cake
requires (`tcf_classify`, `tcf_block_get`, `tcf_block_put`; verified absent in
`/proc/kallsyms` on a running v1.1 router). Loading a separately compiled
`sch_cake.ko` fails with `Unknown symbol`, regardless of vermagic or packaging.
SQM on this device therefore requires a kernel built with the scheduler
infrastructure enabled, i.e. a new firmware image. This build enables
`kmod-sched-core`/`kmod-ifb`/`kmod-sched-cake` in the kernel package set, so
`sch_cake.ko` loads and runs natively (exports verified in the built `vmlinux`).

## Files

| File | Purpose |
|---|---|
| `firmware/openwrt-asjohn720-1.1-sqm-...-jiofiber_jcow414-squashfs-tclinux.trx` | Flashable factory image with SQM preinstalled |
| `build-firmware-image.sh` | Reproducible build script (WSL2/Linux) |

## What's inside the image

- Everything from OpenWrt-Asjohn720 1.1 (LuCI + SSL, bootstrap theme, JCOW414 DTS)
- `kmod-sched-core`, `kmod-ifb`, `kmod-sched-cake` (kernel 6.18.55)
- `tc-tiny`, `ip-tiny`, `sqm-scripts`, `luci-app-sqm`
- First-boot defaults via `uci-defaults`: SQM configured for `lan4`,
  `piece_of_cake.qos`, 28000/28000 kbit/s, **`enabled='0'`** (off until you turn it on)

> **Port note:** `lan4`, the SQM/WAN interface, is the RJ45 port **nearest the
> USB ports** on the back of the JCOW414. Use it as the uplink; `lan1` to `lan3`
> are for LAN devices. This sqm-scripts build expects the device name
> (`lan4`), not the uci interface name (`wan`).

## Flash (from running OpenWrt v1.1)

```sh
# 1. BACK UP FIRST (config + both firmware banks):
sysupgrade -b /tmp/config.tar.gz
dd if=/dev/mtd2ro  of=/tmp/tclinux-openwrt-bank1.bin
dd if=/dev/mtd5ro  of=/tmp/tclinux_slave-stock-bank2.bin
dd if=/dev/mtd9ro  of=/tmp/config-mtd.bin
dd if=/dev/mtd12ro of=/tmp/reservearea.bin
# ...and copy them off the router before proceeding.

# 2. Upload the .trx to /tmp and flash bank 1 (same flow as the original v1.1):
mtd -f write /tmp/openwrt-asjohn720-1.1-sqm-*.trx tclinux

# 3. Reboot. Settings are NOT preserved across mtd flash; re-apply or restore
#    your sysupgrade backup afterwards.
```

Flashing replaces bank 1 only; the stock Jio firmware stays untouched in bank 2
for rollback (swap the boot flag via `reservearea` as documented in the main README).

New installs from stock Jio firmware should use the automated installer in the
main README (`tools/Flash_SQM_Firmware.py`), which performs all steps.

## Verify after first boot

```sh
modprobe sch_cake && lsmod | grep cake        # loads cleanly
tc qdisc show                                  # tc present
uci get sqm.queue.enabled                      # -> 0 (disabled by default)
```

SQM should already be visible under **Network -> SQM QoS** with the `lan4`
queue preconfigured (the section is typed `queue`, so the LuCI grid lists it).

## Enable SQM

```sh
uci set sqm.queue.download='28000'   # your plan, kbit/s
uci set sqm.queue.upload='28000'
uci set sqm.queue.enabled='1'
uci commit sqm
/etc/init.d/sqm enable && /etc/init.d/sqm start
```

## Build it yourself

```sh
mkdir -p ~/jcow414-build && cd ~/jcow414-build
cp /path/to/build-firmware-image.sh . && chmod +x build-firmware-image.sh
./build-firmware-image.sh
```

Notes:
- WSL2 works, but build on the Linux filesystem (under `/home`), never `/mnt/*`;
  the script refuses and strips the Windows PATH (a relative PATH entry otherwise
  breaks `find -execdir`).
- The script pins `REVISION=r0-c4526c7`; a full clone's longer revision string
  overflows the TRX header version field (`tclinux-trx.sh` fails with
  "Version string too long").
- If `make download` stalls on `download.samba.org`, fetch the ppp tarball from
  `https://sources.openwrt.org/ppp-<version>.tar.gz` into `dl/`, kill the stalled
  curl, and re-run.

## Source identity

- `Sirherobrine23/openwrt` @ `c4526c7d56d571994609340f8ae894dd10e13bcd`
  (= firmware revision `r0-c4526c7`)
- Kernel `6.18.55`, module vermagic `6.18.55 SMP mod_unload MIPS32_R2 32BIT`
