
# 🛡️ MichalAFerber Pi-hole Blocklists & Streaming Allowlists

A modern, modular Pi-hole blocklist project inspired by the excellent
https://github.com/StevenBlack/hosts — designed for:

- Home-lab networks
- pfSense / OPNsense + Pi-hole deployments
- VLAN-segmented environments
- Streaming-safe ad/tracker blocking

This repository generates a **unified hosts file** and maintains **known-good allowlists**.

---

## 📁 Repository Structure

pi-hole/
├── README.md
├── hosts/
│   ├── base-hosts.txt
│   ├── extra-privacy.txt
│   ├── local-overrides.txt
│   └── unified-hosts.txt
├── allowlists/
│   ├── streaming/
│   └── misc/
└── scripts/

---

## 🚀 Usage

Add this URL to Pi-hole Adlists:

https://raw.githubusercontent.com/MichalAFerber/pi-hole/main/hosts/unified-hosts.txt

Then update gravity.

---

## 🏗️ Build Unified Hosts

./scripts/generate-unified-hosts.sh

---

## 🏷️ Versioning

Auto-tagged as: vYYYY.MM.DD.HHMM

---

## 📜 License

MIT
