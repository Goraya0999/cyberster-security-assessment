# 🔍 HackThisSite.org — Red Team Recon | Week 1

<div align="center">

![Target](https://img.shields.io/badge/Target-hackthissite.org-red?style=for-the-badge&logo=target)
![Week](https://img.shields.io/badge/Week-1-blue?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen?style=for-the-badge)
![Tools](https://img.shields.io/badge/Tools-Subfinder%20%7C%20Httpx%20%7C%20Aquatone-orange?style=for-the-badge)

**Passive reconnaissance engagement on `hackthissite.org` (authorized training platform)**

</div>

---

## 👤 Intern Details

| Field | Details |
|-------|---------|
| **Name** | Muhammad Shafiq Goraya |
| **Organization** | CyberStr |
| **Role** | Red Team Intern |
| **Instructor** | Umar Niaz |
| **Date** | June 25, 2026 |
| **Target** | hackthissite.org (authorized) |

---

## 📋 Task Overview

| Task | Description | Status |
|------|-------------|--------|
| **T01** | Subdomain Enumeration (Subfinder, Assetfinder, Amass, CRT.sh, DNSDumpster) | ✅ Done |
| **T02** | Infrastructure & Tech Profiling (WhatWeb, Wappalyzer, WHOIS, DIG) | ✅ Done |
| **T03** | GitHub Dorking & Credential Leak Search | ✅ Done |
| **T04** | Live Asset Filtering + Visual Recon (httpx, httprobe, Aquatone) | ✅ Done |

---

## 🗂️ Repository Structure

```
hackthissite/
├── 📁 raw_output/                  # Raw tool outputs
│   ├── subfinder/subfinder.txt     # 63 subdomains
│   ├── assetfinder/assetfinder.txt # 29 subdomains
│   ├── amass/amass.txt             # Amass passive output
│   ├── crtsh/crt_raw.jso           # CRT.sh certificate data
│   └── dnsdumpster/                # DNS Dumpster (manual)
│
├── 📁 analysis/                    # Cross-referenced analysis
│   ├── merged.txt                  # All subdomains merged
│   ├── high_confidence.txt         # 4+ source matches
│   ├── medium_confidence.txt       # 2 source matches
│   ├── low_confidence.txt          # Single source
│   └── overlap.txt                 # Source count per domain
│
├── 📁 final_results/               # ✅ Cleaned final data
│   ├── attack_surface.txt          # 58 unique subdomains (categorized)
│   ├── live_hosts.txt              # 20 live hosts with tech stack
│   ├── tech_profile.txt            # Full infra + tech fingerprint
│   ├── dorking_results.txt         # Google/GitHub dork findings
│   ├── SUMMARY.txt                 # Executive summary
│   └── screenshots/                # 15 evidence screenshots
│
├── 📁 aquatone_results/            # Aquatone visual recon
│   ├── aquatone_report.html        # Full visual report
│   ├── aquatone_urls.txt           # Responsive URLs
│   ├── screenshots/                # 4 target screenshots
│   └── headers/                    # HTTP response headers
│
├── 📁 Assets/                      # Supporting assets
│   ├── lab_screenshots/            # 11 tool execution screenshots
│   └── Front-Page-of-report/       # Organization logo + info
│
├── dig_results.txt                 # DNS ANY record query
├── nslookup_results.txt            # NSLookup IP resolution
├── whois_results.txt               # Domain registration info
├── whatweb_results.txt             # WhatWeb full tech scan
├── httpx_results.txt               # httpx status + tech results
├── live_urls.txt                   # httprobe live URLs
├── Dns_dig_resolutation_path.txt   # DNS trace path
├── top_20_subs.txt                 # Top 20 high-confidence subs
├── urls.txt                        # URL list for Aquatone
├── report.pdf                      # 📄 Full submission report
└── week1-task.pdf                  # Original task brief
```

---

## 📊 Key Statistics

| Metric | Count |
|--------|-------|
| 🌐 Total Unique Subdomains Found | **58** |
| ✅ Live Hosts (2xx/3xx) | **20** |
| 🔴 Dead/Error Hosts | **~10** |
| 🔐 Login Panels Identified | **1** |
| 📂 Open Directories | **1** |
| 🧪 Dev/Staging Environments | **2** |
| 📸 Screenshots Captured | **15** |

---

## 🔬 Task 01 — Subdomain Enumeration

### Tools Used

```bash
# Subfinder — passive DNS intelligence
subfinder -d hackthissite.org -o raw_output/subfinder/subfinder.txt

# Assetfinder — certificate + threat intel APIs
assetfinder --subs-only hackthissite.org > raw_output/assetfinder/assetfinder.txt

# Amass — passive OSINT + ASN mapping
amass enum -passive -d hackthissite.org -o raw_output/amass/amass.txt

# CRT.sh — SSL certificate transparency logs
./crt_v2.sh -d hackthissite.org > raw_output/crtsh/crt_raw.jso

# Merge & deduplicate
cat subfinder.txt assetfinder.txt amass.txt | sort -u > merged.txt

# Overlap analysis (confidence scoring)
sort subfinder.txt assetfinder.txt amass.txt | uniq -c | sort -nr > overlap.txt
```

### Results Summary

| Source | Subdomains |
|--------|-----------|
| Subfinder | 63 |
| Assetfinder | 29 |
| Amass (passive) | 1 |
| CRT.sh | Wildcard + entries |
| **Merged Unique** | **58** |

---

## 🛠️ Task 02 — Infrastructure & Tech Profiling

### WHOIS Summary

| Field | Value |
|-------|-------|
| Registrar | Porkbun LLC |
| Created | 2003-08-10 |
| Expires | 2026-08-10 |
| Name Servers | BuddyNS (anycast) |
| DNSSEC | ❌ Not configured |

### DNS Records

```
A  Records: 137.74.187.100-104 (OVH load-balanced cluster)
MX Records: Google Workspace (aspmx.l.google.com)
TXT Records: SPF policy, verification tokens
CAA Records: letsencrypt.org, sectigo.com, harica.gr
```

### Technology Stack

| Layer | Technology |
|-------|-----------|
| Web Server | Custom HackThisSite + Nginx 1.18.0 |
| JavaScript | jQuery 1.8.1 ⚠️ (outdated 2012) |
| Analytics | Matomo/Piwik (self-hosted) |
| CDN | Fastly + Varnish |
| Hosting | OVH (FR) + GitHub Pages |
| Security | HSTS, CSP, PWA |
| Email | Google Workspace |

---

## 🔎 Task 03 — GitHub Dorking

Queries run: `"hackthissite" "API_KEY"`, `filename:.env "hackthissite"`, `filename:config "DB_PASSWORD"`

**Result: ✅ No credential leaks found**

---

## 📡 Task 04 — Live Asset Filtering & Visual Recon

```bash
# Filter live hosts
cat analysis/merged.txt | httprobe --prefer-https > live_urls.txt
cat analysis/merged.txt | httpx -status-code -title -tech-detect -o httpx_results.txt

# Visual screenshots
cat urls.txt | aquatone -out aquatone_results/
```

### Interesting Assets Found

| Subdomain | Status | Finding |
|-----------|--------|---------|
| `hp.hackthissite.org` | 200 | 🔐 **Login Panel** |
| `mirror.hackthissite.org` | 200 | 📂 **Open Directory (h5ai)** |
| `stats.hackthissite.org` | 200 | 📊 Piwik Analytics Panel |
| `forums.hackthissite.org` | 403 | 🚫 Forbidden (possible hidden) |
| `v3dev.hackthissite.org` | 400 | 🧪 Dev Environment |

---

## ⚠️ Key Findings

| Severity | Finding |
|----------|---------|
| 🟡 Medium | jQuery 1.8.1 in use (EOL, multiple CVEs) |
| 🟡 Medium | Open directory listing on `mirror.hackthissite.org` |
| 🟡 Medium | Analytics panel exposed at `stats.hackthissite.org` |
| 🟡 Medium | `forums.hackthissite.org` returns 403 (suspicious) |
| 🔵 Low | DNSSEC not configured — DNS spoofing risk |
| 🔵 Low | `robots.txt` reveals `/missions/` directory |
| 🔵 Low | 5x firewall egress VM IPs leaked via DNS |
| 🔵 Low | Dev/staging subdomains (v3dev, v3stage) |
| ℹ️ Info | No GitHub credential leaks found |
| ℹ️ Info | No backup files accessible |

---

## 📄 Report

> 📎 See [`report.pdf`](./report.pdf) for the full formatted submission report with screenshots.

---

## ⚖️ Legal & Ethics Disclaimer

> This reconnaissance was performed **exclusively** on `hackthissite.org`, an authorized training platform designed for ethical hacking practice. All activities were **passive** and **non-exploitative**. No unauthorized access was attempted. This work is submitted as part of the CyberStr Red Team Internship training program.

---

<div align="center">
Made with 🔐 by Muhammad Shafiq Goraya | CyberStr Red Team Internship
</div>
