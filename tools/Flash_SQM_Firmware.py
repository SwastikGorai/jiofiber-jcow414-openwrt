#!/usr/bin/env python3
"""Flash the SQM-enabled OpenWrt firmware (1.1-sqm) onto a rooted JCOW414.

Run this on your PC AFTER the root Telnet unlock (stock R2.15 with root/password).
It downloads the firmware from this repo, verifies its SHA256, serves it over
HTTP, pushes it through the router's Telnet shell, and flashes bank 1.

Pure stdlib; works on Windows / Linux / macOS (Python 3.8+).
"""
import hashlib
import http.server
import os
import socket
import sys
import threading

FW_NAME = "openwrt-asjohn720-1.1-sqm-jcow414-econet-en7528-jiofiber_jcow414-squashfs-tclinux.trx"
FW_URL = "https://raw.githubusercontent.com/SwastikGorai/jiofiber-jcow414-openwrt/main/sqm/firmware/" + FW_NAME
FW_SHA256 = "f98cf66c13b1269e9794cc1307c456466beb85676fa7242794ecf83a0a8d14e4"
ROUTER_IP = "192.168.29.1"
TELNET_USER = "root"
TELNET_PASS = "password"


def my_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s.close()


def download():
    if not os.path.exists(FW_NAME):
        print(f"[i] Downloading {FW_URL}")
        import urllib.request
        urllib.request.urlretrieve(FW_URL, FW_NAME)
    else:
        print(f"[i] Using local {FW_NAME}")
    h = hashlib.sha256(open(FW_NAME, "rb").read()).hexdigest()
    if h != FW_SHA256:
        print(f"[!] SHA256 MISMATCH\n    got      {h}\n    expected {FW_SHA256}\n    Delete the file and retry.")
        sys.exit(1)
    print(f"[ok] SHA256 verified: {h}")
    return os.path.abspath(FW_NAME)


class Telnet:
    def __init__(self, host, port=23, timeout=15):
        self.sock = socket.create_connection((host, port), timeout)
        self.sock.settimeout(3)
        self.buf = b""

    def read_until(self, marker, timeout=15):
        self.sock.settimeout(timeout)
        while marker not in self.buf:
            chunk = self.sock.recv(4096)
            if not chunk:
                raise RuntimeError("connection closed")
            self.buf += chunk
        out, self.buf = self.buf, b""
        return out.decode("utf-8", "replace")

    def send(self, line):
        self.sock.sendall(line.encode() + b"\n")

    def run(self, cmd, wait=3):
        self.send(cmd)
        try:
            self.sock.settimeout(wait)
            data = b""
            while True:
                chunk = self.sock.recv(4096)
                if not chunk:
                    break
                data += chunk
                if data.rstrip().endswith(b"#") or data.rstrip().endswith(b"$"):
                    break
            return data.decode("utf-8", "replace")
        except socket.timeout:
            return data.decode("utf-8", "replace")


def main():
    print("=" * 62)
    print(" JCOW414 SQM Firmware Installer (OpenWrt-Asjohn720 1.1-sqm)")
    print(" Prereq: stock R2.15 rooted via Telnet (root/password)")
    print("=" * 62)
    ip = input(f"Router IP [{ROUTER_IP}]: ").strip() or ROUTER_IP
    fw = download()

    print("[i] Starting local HTTP server")
    os.chdir(os.path.dirname(fw))
    srv = http.server.ThreadingHTTPServer(("0.0.0.0", 8000), http.server.SimpleHTTPRequestHandler)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    url = f"http://{my_ip()}:8000/{FW_NAME}"

    print(f"[i] Connecting Telnet {ip}:23")
    tn = Telnet(ip)
    tn.read_until(b"login:")
    tn.send(TELNET_USER)
    tn.read_until(b"assword:")
    tn.send(TELNET_PASS)
    tn.read_until(b"#")
    print("[ok] Root shell")

    print("[i] Router downloading firmware...")
    print(tn.run(f"cd /tmp && rm -f sqm.trx && wget -q '{url}' -O sqm.trx && ls -l sqm.trx", wait=120))
    h = tn.run("sha256sum /tmp/sqm.trx", wait=10)
    print(h)
    if FW_SHA256 not in h:
        print("[!] Router-side SHA256 mismatch, aborting.")
        sys.exit(1)
    print("[ok] Router verified firmware")

    if input(f"[?] Flash {FW_NAME} to bank 1 (tclinux)? This reboots the router. Type FLASH to continue: ").strip() != "FLASH":
        print("[i] Aborted, nothing written.")
        sys.exit(0)

    print("[i] Writing bank 1 (takes 1-2 minutes)...")
    print(tn.run("mtd -f write /tmp/sqm.trx tclinux", wait=300))
    print("[i] Switching boot flag to bank 1 and rebooting...")
    tn.run("/usr/bin/sys bootflag swap", wait=10)
    tn.run("reboot", wait=5)
    print("[ok] Done. Wait ~2 minutes, then connect to http://192.168.1.1")
    print("     SQM is under Network -> SQM QoS (disabled by default; interface lan4 = port nearest USB).")


if __name__ == "__main__":
    main()
