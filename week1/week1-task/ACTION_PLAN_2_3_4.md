# 🎯 ACTION PLAN - TASKS 2, 3, 4
## Infrastructure Profiling → GitHub Dorking → Live Asset Filtering

---

## 📊 QUICK OVERVIEW

| Task | Name | Duration | Status |
|------|------|----------|--------|
| Task 2 | Infrastructure & Tech Profiling | 30-40 min | Automated |
| Task 3 | GitHub Dorking & Credential Leaks | 20-30 min | Manual (web) |
| Task 4 | Live Asset Filtering & Visual Recon | 30-40 min | Automated |
| **TOTAL** | **Complete Recon Phase** | **~1.5-2 hours** | Mixed |

---

## 🚀 QUICKEST PATH (Use Automation)

```bash
# Step 1: Run Tasks 2 & 4 automation
./run_tasks_2_4.sh

# Step 2: Manual GitHub Dorking (while automation runs or after)
# Go to: https://github.com/search
# Use patterns from QUICK_REFERENCE_2_3_4.md

# Step 3: Review results in output directory
```

**Time:** ~1.5 hours (mostly waiting for automation)

---

## 📋 STEP-BY-STEP WORKFLOW

### PREREQUISITES

Verify you have:
- [ ] Completed Task 1 (1,000+ subdomains)
- [ ] File: `analysis/merged_all_subdomains.txt`
- [ ] Kali Linux or Ubuntu with Go installed
- [ ] Internet connection

---

## TASK 2: INFRASTRUCTURE PROFILING (30-40 min)

### Option A: FULLY AUTOMATED ⚡

```bash
./run_tasks_2_4.sh
# Select "y" when prompted for Task 2
# Select "n" for screenshots (do Task 4 later)
```

**What happens:**
1. Detects web technologies (WhatWeb, Wappalyzer)
2. Queries domain ownership (WHOIS)
3. Maps DNS infrastructure (dig/nslookup)
4. Generates summary report

**Output:** `task_2_4_results_*/task_2/` directory

---

### Option B: STEP-BY-STEP MANUAL

```bash
# 1. Technology Detection
whatweb https://hackthissite.org | tee whatweb.txt
wappalyzer https://hackthissite.org --output json | tee tech_stack.json

# 2. Domain Ownership
whois hackthissite.org | tee whois.txt

# 3. DNS Infrastructure
dig hackthissite.org ANY | tee dns_full.txt
dig hackthissite.org MX | tee dns_mx.txt
dig hackthissite.org NS | tee dns_ns.txt
dig +trace hackthissite.org | tee dns_trace.txt

# 4. Save results
mkdir -p task_2_results
mv whatweb.txt tech_stack.json whois.txt dns_*.txt task_2_results/
```

**Copy-paste commands from:** `QUICK_REFERENCE_2_3_4.md` → TASK 2 section

---

### Key Findings to Document

After Task 2, you should know:

✅ **What technology stack is running?**
- Web server (Apache/Nginx/IIS)
- Backend (PHP/Node/Python)
- CMS (WordPress/Drupal)
- Frameworks (Laravel/Django)

✅ **Who owns the domain?**
- Registrar
- Organization name
- Contact information

✅ **Where is it hosted?**
- DNS servers (nameservers)
- Mail infrastructure
- Cloud provider (AWS/Azure/GCP)
- CDN (Cloudflare/Akamai)

✅ **What are the security implications?**
- Outdated software = Known CVEs
- WordPress = Plugin vulnerabilities
- Misconfigured DNS = Subdomain takeover risk

---

## TASK 3: GITHUB DORKING (20-30 min) - MANUAL

### Can be done while Task 2/4 run!

This requires **manual web searching**, not commands.

### Step 1: Go to GitHub Search

**URL:** https://github.com/search

### Step 2: Search Patterns

Use one of these patterns:

**Organization searches:**
```
org:hackthissite "API_KEY"
org:hackthissite "AWS_SECRET"
org:hackthissite "password"
org:hackthissite "private_key"
```

**File-specific searches:**
```
filename:.env hackthissite
filename:config.js hackthissite
filename:settings.py hackthissite
filename:web.config hackthissite
```

**Broad searches:**
```
"hackthissite.org" "API_KEY"
"hackthissite.com" "password ="
"hackthissite" "AWS_ACCESS_KEY"
```

### Step 3: Review Results

For each result:
1. Click to view the file
2. Check if it's real credentials or test/dummy
3. Click "History" to see if secret was added then deleted
4. Note the commit date

### Step 4: Document Findings

