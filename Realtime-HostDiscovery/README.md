# ARP-Based Network Host Discovery & Monitoring Script

## 📌 Overview
This Bash script continuously discovers and monitors live hosts on a local network using **ARP scanning** instead of traditional ICMP ping. It detects **newly appeared hosts**, maintains an **alive host list**, removes **inactive hosts**, and sends **email notifications** when changes are detected.

Unlike ICMP-based discovery, ARP scanning works even when hosts block ping requests, making it more reliable for local network monitoring.

---

## ✨ Features
- 🔍 **ARP-based host discovery** using `arp-scan`
- 🔁 **Continuous monitoring** of the given network range
- 🧾 Maintains a persistent list of alive hosts
- 📬 **Email alerts** when a new host is discovered
- 🧹 Automatically removes hosts that go offline
- 🔌 Optional network interface selection
- 🧩 Easily extensible to integrate Slack, Discord, MS Teams, etc.

---

## 🛠️ Requirements
Ensure the following tools are installed:

- `arp-scan`
- `sendemail`
- `ping`
- `awk`, `sed`, `grep` (usually preinstalled)

### Install on Debian-based systems
```bash
sudo apt update
sudo apt install arp-scan sendemail -y
