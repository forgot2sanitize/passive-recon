#!/usr/bin/env bash

# Passive Recon Script v1.0
# Author: Serhii Chornobai
# Date created: 08.04.2026
# Last modified: 08.04.2026
#
# Description:
#   Passively enumerates subdomains via subfinder + assetfinder, deduplicates results,
#   then probes for live hosts using the ProjectDiscovery httpx Go tool
#   Designed to be VDP-safe

set -euo pipefail

# DEFAULT SETTINGS - VDP-friendly values

SUBFINDER_THREADS=10
HTTPX_THREADS=15
HTTPX_RATE=20

# COLORS

GREEN="\e[32m"
BLUE="\e[34m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

# INPUT VALIDATION

if [ $# -lt 1 ]; then
    echo -e "${RED}[!] Usage: $0 <domain>${RESET}"
    exit 1
fi

RECON_DIR="recon_${TARGET_DOMAIN}"

# DEPENDENCY CHECK

REQUIRED_TOOLS=("subfinder" "assetfinder" "httpx")
echo -e "${BLUE}[*] Checking required tools...${RESET}"

MISSING_TOOLS=0
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        echo -e "${RED}[!] Missing: $tool${RESET}"
        MISSING_TOOLS=1
    else
        echo -e "${GREEN}[✓] Found: $tool${RESET}"
    fi
done

if [ "$MISSING_TOOLS" -eq 1 ]; then
    echo -e "\n${YELLOW}[*] Install missing tools with:${RESET}"
    echo "    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    echo "    go install github.com/tomnomnom/assetfinder@latest"
    echo "    go install github.com/projectdiscovery/httpx/cmd/httpx@latest"
    exit 1
fi

# Guard: the Python httpx library has the same name as ProjectDiscovery tool - confirm we have the ProjectDiscovery Go tool

echo -e "${BLUE}[*] Verifying httpx is the ProjectDiscovery Go version...${RESET}"
HTTPX_VERSION_OUTPUT=$(httpx -version 2>&1 || true)

if ! echo "$HTTPX_VERSION_OUTPUT" | grep -qi "projectdiscovery"; then
    echo -e "${RED}[!] ERROR: The 'httpx' on your PATH does NOT appear to be the"
    echo -e "    ProjectDiscovery Go tool. Found version output:${RESET}"
    echo -e "    $HTTPX_VERSION_OUTPUT"
    echo -e "${YELLOW}[*] Fix: install the correct httpx with:${RESET}"
    echo "    go install github.com/projectdiscovery/httpx/cmd/httpx@latest"
    echo -e "${YELLOW}[*] Then make sure ~/go/bin is before any Python paths in \$PATH.${RESET}"
    exit 1
fi

echo -e "${GREEN}[✓] httpx is the ProjectDiscovery Go version${RESET}"

# START RECON

echo -e "\n${BLUE}[*] Target       : $TARGET_DOMAIN${RESET}"
echo -e "${YELLOW}[*] VDP-safe settings:${RESET}"
echo -e "    subfinder threads : $SUBFINDER_THREADS"
echo -e "    httpx threads     : $HTTPX_THREADS"
echo -e "    httpx rate-limit  : $HTTPX_RATE req/s"
echo ""

mkdir -p "$RECON_DIR"

# STEP 1 - SUBFINDER

echo -e "${GREEN}[+] Running subfinder...${RESET}"
subfinder -d "$TARGET_DOMAIN" -silent -t "$SUBFINDER_THREADS" | tee "$RECON_DIR/subfinder.txt"

# STEP 2 - ASSETFINDER

echo -e "${GREEN}[+] Running assetfinder...${RESET}"
assetfinder --subs-only "$TARGET_DOMAIN" | tee "$RECON_DIR/assetfinder.txt"

# STEP 3 - COMBINE & DEDUPLICATE

echo -e "${GREEN}[+] Combining and deduplicating results...${RESET}"

cat "$RECON_DIR/subfinder.txt" "$RECON_DIR/assetfinder.txt" | sort -u | tee "$RECON_DIR/all_subdomains.txt"

TOTAL_SUBDOMAINS=$(wc -l < "$RECON_DIR/all_subdomains.txt")
echo -e "${BLUE}[*] Total unique subdomains found: $TOTAL_SUBDOMAINS${RESET}"

# Guard: skip httpx entirely if no subdomains were found

if [ "$TOTAL_SUBDOMAINS" -eq 0 ]; then
    echo -e "\n${YELLOW}[!] No subdomains discovered for '$TARGET_DOMAIN'.${RESET}"
    echo -e "${YELLOW}    Possible reasons:${RESET}"
    echo -e "    • Domain is out of scope or private"
    echo -e "    • subfinder API keys are missing (~/.config/subfinder/provider-config.yaml)"
    echo -e "    • Network or DNS issue"
    echo -e "\n${YELLOW}[*] Skipping live-host probe. Recon output saved to: $RECON_DIR${RESET}"
    exit 0
fi

# STEP 4 - PROBE LIVE HOSTS

echo -e "${GREEN}[+] Probing live hosts with httpx...${RESET}"

cat "$RECON_DIR/all_subdomains.txt"| httpx -silent -threads "$HTTPX_THREADS" -rate-limit "$HTTPX_RATE" | tee "$RECON_DIR/live_hosts.txt"

LIVE_HOST_COUNT=$(wc -l < "$RECON_DIR/live_hosts.txt")
echo -e "${BLUE}[*] Live hosts found: $LIVE_HOST_COUNT${RESET}"

# SUMMARY

echo -e "\n${GREEN}[✓] Recon completed safely!${RESET}"
echo -e "${BLUE}[*] Results saved to: $RECON_DIR/${RESET}"