Create a file: `task_3_findings.txt`

```
=== GITHUB DORKING RESULTS ===

Found APIs/Secrets:
- [Link to finding]
- Details
- Risk assessment

Found Configuration Files:
- [Link to finding]
- Contains what info

Commit History Analysis:
- Deleted secrets in commits
- Configuration changes

Risk Assessment:
(Critical / High / Medium / Low)
```

### Step 5: (Advanced) GitHacker - Dump Repository

If you find a .git folder exposed:

```bash
# ⚠️ ONLY ON AUTHORIZED REPOS!

githacker --url "https://target.com/.git/" --output-folder ./dumped_repo
cd dumped_repo
git log -S "password" --all
```

---

## TASK 4: LIVE ASSET FILTERING (30-40 min)

### Option A: FULLY AUTOMATED ⚡

```bash
# If not already running
./run_tasks_2_4.sh

# When prompted for screenshots, choose:
# "y" = Take full screenshots (20-40 min)
# "n" = Skip screenshots (faster)
```

**What happens:**
1. Tests all subdomains for HTTP/HTTPS responses
2. Gets status codes, titles, technologies
3. Takes screenshots of live hosts
4. Generates visual report

---

### Option B: MANUAL STEP-BY-STEP

#### Step 1: Find Live Hosts (Httprobe)

```bash
cat analysis/merged_all_subdomains.txt | \
  httprobe --prefer-https > live_urls.txt

# Check results
wc -l live_urls.txt  # Shows number of live hosts
head -10 live_urls.txt
```

**Expect:** 20-30% of subdomains are live (normal!)

#### Step 2: Get Detailed Info (Httpx)

```bash
cat live_urls.txt | \
  httpx -status-code -title -tech-detect \
  -o httpx_results.txt

# Find interesting targets
grep -i "admin\|staging\|dev" httpx_results.txt
grep "\[403\]" httpx_results.txt  # Forbidden (often interesting!)
grep -i "wordpress\|laravel\|django" httpx_results.txt
```

#### Step 3: Take Screenshots (Aquatone)

```bash
cat live_urls.txt | \
  aquatone -out ~/aquatone_results \
  -threads 8 -timeout 30

# Wait 20-40 minutes...

# View results
firefox ~/aquatone_results/aquatone_report.html
```

**OR Alternative: Gowitness**

```bash
gowitness file -f live_urls.txt \
  --screenshot-path ~/gowitness_screenshots \
  --threads 5

# View web dashboard
gowitness report serve
# Open: http://127.0.0.1:7171
```

---

### Key Findings to Document

After Task 4, you should have:

✅ **Live hosts list** (`live_urls.txt`)

✅ **Response statistics:**
- Total subdomains: X
- Live hosts: Y
- Response rate: Z%

✅ **Interesting targets:**
- Admin panels
- Staging environments
- Forbidden/Access denied (403)
- APIs
- Login pages

✅ **Technology inventory:**
- Web servers detected
- CMS/Frameworks
- Notable versions

✅ **Screenshot grid:**
- Visual overview
- Easy to spot login panels
- Identify dev environments

---

## 📊 COMPLETE WORKFLOW CHART

```
Task 1 Output (1,000+ subdomains)
         ↓
    [TASK 2: INFRASTRUCTURE PROFILING]
    - WhatWeb: Technology detection
    - Wappalyzer: Tech stack
    - WHOIS: Ownership
    - DNS: Infrastructure mapping
         ↓ & ↓ (parallel)
    [TASK 3: GITHUB DORKING]
    - Search for APIs, secrets
    - Check commit history
    - Find exposed credentials
         ↓
    [TASK 4: LIVE ASSET FILTERING]
    - Httprobe: Find responding hosts
    - Httpx: Get details
    - Aquatone: Screenshots
         ↓
    CONSOLIDATED RECONNAISSANCE
    (Ready for exploitation/testing)
```

---

## ⏱️ TIME BREAKDOWN

| Phase | Time | What's Happening |
|-------|------|------------------|
| Task 2 Setup | 5 min | Install tools |
| Task 2 Execution | 25-35 min | Tech profiling + DNS queries |
| Task 3 Setup | 0 min | Just open github.com |
| Task 3 Execution | 20-30 min | Manual searching |
| Task 4 Setup | 5 min | Download/install screenshot tools |
| Task 4 Httprobe | 5-10 min | Test subdomains |
| Task 4 Httpx | 5-10 min | Get detailed info |
| Task 4 Aquatone | 20-40 min | Take screenshots |
| **TOTAL** | **~1.5-2 hours** | Full recon phase |

