# QUICK REFERENCE - TASKS 2, 3, 4
## Copy-Paste Command Cheatsheet

---

# 🎯 TASK 2: INFRASTRUCTURE & TECH PROFILING

## WhatWeb - Detect Web Technologies

```bash
# Single URL
whatweb https://hackthissite.org

# Multiple URLs from file
for url in $(cat urls.txt); do
  whatweb "$url"
done

# Save to file
whatweb https://hackthissite.org | tee whatweb_result.txt
```

---

## Wappalyzer - Technology Stack

```bash
# Single URL
wappalyzer https://hackthissite.org

# JSON output
wappalyzer https://hackthissite.org --output json | tee tech_stack.json

# Using Node
npx wappalyzer https://hackthissite.org
```

---

## WHOIS - Domain Ownership

```bash
# Full WHOIS
whois hackthissite.org

# Save to file
whois hackthissite.org | tee whois.txt

# Extract specific info
whois hackthissite.org | grep -i "registrar:"
whois hackthissite.org | grep -i "organization:"
whois hackthissite.org | grep -i "name server:"
```

---

## NSLookup - DNS Queries (Simple)

```bash
# A record (IP)
nslookup hackthissite.org

# Specific record types
nslookup -type=A hackthissite.org      # IPv4
nslookup -type=AAAA hackthissite.org   # IPv6
nslookup -type=MX hackthissite.org     # Mail servers
nslookup -type=NS hackthissite.org     # Name servers
nslookup -type=TXT hackthissite.org    # SPF, DKIM, DMARC
nslookup -type=CNAME www.hackthissite.org  # Aliases

# Save results
nslookup hackthissite.org | tee dns_info.txt
```

---

## Dig - DNS Queries (Advanced)

```bash
# All records
dig hackthissite.org ANY

# Specific record types
dig hackthissite.org MX
dig hackthissite.org NS
dig hackthissite.org TXT
dig hackthissite.org A

# Full DNS trace (shows entire resolution path)
dig +trace hackthissite.org

# More detailed
dig +noall +answer hackthissite.org

# Save output
dig hackthissite.org ANY | tee dig_full.txt
```

---

## Google Dorking - Find Sensitive Files

```
# In Google search bar, not terminal!

# phpinfo() pages
site:hackthissite.org inurl:phpinfo.php
site:hackthissite.org intitle:"phpinfo()"

# .env files (CRITICAL)
site:hackthissite.org filetype:env
site:hackthissite.org inurl:.env
site:hackthissite.org ".env"

# robots.txt
site:hackthissite.org inurl:robots.txt

# Backup files
site:hackthissite.org filetype:bak
site:hackthissite.org filetype:zip
site:hackthissite.org filetype:tar
site:hackthissite.org filetype:sql
site:hackthissite.org inurl:backup

# Directory listing
site:hackthissite.org intitle:"Index of"
site:hackthissite.org intitle:"Directory listing"

# Configuration files
site:hackthissite.org filetype:conf
site:hackthissite.org filetype:config
```

---

## Automated Task 2 Script

```bash
#!/bin/bash
TARGET="hackthissite.org"

echo "=== WhatWeb ==="
whatweb https://$TARGET | tee whatweb.txt

echo "=== Wappalyzer ==="
wappalyzer https://$TARGET --output json | tee wappalyzer.json

echo "=== WHOIS ==="
whois $TARGET | tee whois.txt

echo "=== DNS (dig) ==="
dig $TARGET ANY | tee dns_dig.txt

echo "=== MX Records ==="
dig $TARGET MX | tee dns_mx.txt

echo "=== Name Servers ==="
dig $TARGET NS | tee dns_ns.txt

echo "Done! Check *.txt files"
```

---

---

# 🔐 TASK 3: GITHUB DORKING & CREDENTIAL LEAKS

## Manual GitHub Searches

**Go to:** https://github.com/search

```
# Organization searches
org:hackthissite "API_KEY"
org:hackthissite "AWS_SECRET"
org:hackthissite "password"
org:hackthissite "private_key"

# File-specific searches
filename:.env hackthissite
filename:.env.production hackthissite
filename:config.js api
filename:settings.py SECRET_KEY
filename:web.config password
filename:application.properties password

# Broad searches
"hackthissite.org" "API_KEY"
"hackthissite.org" "password ="
"hackthissite.com" "AWS_ACCESS_KEY"
"hackthissite" "ssh_key"
"hackthissite" "private_key"

# Combined (org + file)
org:hackthissite filename:.env "password"
```

**After searching:**
1. Click "Code" tab (not Issues/Users)
2. Sort by "Recently updated"
3. Review each result
4. Click "History" to see commit history

---

## GitHub CLI - Command Line Search

```bash
# Authenticate first
gh auth login

# Search for API keys
gh search code "API_KEY" --owner=hackthissite

# Search for passwords
gh search code "password" --owner=hackthissite --match=all

# Search for AWS credentials
gh search code "AWS_SECRET" --owner=hackthissite

# List all repos
gh repo list hackthissite
```

---

## GitHacker - Dump Repository

```bash
# ⚠️ ONLY ON AUTHORIZED REPOS!

# Install
go install github.com/BishopFox/GitHacker@latest

# Dump repository
githacker --url "https://target.com/.git/" --output-folder ./dumped_repo

# After dumping
cd dumped_repo

# View commit history
git log

# Search history for passwords
git grep -i "password" $(git rev-list --all)
git grep -i "API_KEY" $(git rev-list --all)

# Show commits where secret was added/removed
git log -S "password" --all
git log -S "API_KEY" --all

# View full history with changes
git log -p | grep -B 5 -A 5 "password\|API_KEY"
```

