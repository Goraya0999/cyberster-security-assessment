# WEEK 1 - TASKS 2, 3, 4: Complete Practical Guide
## Infrastructure Profiling → GitHub Dorking → Live Asset Filtering

**Target:** hackthissite.org  
**Purpose:** Study & Lab Practice Only  
**Total Time:** ~1.5-2 hours

---

## 📋 TASKS OVERVIEW

| Task | Name | Purpose | Time |
|------|------|---------|------|
| **Task 2** | Infrastructure & Tech Profiling | Identify tech stack, hosting, sensitive files | 30-40 min |
| **Task 3** | GitHub Dorking & Credential Leaks | Search for leaked secrets in repos | 20-30 min |
| **Task 4** | Live Asset Filtering & Visual Recon | Screenshot alive subdomains | 30-40 min |

---

# 🎯 TASK 2: INFRASTRUCTURE & TECH PROFILING

## What You're Discovering

You have 1,000+ subdomains from Task 1. Now:
1. **Fingerprint tech stack** (What software is running?)
2. **Map infrastructure** (Where is it hosted?)
3. **Find sensitive files** (Are there exposed configs?)
4. **Query DNS records** (What's the network topology?)

---

## 📊 SECTION 1: WEB TECHNOLOGY DETECTION

### Step 2.1 - Install & Run WhatWeb

**Installation:**
```bash
# Method 1: If installed on Kali
whatweb -h

# Method 2: Install from source
git clone https://github.com/urbanadventurer/WhatWeb.git
cd WhatWeb
chmod +x whatweb
sudo apt install ruby-dev -y
sudo gem install bundler
bundle install
```

**Basic Command (Single URL):**
```bash
whatweb https://hackthissite.org
```

**Expected Output:**
```
https://hackthissite.org [200 OK] 
Apache[2.4.41], 
PHP[7.4], 
JQuery[3.5.1], 
Bootstrap[4.5.2],
Google Analytics,
Cloudflare
```

**Understanding output:**
- **Apache 2.4.41** = Web server (potential CVEs)
- **PHP 7.4** = Backend language (check for vulnerabilities)
- **jQuery 3.5.1** = JavaScript library
- **Bootstrap** = Frontend framework
- **Cloudflare** = CDN in use (real IP hidden)

**Run on multiple subdomains:**
```bash
# Create list of live subdomains (from Task 1)
cat analysis/high_confidence_subs.txt | head -20 > top_20_subs.txt

# Modify to include full URLs
sed 's/^/https:\/\//' top_20_subs.txt > urls.txt

# Run WhatWeb on all
for url in $(cat urls.txt); do
  echo "=== $url ===" | tee -a whatweb_results.txt
  whatweb "$url" 2>/dev/null | tee -a whatweb_results.txt
  echo "" >> whatweb_results.txt
done
```

**Aggregate results:**
```bash
cat whatweb_results.txt | grep -i "Apache\|Nginx\|IIS\|WordPress\|Laravel"
```

---

### Step 2.2 - Wappalyzer (More Detailed)

**Installation:**

Option A: Using NPM (Node.js):
```bash
# Check if Node/npm installed
node -v
npm -v

# If not:
sudo apt install nodejs npm -y

# Install Wappalyzer CLI
sudo npm install -g wappalyzer
```

Option B: Using apt:
```bash
sudo apt install wappalyzer -y
```

**Run Wappalyzer:**
```bash
# Single URL
wappalyzer https://hackthissite.org

# Multiple URLs
cat urls.txt | while read url; do
  echo "=== Testing $url ===" 
  wappalyzer "$url" 2>/dev/null
  echo ""
done
```

**Advanced: JSON Output**
```bash
# Get structured output
wappalyzer https://hackthissite.org --output json > tech_stack.json

# Pretty print
cat tech_stack.json | jq '.'
```

**Expected output:**
```json
{
  "url": "https://hackthissite.org",
  "technologies": [
    {
      "slug": "apache",
      "name": "Apache",
      "version": "2.4.41"
    },
    {
      "slug": "php",
      "name": "PHP",
      "version": "7.4"
    },
    {
      "slug": "jquery",
      "name": "jQuery",
      "version": "3.5.1"
    }
  ]
}
```

**Node Wappalyzer (if CLI doesn't work):**
```bash
npx wappalyzer https://hackthissite.org
```

---

## 📍 SECTION 2: WHOIS & DOMAIN OWNERSHIP

### Step 2.3 - WHOIS Lookup

**Installation:**
```bash
# Usually pre-installed
whois --version

# If not:
sudo apt install whois -y
```

**Run WHOIS:**
```bash
whois hackthissite.org > whois_results.txt
cat whois_results.txt
```

**Key information to extract:**
```bash
# Registrar
grep -i "registrar:" whois_results.txt

# Organization
grep -i "organization:" whois_results.txt

# Name Servers
grep -i "name server:" whois_results.txt

# Registrant Contact (if not private)
grep -i "registrant" whois_results.txt

# Abuse contact
grep -i "abuse" whois_results.txt
```

**Example output:**
```
Registrar: GoDaddy.com, Inc.
Organization: HackThisSite
Name Server: NS1.HACKTHISSITE.ORG
Name Server: NS2.HACKTHISSITE.ORG
Registrant Country: US
```

**What this tells you:**
- GoDaddy = Common registrar (large target potential)
- HackThisSite org = Organization name
- NS servers = Where DNS is hosted
- Contact = Abuse/security contacts

---

## 🔎 SECTION 3: DNS QUERIES & INFRASTRUCTURE MAPPING

### Step 2.4 - NSLookup Basics

**Installation:**
```bash
# Usually pre-installed
nslookup -version

# If not:
sudo apt install dnsutils -y
```

**Query A Records (IP addresses):**
```bash
nslookup hackthissite.org
# Shows IP address of main domain
```

**Query specific record types:**
```bash
# A Record (IPv4)
nslookup -type=A hackthissite.org

# AAAA Record (IPv6)
nslookup -type=AAAA hackthissite.org

# MX Record (Mail servers)
nslookup -type=MX hackthissite.org

# NS Record (Name servers)
nslookup -type=NS hackthissite.org

# TXT Record (SPF, DKIM, DMARC)
nslookup -type=TXT hackthissite.org

# CNAME Record (Aliases)
nslookup -type=CNAME www.hackthissite.org
```

**Expected MX Record output:**
```
mail.hackthissite.org     preference = 10, mail exchange = mail.hackthissite.org
```

**Expected TXT Record output (SPF):**
```
v=spf1 include:_spf.google.com ~all
```

---

### Step 2.5 - Dig (More Powerful Alternative)

**Installation:**
```bash
# Usually pre-installed
dig -v

# If not:
sudo apt install dnsutils -y
```

**Run dig:**
```bash
# All records
dig hackthissite.org ANY

# Specific types
dig hackthissite.org MX
dig hackthissite.org NS
dig hackthissite.org TXT
dig hackthissite.org CNAME

# Full output with trace
dig +trace hackthissite.org
```

**Trace DNS hierarchy:**
```bash
# Shows complete DNS resolution path
dig +trace hackthissite.org

# Output shows:
# 1. Root nameserver
# 2. TLD nameserver
# 3. Authoritative nameserver
# 4. Final A record
```

---

## 🔍 SECTION 4: GOOGLE DORKING FOR SENSITIVE FILES

### Step 2.6 - Finding phpinfo() Pages

**Command (in Google):**
```
site:hackthissite.org inurl:phpinfo.php
site:hackthissite.org intitle:"phpinfo()"
site:hackthissite.org inurl:info.php
```

**Why this matters:**
- Shows PHP version
- Lists all loaded modules
- Displays server paths
- Environment variables exposed
- Can reveal database locations

**Manual verification:**
```bash
# If you find one, check it
curl -s "https://hackthissite.org/phpinfo.php" | head -50
```

---

### Step 2.7 - Finding .env Files (CRITICAL)

**Google Dorking:**
```
site:hackthissite.org filetype:env
site:hackthissite.org inurl:.env
site:hackthissite.org ".env"
```

**Why critical:**
- Database passwords
- API keys
- Mail server credentials
- Secret tokens
- AWS/cloud credentials

**If found, it typically contains:**
```
APP_NAME=HackThisSite
APP_ENV=production
APP_KEY=base64:xxxxx
DB_HOST=localhost
DB_DATABASE=hackthissite_db
DB_USERNAME=dbuser
DB_PASSWORD=SecurePassword123
MAIL_HOST=mail.hackthissite.org
MAIL_USERNAME=noreply@hackthissite.org
MAIL_PASSWORD=mailpass
API_KEY=sk_live_xxxxx
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=xxxx
```

---

### Step 2.8 - Finding robots.txt

**Google Dorking:**
```
site:hackthissite.org inurl:robots.txt
```

**Manual check:**
```bash
curl -s "https://hackthissite.org/robots.txt"
```

**What robots.txt reveals:**
```
User-agent: *
Disallow: /admin
Disallow: /private
Disallow: /staging
Disallow: /api/internal
Allow: /public

Sitemap: https://hackthissite.org/sitemap.xml
```

**Why this matters:**
- `/admin` → Admin panel location
- `/staging` → Staging environment (often less secure)
- `/private` → Internal areas
- `/api/internal` → Hidden API endpoints

---

### Step 2.9 - Finding Backup Files

**Google Dorking:**
```
site:hackthissite.org filetype:bak
site:hackthissite.org filetype:zip
site:hackthissite.org filetype:tar
site:hackthissite.org filetype:sql
site:hackthissite.org filetype:old
site:hackthissite.org inurl:backup
site:hackthissite.org ext:sql.bak
```

**What backups contain:**
- Full source code
- SQL database dumps
- Configuration files
- Credentials
- Old API keys

**If found, download them:**
```bash
# Example backup file
wget "https://hackthissite.org/backup.zip"
unzip backup.zip
ls -la
```

---

### Step 2.10 - Directory Listing Discovery

**Google Dorking:**
```
site:hackthissite.org intitle:"Index of"
site:hackthissite.org intitle:"Directory listing"
```

**What it reveals:**
- Uploaded files
- Log files
- Configuration files
- Backup files
- Internal documents

**Manual check:**
```bash
# If you find an index, browse it
curl -s "https://hackthissite.org/uploads/" | head -30
```

---

## 📋 TASK 2 SUMMARY - COMMAND CHEATSHEET

```bash
# 1. Technology Detection
whatweb https://hackthissite.org | tee whatweb.txt
wappalyzer https://hackthissite.org --output json | tee wappalyzer.json

# 2. WHOIS & Ownership
whois hackthissite.org | tee whois.txt

# 3. DNS Queries
nslookup hackthissite.org | tee dns_a.txt
nslookup -type=MX hackthissite.org | tee dns_mx.txt
nslookup -type=NS hackthissite.org | tee dns_ns.txt
nslookup -type=TXT hackthissite.org | tee dns_txt.txt

# 4. Powerful DNS
dig hackthissite.org ANY | tee dig_full.txt
dig +trace hackthissite.org | tee dig_trace.txt

# 5. Google Dorking (manual - go to google.com)
# site:hackthissite.org inurl:phpinfo.php
# site:hackthissite.org filetype:env
# site:hackthissite.org inurl:robots.txt
# site:hackthissite.org filetype:bak
```

---

---

# 🔐 TASK 3: GITHUB DORKING & CREDENTIAL LEAKS

## What You're Discovering

Searching public repositories for:
- Hardcoded API keys
- Database passwords
- SSH private keys
- AWS credentials
- Secret tokens

---

## 📍 SECTION 1: MANUAL GITHUB SEARCHING

### Step 3.1 - Basic Organization Search

**Go to:** https://github.com/search

**Search patterns:**
```
org:targetorg "API_KEY"
org:targetorg "password"
org:targetorg "AWS_SECRET"
org:hackthissite "API_KEY"
```

**Steps:**
1. Go to GitHub search
2. Type search query
3. Click "Code" tab (important!)
4. Sort by "Recently updated"
5. Review results

---

### Step 3.2 - Broad Public Search

**Search patterns:**
```
"hackthissite.org" "API_KEY"
"hackthissite" "AWS_SECRET_ACCESS_KEY"
"hackthissite" "password ="
"hackthissite" "private_key"
```

**Why search beyond org:**
- Developers use personal repos
- Contractors push to private accounts
- Forks may have exposed secrets
- Test repos not officially managed

---

### Step 3.3 - File-Specific Searches

**Common risky files:**
```
filename:.env "hackthissite"
filename:.env.production "hackthissite"
filename:config.js "api"
filename:settings.py "SECRET_KEY"
filename:application.properties "password"
filename:web.config "connection"
filename:database.yml "password"
```

**Command syntax:**
```
filename:.env hackthissite
# Searches for .env files containing "hackthissite"
```

---

## 🔍 SECTION 2: ANALYZING RESULTS

### Step 3.4 - What You're Looking For

**Red flags:**
```
# Real API key (production)
const API_KEY = "sk_live_4eC39HqLyjWDarhtT657j..."

# Real AWS key
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY

# Real password
password = "Admin@123!SecurePass"
DB_PASSWORD = "MyDatabasePassword123"

# Real private key
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA2K...
```

**What to ignore:**
- Test/dummy values
- Commented-out values
- Documentation examples
- Placeholder values like "xxxxx" or "YOUR_API_KEY"

---

### Step 3.5 - Commit History Analysis

**Why it matters:**
- Developer committed secret
- Realized mistake
- Deleted it in next commit
- **Git preserves the history!**

**Steps:**
1. Find the file
2. Click "History" (top right of file)
3. Browse older commits
4. Look for when credential was added

**Example:**
```
Commit 1: Add API integration
+ API_KEY = "sk_live_..."

Commit 2: Remove hardcoded keys (mistake in commit 1)
- API_KEY = "sk_live_..."
```

**Even if removed, the secret was briefly exposed!**

---

## 💻 SECTION 3: COMMAND-LINE GITHUB DORKING

### Step 3.6 - GitHub CLI Tool

**Installation:**
```bash
# Using apt
sudo apt install gh -y

# Or from source
curl -fsSLo /tmp/gh-release.tar.gz https://github.com/cli/cli/releases/download/v2.48.0/gh_2.48.0_linux_amd64.tar.gz
tar xzf /tmp/gh-release.tar.gz
sudo mv gh_2.48.0_linux_amd64/bin/gh /usr/local/bin/
```

**Authenticate (required for searches):**
```bash
gh auth login
# Choose: GitHub.com
# Choose: HTTPS
# Paste personal access token (if you have one)
# Or: Paste SSH key
```

**Search from terminal:**
```bash
# Search code
gh search code "API_KEY" --owner=hackthistestsiteorg --match=all

# Search commits
gh search commits "password" --author=user

# List repositories
gh repo list hackthistestsiteorg
```

---

### Step 3.7 - GitHacker (Dump Full Repository)

**Installation:**
```bash
# Install Go (if needed)
go install github.com/BishopFox/GitHacker@latest

# Or clone
git clone https://github.com/BishopFox/GitHacker.git
cd GitHacker
go build -o githacker
```

**⚠️ CRITICAL: ONLY USE ON AUTHORIZED REPOSITORIES**

**Usage:**
```bash
# Example (if .git exposed):
githacker --url "https://target.com/.git/" --output-folder ./dumped_repo

# Or GitHub raw URL:
githacker "https://raw.githubusercontent.com/user/repo/main/.git/" ./output
```

**After dumping:**
```bash
cd dumped_repo

# View commit history
git log

# Search for passwords in entire history
git log -S "password" --all

# Search for API keys
git grep -i "API_KEY" $(git rev-list --all)

# Show deleted content
git log -p | grep -i "password\|API_KEY"
```

---

## 📋 TASK 3 SUMMARY - QUICK REFERENCE

### Manual GitHub Search Patterns:

```
# Organization searches
org:target "API_KEY"
org:target "AWS_SECRET"
org:target "password"
org:target "private_key"

# File searches
filename:.env target
filename:config.js API
filename:settings.py SECRET
filename:web.config password

# Broad searches
"target.com" "API_KEY"
"target" "ssh_key"
"target" "database_password"

# Combined
org:target filename:.env "password"
```

### Important Notes:

✅ **Ethical considerations:**
- You're searching PUBLIC repositories
- No account hacking required
- This is OSINT (publicly available info)
- Important for bug bounty programs

❌ **Do NOT:**
- Search for private repos
- Use credentials you find
- Abuse exposed secrets
- Report fake findings

---

---

# 📸 TASK 4: LIVE ASSET FILTERING & VISUAL RECON

## What You're Doing

Taking 1,000+ subdomains from Task 1, and:
1. **Filter** dead domains (remove non-responsive)
2. **Screenshot** live ones
3. **Visualize** results
4. **Identify** interesting targets (login panels, admin areas)

---

## 🔌 SECTION 1: LIVE HOST DETECTION

### Step 4.1 - Httprobe (Simple & Fast)

**Installation:**
```bash
# Using Go
go install github.com/tomnomnom/httprobe@latest

# Add Go bin to PATH
export PATH=$PATH:$(go env GOPATH)/bin
```

**Basic usage:**
```bash
# Test single URL
echo "hackthissite.org" | httprobe

# Test from file
cat analysis/high_confidence_subs.txt | httprobe > live_urls.txt

# Prefer HTTPS
cat analysis/high_confidence_subs.txt | httprobe --prefer-https > live_urls_https.txt

# Show response time
cat analysis/high_confidence_subs.txt | httprobe --prefer-https -c 50 | tee live_urls.txt
```

**Expected output:**
```
http://www.hackthissite.org
https://www.hackthissite.org
https://api.hackthissite.org
http://forum.hackthissite.org
https://mail.hackthissite.org
```

**Explanation:**
- Tests both HTTP and HTTPS
- Only shows responding subdomains
- Skips dead/non-responsive hosts
- `--prefer-https`: Uses HTTPS if available

**Count live hosts:**
```bash
wc -l live_urls.txt
# Example: "342 live_urls.txt"
```

**Statistics:**
```bash
total_subdomains=$(wc -l < analysis/merged.txt)
live_subdomains=$(wc -l < live_urls.txt)
percentage=$(echo "scale=2; $live_subdomains * 100 / $total_subdomains" | bc)

echo "Total subdomains: $total_subdomains"
echo "Live subdomains: $live_subdomains"
echo "Response rate: $percentage%"
```

---

### Step 4.2 - Httpx (More Detailed)

**Installation:**
```bash
# Using Go
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
```

**Basic usage:**
```bash
cat analysis/high_confidence_subs.txt | httpx
```

**With detailed output:**
```bash
cat analysis/high_confidence_subs.txt | httpx \
  -status-code \
  -title \
  -tech-detect \
  -o httpx_results.txt
```

**Advanced options:**
```bash
httpx -l analysis/high_confidence_subs.txt \
  -status-code \
  -title \
  -tech-detect \
  -header \
  -fr \
  -o httpx_detailed.txt
```

**Output explanation:**
```
https://www.hackthissite.org [200] [title:HackThisSite - Home] [Apache/2.4.41] [PHP/7.4]
https://api.hackthissite.org [200] [title:API] [Nginx/1.18] [Node.js]
https://admin.hackthissite.org [403] [title:Forbidden]
https://staging.hackthissite.org [200] [title:Staging Environment] [Laravel]
```

**Key information:**
- `[200]` = Responding (good)
- `[403]` = Forbidden (interesting!)
- `[404]` = Not found (not live)
- `[title:...]` = Page title
- `[...2.4.41]` = Web server/framework

**Filter interesting responses:**
```bash
# Find all 200 OK responses
grep "\[200\]" httpx_detailed.txt

# Find all login panels
grep -i "login\|admin\|auth" httpx_detailed.txt

# Find staging environments
grep -i "staging\|dev\|test" httpx_detailed.txt
```

---

## 📸 SECTION 2: SCREENSHOT CAPTURE

### Step 4.3 - Aquatone (Visual Recon)

**Installation:**
```bash
# Download binary
wget https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_amd64_1.7.0.zip
unzip aquatone_linux_amd64_1.7.0.zip
sudo mv aquatone /usr/local/bin/

# Verify
aquatone -h
```

**Requirements:**
- Chrome or Chromium browser
- At least 2GB RAM

**Run Aquatone:**
```bash
# Simple command
cat live_urls.txt | aquatone -out ~/aquatone_results

# With custom options
cat live_urls.txt | aquatone \
  -out ~/aquatone_results \
  -threads 10 \
  -timeout 30
```

**Timeline:**
- 100 live hosts = 2-5 minutes
- 300 live hosts = 10-20 minutes
- 500+ live hosts = 30+ minutes

**View results:**
```bash
# Open HTML report
firefox ~/aquatone_results/aquatone_report.html

# Or use file manager
nautilus ~/aquatone_results/
```

**What you'll see:**
- Grid of all website screenshots
- Click to expand individual screenshots
- Organized by URL
- Easy to spot interesting panels

**Export specific screenshots:**
```bash
# Copy interesting ones
cp ~/aquatone_results/screenshots/*.png ./interesting_screenshots/

# Or use web interface to save manually
```

---

### Step 4.4 - Gowitness (Alternative Approach)

**Installation:**
```bash
# Using Go
go install -v github.com/sensepost/gowitness@latest

# Or download binary
wget https://github.com/sensepost/gowitness/releases/download/2.4.2/gowitness-2.4.2-linux-amd64
chmod +x gowitness-2.4.2-linux-amd64
sudo mv gowitness-2.4.2-linux-amd64 /usr/local/bin/gowitness
```

**Take screenshots:**
```bash
# From file
gowitness file -f live_urls.txt \
  --screenshot-path ~/gowitness_screenshots \
  --threads 5

# With options
gowitness file -f live_urls.txt \
  --screenshot-path ~/gowitness_screenshots \
  --threads 10 \
  --timeout 30
```

**View results (built-in web server):**
```bash
# Start web server
gowitness report serve

# Open browser to
# http://127.0.0.1:7171

# Default port is 7171
# Can change with --port 8080
```

**Gowitness dashboard features:**
- Organized list of screenshots
- Filter by status
- Search by URL
- Download individual screenshots
- Export reports

---

## 📋 SECTION 3: DOCUMENTATION & ANALYSIS

### Step 4.5 - Create Summary Report

**Organize findings:**
```bash
mkdir -p report/{screenshots,data}

# Copy screenshots
cp ~/aquatone_results/screenshots/* report/screenshots/

# Create data file
cat > report/findings.txt << 'EOF'
=== LIVE ASSET RECON REPORT ===
Target: hackthissite.org

STATISTICS:
Total subdomains found (Task 1): 1247
Live subdomains: 342
Response rate: 27.4%

INTERESTING FINDINGS:
1. Admin panel (403 Forbidden)
   - https://admin.hackthissite.org
   - Apache 2.4.41, PHP 7.4
   
2. Staging environment (200 OK)
   - https://staging.hackthissite.org
   - Title: "Staging Environment"
   - Laravel detected
   - Often less secure
   
3. API endpoint
   - https://api.hackthissite.org
   - Node.js backend
   - JSON responses

OBSERVATIONS:
- Cloudflare CDN active (IP masking)
- Multiple WordPress instances detected
- Outdated Apache version (potential CVEs)
- No HTTPS on some subdomains (security concern)

NEXT STEPS:
1. Focus on staging environment
2. Test WordPress plugins for vulnerabilities
3. Check for outdated software
4. Investigate API endpoints
EOF

cat report/findings.txt
```

---

### Step 4.6 - Priority Matrix

**Categorize findings:**
```bash
cat > report/priority_matrix.txt << 'EOF'
HIGH PRIORITY (Test First):
- Staging environments (often less secure)
- Admin panels (direct targets)
- Outdated software (known CVEs)

MEDIUM PRIORITY:
- Live WordPress instances
- Custom applications
- APIs

LOW PRIORITY:
- Static websites
- Parked domains
- Honeypots/traps
EOF
```

---

## 📊 TASK 4 SUMMARY - COMMAND CHEATSHEET

```bash
# 1. Filter live hosts (HTTPROBE)
cat analysis/high_confidence_subs.txt | httprobe --prefer-https > live_urls.txt

# 2. Detailed host info (HTTPX)
cat live_urls.txt | httpx -status-code -title -tech-detect -o httpx_results.txt

# 3. Take screenshots (AQUATONE)
cat live_urls.txt | aquatone -out ~/aquatone_results

# 4. View Aquatone report
firefox ~/aquatone_results/aquatone_report.html

# 5. Alternative screenshots (GOWITNESS)
gowitness file -f live_urls.txt --screenshot-path ~/gowitness_screenshots
gowitness report serve
# Open: http://127.0.0.1:7171

# 6. Count live hosts
echo "Total: $(wc -l < analysis/high_confidence_subs.txt)"
echo "Live: $(wc -l < live_urls.txt)"

# 7. Find interesting URLs
grep -E "admin|staging|dev|api" live_urls.txt
grep "\[403\]" httpx_results.txt  # Forbidden (interesting!)
```

---

## ✅ TASK 4 SUBMISSION CHECKLIST

Before submitting Task 4:

- [ ] Created live_urls.txt (from httprobe)
- [ ] Generated httpx_results.txt with status codes/titles
- [ ] Captured screenshots (Aquatone or Gowitness)
- [ ] Documented statistics (total vs live)
- [ ] Identified interesting targets
- [ ] Created findings report
- [ ] Prioritized results
- [ ] Screenshots show login panels/admin areas
- [ ] Can explain what each finding means
- [ ] Organized and professional presentation

---

## 🎯 KEY LEARNING

**By Task 4, you understand:**
1. Not all discovered subdomains are active
2. Live hosts need deeper investigation
3. Visual reconnaissance helps identify targets
4. Staging/dev environments are priority
5. Outdated software = known vulnerabilities
6. Focus = more efficient than testing everything

---

## ⏱️ ESTIMATED TIMELINE

| Phase | Time |
|-------|------|
| Task 2: Tech profiling | 30-40 min |
| Task 3: GitHub dorking | 20-30 min |
| Task 4: Live filtering & screenshots | 30-40 min |
| **TOTAL** | **1.5-2 hours** |

---

## 📝 NEXT STEPS

Your attack surface is now:
✅ Enumerated (Task 1: 1,000+ subdomains)
✅ Profiled (Task 2: Technology identified)
✅ Leaked-secret checked (Task 3: GitHub scanned)
✅ Filtered & Visualized (Task 4: 300+ live hosts with screenshots)

Ready for: **Week 1 Task 5 - Vulnerability Assessment**

---

Good luck! 💪