---

## 📋 SUBMISSION CHECKLIST

### Task 2 Deliverables:

- [ ] WhatWeb results (technology detection)
- [ ] Wappalyzer results (tech stack JSON)
- [ ] WHOIS information (domain ownership)
- [ ] DNS queries (A, MX, NS, TXT, trace)
- [ ] Summary report (key findings)
- [ ] Identified CVE opportunities (outdated software)

### Task 3 Deliverables:

- [ ] GitHub search screenshots (or documentation)
- [ ] Found credentials/secrets (list)
- [ ] Risk assessment (Critical/High/Medium/Low)
- [ ] Commit history analysis (if applicable)
- [ ] Notes on findings

### Task 4 Deliverables:

- [ ] live_urls.txt (list of responding hosts)
- [ ] httpx_results.txt (status codes, titles, tech)
- [ ] Screenshot report (Aquatone HTML)
- [ ] Interesting targets identified
- [ ] Statistics (total vs live)
- [ ] Priority target list

### Quality Checklist:

- [ ] All files organized in directories
- [ ] Clear file naming (no mystery files)
- [ ] Summary reports created
- [ ] Statistics documented
- [ ] Key findings highlighted
- [ ] Professional presentation
- [ ] Can explain each finding

---

## 🎯 SUCCESS CRITERIA FOR 10/10

### Task 2: Infrastructure Profiling
✅ Identified multiple technology layers (web server, backend, framework)
✅ Mapped DNS infrastructure (nameservers, mail, CDN)
✅ Found WHOIS information
✅ Noted outdated software versions
✅ Clear documentation

### Task 3: GitHub Dorking
✅ Performed 5+ GitHub searches
✅ Documented findings (or confirmed none)
✅ Analyzed commit history
✅ Risk assessment provided
✅ Professional documentation

### Task 4: Live Asset Filtering
✅ Generated live hosts list
✅ Got detailed info (status codes, titles, tech)
✅ Captured screenshots
✅ Identified interesting targets
✅ Created visual report
✅ Organized findings

---

## 🚀 COMMANDS QUICK REFERENCE

### Fastest Execution (Automated):
```bash
./run_tasks_2_4.sh
```

### Copy-Paste Commands (Manual):
See: `QUICK_REFERENCE_2_3_4.md`

### Manual Web Search (Task 3):
Go to: `https://github.com/search`

### View Screenshots:
```bash
firefox ~/aquatone_results/aquatone_report.html
# OR
http://127.0.0.1:7171  (if using Gowitness)
```

---

## 🔧 TROUBLESHOOTING

### "merged_all_subdomains.txt not found"
→ Complete Task 1 first

### "whatweb: command not found"
→ Kali has it pre-installed. Try: `which whatweb`

### "Httprobe taking too long"
→ Normal for 1000+ subdomains. Can take 10-15 min

### "Aquatone needs Chrome"
→ Install: `sudo apt install chromium-browser -y`

### "GitHub search returned no results"
→ Try different search patterns from the guide

### "Screenshots look broken"
→ Make sure Chrome/Chromium is properly installed

---

## 📚 READING ORDER

1. **Read first:** `ACTION_PLAN.md` (this file) - 5 min
2. **Reference during execution:** `QUICK_REFERENCE_2_3_4.md` - copy-paste commands
3. **Deep dive:** `TASKS_2_3_4_COMPLETE_GUIDE.md` - detailed explanations
4. **Verify results:** Expected outputs in guide

---

## 🎓 LEARNING OUTCOMES

After completing Tasks 2-4, you understand:

✅ **Technology reconnaissance** - Identifying web tech stack
✅ **Infrastructure mapping** - Understanding hosting & DNS
✅ **Open source intelligence** - Finding secrets in public repos
✅ **Live host detection** - Filtering dead vs active targets
✅ **Visual reconnaissance** - Using screenshots for target analysis
✅ **Risk prioritization** - Focusing on high-value targets

---

## ✨ READY TO START?

### Choose your path:

**🔴 Fastest (Automated):**
```bash
./run_tasks_2_4.sh
```

**🟡 Recommended (Manual + Reference):**
1. Read this file
2. Use `QUICK_REFERENCE_2_3_4.md` for commands
3. Follow the step-by-step workflow

**🟢 Deep Learning:**
1. Read `TASKS_2_3_4_COMPLETE_GUIDE.md`
2. Execute manually, understanding each step
3. Document everything

---

**Start now! You've got all the resources.** 💪

Next: Week 1 Task 5 - Vulnerability Assessment (after completing Tasks 1-4)