---

## What to Look For (Red Flags)

```
# REAL API keys (production)
const API_KEY = "sk_live_4eC39HqLyjWDarhtT657j..."
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
STRIPE_SECRET_KEY="sk_live_..."

# REAL passwords
password = "Admin@123!SecurePass"
DB_PASSWORD = "MyDatabasePassword123"
MAIL_PASSWORD = "SecureMailPassword"

# REAL private keys
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA2K...

# Ignore these (NOT real):
API_KEY = "your_api_key_here"
password = "xxxxx"
token = "PLACEHOLDER"
db_pass = "change_this"
```

---

---

# 📸 TASK 4: LIVE ASSET FILTERING & VISUAL RECON

## Httprobe - Find Live Hosts

```bash
# From file
cat analysis/high_confidence_subs.txt | httprobe > live_urls.txt

# Prefer HTTPS
cat analysis/high_confidence_subs.txt | httprobe --prefer-https > live_urls.txt

# With timeout
cat analysis/high_confidence_subs.txt | httprobe --prefer-https -t 5000 > live_urls.txt

# Count results
wc -l live_urls.txt
```

---

## Httpx - Detailed Host Info

```bash
# Basic
cat live_urls.txt | httpx

# With details
cat live_urls.txt | httpx \
  -status-code \
  -title \
  -tech-detect \
  -o httpx_results.txt

# Full details
httpx -l analysis/high_confidence_subs.txt \
  -status-code \
  -title \
  -tech-detect \
  -header \
  -fr \
  -o httpx_detailed.txt

# Filter interesting results
grep "\[200\]" httpx_results.txt          # Responding
grep -i "login\|admin" httpx_results.txt  # Login pages
grep -i "staging\|dev" httpx_results.txt  # Dev environments
grep "\[403\]" httpx_results.txt          # Forbidden (interesting!)
```

---

## Aquatone - Screenshot All Live Hosts

```bash
# Install
wget https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_amd64_1.7.0.zip
unzip aquatone_linux_amd64_1.7.0.zip
sudo mv aquatone /usr/local/bin/

# Run simple
cat live_urls.txt | aquatone -out ~/aquatone_results

# Run advanced
cat live_urls.txt | aquatone \
  -out ~/aquatone_results \
  -threads 10 \
  -timeout 30

# View results
firefox ~/aquatone_results/aquatone_report.html
```

---

## Gowitness - Alternative Screenshots

```bash
# Install
go install -v github.com/sensepost/gowitness@latest

# Take screenshots
gowitness file -f live_urls.txt \
  --screenshot-path ~/gowitness_screenshots \
  --threads 5

# View results (web server)
gowitness report serve

# Open browser to:
# http://127.0.0.1:7171
```

---

## Statistics & Analysis

```bash
# Count statistics
echo "Total subdomains: $(wc -l < analysis/merged.txt)"
echo "Live subdomains: $(wc -l < live_urls.txt)"
echo "Response rate: $(($(wc -l < live_urls.txt) * 100 / $(wc -l < analysis/merged.txt)))%"

# Find interesting URLs
grep -E "admin|api|staging|dev|test" live_urls.txt

# Find forbidden responses (often interesting)
grep "\[403\]" httpx_results.txt

# Find applications
grep -i "wordpress\|laravel\|django\|flask" httpx_results.txt
```

---

## Create Report

```bash
mkdir -p report/{screenshots,data}

cat > report/summary.txt << 'EOF'
=== LIVE ASSET RECON SUMMARY ===
Total subdomains found: $(wc -l < analysis/merged.txt)
Live subdomains: $(wc -l < live_urls.txt)
Response rate: XX%

INTERESTING FINDINGS:
- Admin panels (403)
- Staging environments
- APIs
- Old WordPress versions

KEY TARGETS:
(List your high-priority targets here)
EOF

cp ~/aquatone_results/screenshots/* report/screenshots/
echo "Report ready in ./report/"
```

---

## Complete Task 2-4 One-Liner

```bash
# Task 2
whatweb https://hackthissite.org && \
whois hackthissite.org && \
dig hackthissite.org ANY

# Task 3
# (Manual GitHub search at https://github.com/search)

# Task 4
cat analysis/high_confidence_subs.txt | httprobe --prefer-https > live_urls.txt && \
cat live_urls.txt | httpx -status-code -title -tech-detect -o httpx_results.txt && \
cat live_urls.txt | aquatone -out ~/aquatone_results

echo "All tasks complete!"
```

---

## Time Reference

| Tool | Time |
|------|------|
| WhatWeb | <1 min |
| Wappalyzer | <1 min |
| WHOIS | <1 min |
| DNS queries | <1 min |
| GitHub search | 5-10 min (manual) |
| Httprobe (300 hosts) | 5-10 min |
| Httpx | 5-10 min |
| Aquatone (300 hosts) | 15-30 min |
| **TOTAL** | **~1.5 hours** |

---

## Troubleshooting

| Error | Fix |
|-------|-----|
| `whatweb: command not found` | Kali Linux has it pre-installed; try `which whatweb` |
| `wappalyzer: command not found` | `sudo npm install -g wappalyzer` |
| `httprobe not found` | `go install github.com/tomnomnom/httprobe@latest` |
| `httpx not found` | `go install github.com/projectdiscovery/httpx@latest` |
| Aquatone needs Chrome | `sudo apt install chromium-browser -y` |
| GitHub search timing out | Reduce number of results, search smaller org |
| Screenshots look broken | Make sure Chrome/Chromium is installed |

---

Good luck! Copy-paste these commands and go! 💪
