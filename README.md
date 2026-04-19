# 🔐 Passive Recon Script

![Bash](https://img.shields.io/badge/Bash-Script-informational?logo=gnubash)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS-blue)
![Security](https://img.shields.io/badge/Purpose-Passive%20Recon-orange)
![License](https://img.shields.io/badge/License-MIT-green)

> A beginner-friendly Bash script for passive subdomain enumeration and live host detection - built for VDP and bug bounty environments.

---

## About

Built as part of my hands-on learning in web security and bug bounty hunting. The script automates early-stage recon while staying within safe, responsible testing boundaries suitable for VDPs and platforms like HackerOne and Bugcrowd.

---

## Features

- Subdomain enumeration via `subfinder` + `assetfinder`
- Automatic deduplication with `sort -u`
- Live host probing via `httpx` (ProjectDiscovery Go version)
- Validates that `httpx` is the Go tool, not the Python library (same binary name, common conflict)
- Graceful exit if no subdomains are found - no empty `httpx` runs
- Dependency check with install instructions on failure
- Color-coded terminal output
- Full CLI argument parsing via `getopts` (`-d`, `-t`, `-r`, `-o`)

---

## Usage

```bash
git clone https://github.com/forgot2sanitize/passive-recon.git
cd passive-recon
chmod +x recon.sh
./recon.sh -d <domain> [-t threads] [-r rate] [-o output]
```

**Examples**

```bash
# Basic run (defaults for threads, rate, and output directory)
./recon.sh -d example.com

# Custom threads, rate limit, and output directory
./recon.sh -d example.com -t 50 -r 100 -o custom_dir
```

By default, output is written under `recon_<domain>/` (for example, `recon_example.com/` when targeting `example.com`). Use `-o` to choose a different directory.

```
recon_example.com/
├── subfinder.txt
├── assetfinder.txt
├── all_subdomains.txt
└── live_hosts.txt
```

---

## Requirements

Install all three tools via Go:

```bash
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/tomnomnom/assetfinder@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
```

Make sure `~/go/bin` is in your `$PATH` and comes **before** any Python paths to avoid the `httpx` name conflict.

---

## Planned Improvements

- URL discovery (`gau`, `waybackurls`)
- Technology fingerprinting and screenshots

---

## ⚠️ Disclaimer

This project is for **educational purposes only**.

Always:

* Test only authorized targets
* Follow program scope and rules
* Respect legal and ethical guidelines

---

## Contact

LinkedIn: [Serhii Chornobai](https://www.linkedin.com/in/serhiichornobai/)

⭐ Star the repo if you found it useful.