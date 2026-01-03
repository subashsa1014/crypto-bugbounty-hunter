#!/bin/bash
# Crypto.com Passive Reconnaissance Script
# ONLY RUN WITH WRITTEN PERMISSION FROM hackerone@crypto.com

DOMAIN="crypto.com"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
OUTPUT_DIR="recon/subdomains/$DATE"
mkdir -p "$OUTPUT_DIR"

echo "[*] Starting passive recon for $DOMAIN at $DATE"
echo "[*] WARNING: Ensure you have written permission from Crypto.com before running this"
echo ""

# Step 1: Subdomain enumeration using Subfinder
echo "[+] Phase 1: Enumerating subdomains using Subfinder..."
if command -v subfinder &> /dev/null; then
    subfinder -d $DOMAIN -silent -o "$OUTPUT_DIR/all_subdomains.txt"
    TOTAL=$(wc -l < "$OUTPUT_DIR/all_subdomains.txt")
    echo "[*] Found $TOTAL subdomains"
else
    echo "[-] Subfinder not installed. Install with: go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    exit 1
fi

# Step 2: Filter for critical targets
echo "[+] Phase 2: Filtering for critical/high-priority targets..."
grep -iE "(api|admin|internal|staging|dev|exchange|wallet|backup|pay|fund|transaction)" \
    "$OUTPUT_DIR/all_subdomains.txt" > "$OUTPUT_DIR/critical_targets.txt" 2>/dev/null || true

CRITICAL=$(wc -l < "$OUTPUT_DIR/critical_targets.txt")
echo "[!] Found $CRITICAL critical/high-priority subdomains"

# Step 3: Check for new subdomains (compare with previous run)
echo "[+] Phase 3: Comparing with previous results..."
if [ -f "recon/subdomains/latest/all_subdomains.txt" ]; then
    echo "[*] Checking for NEW subdomains..."
    comm -23 <(sort "$OUTPUT_DIR/all_subdomains.txt") \
             <(sort "recon/subdomains/latest/all_subdomains.txt") > "$OUTPUT_DIR/NEW_SUBDOMAINS.txt" || true
    NEW=$(wc -l < "$OUTPUT_DIR/NEW_SUBDOMAINS.txt")
    if [ "$NEW" -gt 0 ]; then
        echo "[!] ALERT: Found $NEW NEW subdomains!"
        echo "[*] New subdomains:"
        cat "$OUTPUT_DIR/NEW_SUBDOMAINS.txt"
    fi
fi

# Update latest results
mkdir -p recon/subdomains/latest
cp "$OUTPUT_DIR/all_subdomains.txt" recon/subdomains/latest/all_subdomains.txt

echo ""
echo "[+] Reconnaissance complete!"
echo "[*] Results saved to: $OUTPUT_DIR"
echo ""
echo "=== SUMMARY ==="
echo "Total Subdomains: $TOTAL"
echo "Critical Targets: $CRITICAL"
echo "========================"
echo ""
echo "[*] Next steps:"
echo "  1. Review critical targets in: $OUTPUT_DIR/critical_targets.txt"
echo "  2. For each target, test for:"
echo "     - Authentication bypass"
echo "     - Authorization flaws"
echo "     - API logic vulnerabilities"
echo "     - Data exposure"
echo "  3. Document findings with PoC"
echo "  4. Submit via HackerOne Report Assistant"
