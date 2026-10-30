# JioFiber Router JCOW414 OpenWrt

[![OpenWrt Version](https://img.shields.io/badge/OpenWrt-23.05%20Airoha-blue.svg)](https://openwrt.org)
[![OpenWrt Wiki](https://img.shields.io/badge/OpenWrt%20Wiki-Sercomm%20JCOW414-006699.svg)](https://openwrt.org/toh/sercomm/jcow414)
[![Linux Kernel](https://img.shields.io/badge/Kernel-6.18.55-green.svg)](https://kernel.org)
[![SoC](https://img.shields.io/badge/SoC-EcoNet%20EN7528HU-orange.svg)](https://www.airoha.com)
[![Failsafe](https://img.shields.io/badge/Flash-Dual--Bank%20Protected-brightgreen.svg)](#dual-bank-failsafe--rollback)
[![License: GPL-2.0](https://img.shields.io/badge/License-GPL--2.0-yellow.svg)](LICENSE)

An unofficial, fully working community OpenWrt port for the **Sercomm JioFiber JCOW414** router (powered by the **EcoNet / Airoha EN7528HU** platform).

This repository provides the complete **Device Tree Source (`.dts`)**, build recipes, automated root patch tools, and step-by-step flashing guides to unlock your JCOW414 router and run modern OpenWrt with LuCI web administration.

> 📖 **Official Hardware Documentation:** [OpenWrt Table of Hardware: Sercomm JCOW414](https://openwrt.org/toh/sercomm/jcow414)

![OpenWrt LuCI Dashboard on Sercomm JCOW414](docs/screenshots/Openwrt_dashboard.png)

---

## ⚡ Quick Flashing Guide (No Disassembly Required)

You do **not** need to open your router or solder serial wires. Flashing is performed entirely over the network using the stock web panel and root Telnet shell.

---

### Step 1: Gain Root Access (Automated 1-Click Method)

> **Why do this?** Modern Jio firmware versions (R2.41 / R2.52) lock the root account with randomized passwords. Downgrading to R2.15 allows us to decrypt the router's configuration file, inject a command that launches a root Telnet server, and set our own password (`password`).

#### 1.1 Downgrade Router to R2.15
1. Download these two official signed firmware files to your computer:
   * **Firmware Image:** [`SRCMTF1_JCOW414_R2.15.img`](https://raw.githubusercontent.com/gpsarathy/JioFiber-Home-Gateway/master/Firmwares/JCOW414/2.15/SRCMTF1_JCOW414_R2.15.img) (or via [Jio OTA Mirror](http://fota.slv.fxd.jiophone.net/ONT/Sercomm/JCOW414/SRCMTF1_JCOW414_R2.15.img))
   * **Signature File:** [`SRCMTF1_JCOW414_R2.15.sig`](https://raw.githubusercontent.com/gpsarathy/JioFiber-Home-Gateway/master/Firmwares/JCOW414/2.15/SRCMTF1_JCOW414_R2.15.sig) (or via [Jio OTA Mirror](http://fota.slv.fxd.jiophone.net/ONT/Sercomm/JCOW414/SRCMTF1_JCOW414_R2.15.sig))
2. Open your browser and go to `http://192.168.29.1` (Default login: `admin` / `Jiocentrum` or your Wi-Fi password).
3. Navigate to: **Administrator** &rarr; **Maintenance** &rarr; **Firmware Upgrade**.
4. Select both files (`.img` and `.sig`) and click **Proceed**. Wait ~2–3 minutes while the router reboots into R2.15.

#### 1.2 Download Your Config Backup
1. After reboot, log back in to `http://192.168.29.1`.
2. Go to: **Administrator** &rarr; **Maintenance** &rarr; **Backup/Restore**.
3. Click the **Backup** button. Your browser downloads a file named like `RSVXXXXXXXXXXX_JCOW414.enc`.

#### 1.3 Run 1-Click Auto-Patch Script
To inject the root payload into your downloaded backup:

* **On Windows (1-Click Standalone):**  
  Download [`JioFiber_Universal_Root_Unlocker_For_Windows.bat`](https://raw.githubusercontent.com/Asjohn720/jiofiber-jcow414-openwrt/main/tools/JioFiber_Universal_Root_Unlocker_For_Windows.bat).  
  👉 **Drag & drop** your downloaded `RSV..._JCOW414.enc` file directly onto `bat` (or double-click it!). 

* **On Linux / macOS (Python):**  
  ```bash
  python3 tools/JioFiber_Universal_Root_Unlocker_For_mac_linux.py
  ```

*(Advanced users can also manually decrypt and re-encrypt using OpenSSL with passphrase `"BE F2 26 75 7C B1 49 CB 04 CD CA 84 DC 5B E9 55"`).*

This instantly creates **`<original-backup-name>_MODIFIED.enc`** in your folder (for example `RSVOTKHEM068672_JCOW414_MODIFIED.enc`).

> ⚠️ **Keep the model name in the filename.** The stock firmware rejects any restore file whose name does not contain the router's product class (e.g. `JCOW414`), showing *"Invalid File Selected. Please provide a Valid File."*

#### 1.4 Upload Modified Backup & Connect
1. In the router web panel, go to **Maintenance** &rarr; **Backup/Restore**.
2. Under **Restore**, choose the generated `*_JCOW414_MODIFIED.enc` file and click **Restore**.
3. ⚠️ **Normal & Expected Notice:** The web UI will show:  
   `"Failed to update configuration (checksum error)"`  
   **Do NOT panic!** The router executed your injected payload in memory as root *before* checking the checksum. Telnet root shell is now active!
4. Open your terminal (or PuTTY) and connect via Telnet:
   ```bash
   telnet 192.168.29.1 23
   ```
   * **Username:** `root`
   * **Password:** `password`

You now have full root access to your JCOW414 router! 🎉

---

### Step 2: Download & Flash OpenWrt Factory Image (.trx)

1. Download the latest **`openwrt-jiofiber_jcow414_v1.1.trx`** (or `openwrt-jiofiber_jcow414_v1.1.trx`) from [Releases](https://github.com/Asjohn720/jiofiber-jcow414-openwrt/releases).
2. On your PC, open a terminal in the folder where you downloaded the `.trx` file and start a local HTTP server:
   ```bash
   python -m http.server 8000
   ```
3. In your router's Telnet shell (`root@192.168.29.1`), download the firmware into RAM (`/tmp`):
   ```sh
   cd /tmp
   # Replace <YOUR_PC_IP> with your computer's actual LAN IP (e.g., 192.168.29.x)
   wget http://<YOUR_PC_IP>:8000/openwrt-jiofiber_jcow414_v1.1.trx -O openwrt.trx
   ```
4. Flash the factory image into **Bank 1 (`tclinux`)** using the mandatory `-f` force flag:
   ```sh
   # IMPORTANT: The -f flag is mandatory to bypass stock Broadcom TRX header check
   mtd -f write /tmp/openwrt.trx tclinux
   ```

---

### Step 3: Switch Active Boot Bank & Reboot

> **Shell matters here.** `/usr/bin/sys` exists **only in the stock firmware** and is used from the stock Telnet shell (`root@192.168.29.1`) before OpenWrt boots. It does **not** exist in OpenWrt. The OpenWrt-side equivalent is `/sbin/en75_chboot` — the two are not interchangeable.

At this point the router is still running stock firmware from Bank 2 (`tclinux_slave`), and you have written OpenWrt into Bank 1 (`tclinux`). Switch the hardware boot flag to Bank 1 and reboot, from the **stock** shell:
```sh
# STOCK firmware Telnet shell only (root@192.168.29.1):
/usr/bin/sys bootflag swap
reboot
```

After the reboot the router boots into **OpenWrt**. Wait until the front status LED turns **green** — this indicates a successful boot. Keep an **Ethernet cable** handy — Wi-Fi is not configured yet, so the first login must be done over Ethernet.

1. Once the status LED is green, connect your PC to **LAN Port 1** of the router with an Ethernet cable (green & amber LEDs will blink).
2. Wait ~60 seconds, then open `http://192.168.1.1` in your browser.
3. If the page does not load (your PC did not get a DHCP lease), set your PC's Ethernet adapter to a static IP:
   * **IP address:** `192.168.1.2`
   * **Subnet mask:** `255.255.255.0`
   * **Gateway:** `192.168.1.1`

   Then open `http://192.168.1.1` again.
4. Log in to the **OpenWrt LuCI** dashboard (prebuilt image: user `root`, password `root` — change it under **System → Administration**).
5. Enable Wi-Fi: go to **Network → Wireless**, click **Edit** on each radio (2.4 GHz / 5 GHz), tick **Enable**, set your **SSID** and a **WPA2-PSK** key, then click **Save & Apply**.

You will be greeted by the **OpenWrt LuCI Dashboard**! 🎉

> **Bank switching once OpenWrt is running:** use `/sbin/en75_chboot` (there is no `/usr/bin/sys` in OpenWrt):
> * `/sbin/en75_chboot` — print the current boot flag (e.g. `Current boot flag set to OS A (OpenWrt)`)
> * `/sbin/en75_chboot factory` — set the boot flag to the stock firmware bank
> * `/sbin/en75_chboot openwrt` — set the boot flag to the OpenWrt bank
>
> Always run `reboot` afterwards for the change to take effect.

---

## Dual-Bank Failsafe & Rollback

The JCOW414 flash partition layout contains two independent firmware banks:
* **Bank 1 (`mtd2` / `tclinux`):** OpenWrt target — inactive before flashing, receives the `.trx` (see Step 2)
* **Bank 2 (`mtd5` / `tclinux_slave`):** Stock Jio R2.15 — the bank the stock firmware normally boots from; left untouched as the recovery bank

If you ever wish to return to stock firmware:
1. Access the OpenWrt terminal via SSH: `ssh root@192.168.1.1`.
2. Switch the boot flag back to the stock bank in the `reservearea` partition, then reboot:
   ```sh
   /sbin/en75_chboot factory
   reboot
   ```
3. To go back to OpenWrt again, run `/sbin/en75_chboot openwrt` followed by `reboot`. Running `/sbin/en75_chboot` with no arguments prints the current boot flag (e.g. `Current boot flag set to OS A (OpenWrt)`).

*(Even in the event of an incomplete flash, the stock bootloader automatically rolls back if Bank 1 fails validation).*

---

## 🛠️ Compiling From Source

If you want to build custom packages or customize your OpenWrt firmware from source:

1. **Install build dependencies (Ubuntu 22.04+ / WSL2):**
   ```bash
   sudo apt update && sudo apt install -y build-essential clang flex bison g++ gawk \
   gcc-multilib gettext git libncurses-dev libssl-dev python3-distutils rsync unzip zlib1g-dev file wget
   ```

2. **Clone the OpenWrt source with EcoNet / Airoha support:**
   ```bash
   git clone --depth=1 -b airoha https://github.com/Sirherobrine23/openwrt.git openwrt-jcow414
   cd openwrt-jcow414
   ./scripts/feeds update -a && ./scripts/feeds install -a
   ```

3. **Install the JCOW414 Device Tree:**
   ```bash
   cp /path/to/openwrt/en7528-sercomm-jcow414.dts target/linux/econet/dts/
   ```

4. **Apply configuration:**
   ```bash
   bash /path/to/openwrt/setup_config.sh
   ```

5. **Build the firmware:**
   ```bash
   # Note: Clear Windows PATH entries if building inside WSL2
   export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
   make download -j8
   make -j$(nproc)
   ```

The dual-bank flashable image will be generated under:  
`bin/targets/econet/en7528/openwrt-*-squashfs-tclinux.trx`

---

## Hardware Specifications

| Component | Specification | Details |
|---|---|---|
| **Model** | Sercomm JCOW414 / JioFiber JCO4032 | Reliance Jio Infocomm Home Gateway |
| **SoC** | EcoNet EN7528HU | Dual-Core MIPS 1004Kc @ 900MHz (4 VPEs, little-endian `mipsel_24kc`) |
| **RAM** | 512 MB DDR3 | SK Hynix H5TQ4G63EFR (**432 MB usable** system RAM) |
| **Flash** | 256 MB SPI-NAND + 1 MB SPI-NOR | Micron MT29F2G01 (Firmware/Storage) + Puya P25Q80L (Stage 1 Bootloader) |
| **Ethernet** | 4x Gigabit LAN Ports | Internal EcoNet switch (1000BASE-T full duplex verified) |
| **LAN LEDs** | Hardware GPHY Offloaded | Green & Amber status LEDs per port driven by internal PHYs |
| **2.4 GHz Wi-Fi** | MediaTek MT7603E | 802.11b/g/n 2T2R MIMO (PCIe Bus 1, `14c3:7603`) |
| **5 GHz Wi-Fi** | MediaTek MT7613E | 802.11a/n/ac Wave 2 2T2R MU-MIMO (PCIe Bus 2, `14c3:7663`) |
| **USB** | 2x USB Ports | USB 2.0 / USB 3.0 Host support (Storage & 4G/5G Dongles) |
| **Failsafe** | Dual-Bank Flash | Bank 1 (`tclinux` / `mtd2`) + Bank 2 (`tclinux_slave` / `mtd5`) |
| **Wiki Page** | [OpenWrt ToH](https://openwrt.org/toh/sercomm/jcow414) | Official hardware dataentry & community guide |

---

## Current Status

- [x] **Linux 6.18 Kernel:** Boots cleanly on EcoNet EN7528HU SoC with full 4 VPE CPU detection.
- [x] **Memory Management:** Full 432 MB physical DDR3 RAM mapped and operational.
- [x] **Network Switch:** All 4 Gigabit Ethernet LAN ports active with link speed negotiation and DSA bridge.
- [x] **Dual-Band Wi-Fi:** 2.4 GHz (MT7603E) & 5 GHz (MT7613E/MT7663) fully functional with factory NVMEM calibration.
- [x] **USB 2.0 / USB 3.0 Host:** SuperSpeed xHCI controller active with dual independent 5V VBUS power regulators.
- [x] **Web UI:** LuCI bootstrap web administration interface running out of the box with SSL at `192.168.1.1`.
- [x] **Storage Overlay:** Persistent UBIFS writable overlay over MTD-concatenated virtual flash (`rootfs_data`).
- [x] **Factory `.trx` Packaging:** EcoNet `HDR2` container with custom LZMA compression for stock MTD flasher compatibility.
- [x] **Zero-Risk Rollback:** Dual-bank safe flashing keeps stock firmware in Bank 2 as an instant fallback.
- [ ] **GPON SFP/PON:** Optical uplink driver not yet ported to upstream kernel (use as high-performance Gigabit Wi-Fi router / Access Point / Dumb AP).

---

## Repository Structure

```
jiofiber-jcow414-openwrt/
├── openwrt/
│   ├── en7528-sercomm-jcow414.dts   # Linux Device Tree Source for JCOW414
│   └── setup_config.sh              # Automated build configuration script
├── tools/
│   ├── patch_backup.bat             # 1-Click JioFiber Universal Root Unlocker (Interactive CLI)
│   └── patch_backup.py              # 1-Click Linux / macOS root patch script
├── docs/
│   └── screenshots/
│       └── Openwrt_dashboard.png    # Live verified LuCI system status
├── .gitignore
├── LICENSE                          # GNU General Public License v2.0
└── README.md
```

---

## Author & Credits

* **Anand ([@Asjohn720](https://github.com/Asjohn720))** — Device Tree Source (`en7528-sercomm-jcow414.dts`), kernel memory mapping, dual-bank packaging, and OpenWrt compilation.
* **zke-7D6 ([zke-7D6/jio-jcow414-research](https://github.com/zke-7D6/jio-jcow414-research))** — Initial JCOW414 hardware teardown, UART serial pinout analysis, and bootloader research.
* **gpsarathy ([gpsarathy/JioFiber-Home-Gateway](https://github.com/gpsarathy/JioFiber-Home-Gateway))** — Static firmware decryption keys archive and JioFiber Home Gateway research.
* **OpenWrt Project** — The extensible open-source Linux operating system for embedded routers.
* **Airoha / EcoNet Linux Developers** — Kernel 6.x EcoNet EN75xx platform staging tree.
* **Community Contributors** — Hardware teardown and research documentation.

---

## Legal Disclaimer & Fair Use Notice

This project is an independent academic, educational, and hardware preservation initiative conducted strictly on privately owned, fully paid consumer hardware:
* **Lawful Interoperability:** Research and development are carried out under lawful interoperability doctrines (including Section 52(1)(ab) of the Indian Copyright Act, 1957, and international Fair Use principles permitting reverse engineering solely for achieving interoperability).
* **No ISP Infrastructure Targeted:** At no point was any telecommunications infrastructure, ISP network, optical line terminal (OLT), authentication server, or subscriber database accessed, modified, or compromised. This project does NOT bypass ISP billing, does NOT grant unauthorized network access, and does NOT interact with any live telecommunications backend.
* **100% Open Source Software:** No proprietary vendor code or encrypted copyrighted intellectual property is hosted or distributed by this repository. OpenWrt is a free, independently developed operating system governed by the GNU General Public License (GPL).
* **Trademarks:** All brand names, logos, and trademarks (including "Jio", "JioFiber", "Reliance", and "Sercomm") are the property of their respective owners and are used here purely for nominative hardware identification.
