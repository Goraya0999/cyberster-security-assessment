#!/bin/bash

################################################################################
# WEEK 1 - TASKS 2 & 4: Infrastructure Profiling + Live Asset Filtering
# Task 3 (GitHub Dorking) requires manual searching at github.com/search
# 
# This script automates:
# Task 2: Tech profiling, WHOIS, DNS queries, Google Dorking suggestions
# Task 4: Live host detection, detailed profiling, screenshots
################################################################################

set -e

# ===== CONFIGURATION =====
TARGET="hackthissite.org"
MERGED_SUBDOMAINS="analysis/merged_all_subdomains.txt"  # From Task 1
WORKDIR="${PWD}/task_2_4_results_$(date +%Y%m%d_%H%M%S)"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ===== HELPER FUNCTIONS =====

print_header() {
    echo -e "${BLUE}[*] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

print_error() {
    echo -e "${RED}[!] $1${NC}"
}

print_info() {
    echo -e "${YELLOW}[+] $1${NC}"
}

count_lines() {
    if [ -f "$1" ]; then
        wc -l < "$1"
    else
        echo "0"
    fi
}

# ===== PRE-FLIGHT CHECKS =====

check_prerequisites() {
    print_header "Checking prerequisites..."
    
    # Check if Task 1 output exists
    if [ ! -f "$MERGED_SUBDOMAINS" ]; then
        print_error "Cannot find: $MERGED_SUBDOMAINS"
        print_error "Please complete Task 1 first!"
        exit 1
    fi
    
    print_success "Task 1 output found"
    
    # Check for required tools
    local missing_tools=()
    
    # Check WhatWeb
    if ! command -v whatweb &> /dev/null; then
        print_info "WhatWeb not found (optional, Kali has it built-in)"
    else
        print_success "WhatWeb found"
    fi
    
    # Check Wappalyzer
    if ! command -v wappalyzer &> /dev/null; then
        print_info "Wappalyzer not found (will install via npm)"
    else
        print_success "Wappalyzer found"
    fi
    
    # Check WHOIS
    if ! command -v whois &> /dev/null; then
        missing_tools+=("whois")
    else
        print_success "WHOIS found"
    fi
    
    # Check dig/nslookup
    if ! command -v dig &> /dev/null; then
        missing_tools+=("dnsutils")
    else
        print_success "dig found"
    fi
    
    # Check httprobe
    if ! command -v httprobe &> /dev/null; then
        print_info "Httprobe not found (installing via Go)"
    else
        print_success "Httprobe found"
    fi
    
    # Check httpx
    if ! command -v httpx &> /dev/null; then
        print_info "Httpx not found (installing via Go)"
    else
        print_success "Httpx found"
    fi
    
    # Install missing tools
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_header "Installing missing dependencies..."
        sudo apt update
        for tool in "${missing_tools[@]}"; do
            print_info "Installing $tool..."
            sudo apt install "$tool" -y
        done
    fi
}

install_optional_tools() {
    print_header "Setting up optional tools..."
    
    # Install Httprobe
    if ! command -v httprobe &> /dev/null; then
        print_info "Installing Httprobe..."
        go install github.com/tomnomnom/httprobe@latest
        export PATH=$PATH:$(go env GOPATH)/bin
    fi
    
    # Install Httpx
    if ! command -v httpx &> /dev/null; then
        print_info "Installing Httpx..."
        go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
        export PATH=$PATH:$(go env GOPATH)/bin
    fi
    
    # Install Aquatone
    if ! command -v aquatone &> /dev/null; then
        print_info "Aquatone not found. Installing..."
        cd /tmp
        wget -q https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_amd64_1.7.0.zip
        unzip -q aquatone_linux_amd64_1.7.0.zip
        sudo mv aquatone /usr/local/bin/
        print_success "Aquatone installed"
        cd - > /dev/null
    fi
    
    print_success "Optional tools ready"
}

# ===== SETUP =====

setup_directories() {
    print_header "Setting up working directories..."
    
    mkdir -p "${WORKDIR}"/{task_2/{whatweb,wappalyzer,whois,dns,dorks},task_4/{live,httpx,screenshots},reports}
    
    print_success "Working directory: ${WORKDIR}"
}

# ===== TASK 2: INFRASTRUCTURE PROFILING =====

task_2_whatweb() {
    print_header "TASK 2A: WhatWeb - Technology Detection"
    
    local top_subs=$(head -20 "$MERGED_SUBDOMAINS")
    local count=0
    
    for sub in $top_subs; do
        local url="https://$sub"
        print_info "Testing: $url"
        
        if whatweb "$url" >> "${WORKDIR}/task_2/whatweb/results.txt" 2>/dev/null; then
            ((count++))
            echo "" >> "${WORKDIR}/task_2/whatweb/results.txt"
        fi
    done
    
    print_success "WhatWeb scan complete: $count hosts"
}

task_2_wappalyzer() {
    print_header "TASK 2B: Wappalyzer - Technology Stack Detection"
    
    # Install if needed
    if ! command -v wappalyzer &> /dev/null; then
        print_info "Installing Wappalyzer via npm..."
        sudo npm install -g wappalyzer > /dev/null 2>&1
    fi
    
    local top_subs=$(head -20 "$MERGED_SUBDOMAINS")
    local count=0
    
    for sub in $top_subs; do
        local url="https://$sub"
        print_info "Profiling: $url"
        
        if wappalyzer "$url" >> "${WORKDIR}/task_2/wappalyzer/results.txt" 2>/dev/null; then
            ((count++))
        fi
    done
    
    print_success "Wappalyzer scan complete: $count hosts"
}

task_2_whois() {
    print_header "TASK 2C: WHOIS - Domain Ownership"
    
    print_info "Querying WHOIS for: $TARGET"
    
    whois "$TARGET" > "${WORKDIR}/task_2/whois/whois.txt"
    
    # Extract key info
    echo "=== EXTRACTED INFORMATION ===" > "${WORKDIR}/task_2/whois/extracted.txt"
    echo "Registrar: $(grep -i 'registrar:' whois.txt | head -1 || echo 'N/A')" >> "${WORKDIR}/task_2/whois/extracted.txt"
    echo "Organization: $(grep -i 'organization:' whois.txt | head -1 || echo 'N/A')" >> "${WORKDIR}/task_2/whois/extracted.txt"
    echo "Name Servers:" >> "${WORKDIR}/task_2/whois/extracted.txt"
    grep -i 'name server:' whois.txt >> "${WORKDIR}/task_2/whois/extracted.txt" 2>/dev/null || echo "N/A" >> "${WORKDIR}/task_2/whois/extracted.txt"
    
    print_success "WHOIS lookup complete"
}

task_2_dns() {
    print_header "TASK 2D: DNS Queries - Network Infrastructure"
    
    print_info "Querying A records..."
    dig "$TARGET" A > "${WORKDIR}/task_2/dns/a_records.txt"
    
    print_info "Querying MX records (mail)..."
    dig "$TARGET" MX > "${WORKDIR}/task_2/dns/mx_records.txt"
    
    print_info "Querying NS records (nameservers)..."
    dig "$TARGET" NS > "${WORKDIR}/task_2/dns/ns_records.txt"
    
    print_info "Querying TXT records (SPF/DKIM)..."
    dig "$TARGET" TXT > "${WORKDIR}/task_2/dns/txt_records.txt"
    
    print_info "Full DNS trace..."
    dig +trace "$TARGET" > "${WORKDIR}/task_2/dns/trace.txt"
    
    print_success "DNS queries complete"
}

task_2_summary() {
    print_header "Creating Task 2 Summary Report"
    
    cat > "${WORKDIR}/reports/task_2_report.txt" << 'EOF'
=== TASK 2: INFRASTRUCTURE & TECH PROFILING REPORT ===

TECHNOLOGIES DETECTED:
(See task_2/whatweb/ and task_2/wappalyzer/ for details)

WEB SERVERS & FRAMEWORKS:
(Apache, Nginx, PHP, Node.js, etc.)

DNS INFRASTRUCTURE:
(See task_2/dns/ for A, MX, NS, TXT records)

REGISTRAR & OWNERSHIP:
(See task_2/whois/ for full details)

KEY FINDINGS:
- Check for outdated software versions
- Note any known vulnerable frameworks
- Identify email infrastructure
- Document CDN usage

NEXT STEPS:
1. Review DNS records for subdomains
2. Check for exposed .env files (Google Dorking)
3. Look for phpinfo() pages
4. Find robots.txt and backup files
EOF
    
    print_success "Task 2 summary created"
}

# ===== TASK 4: LIVE ASSET FILTERING =====

task_4_httprobe() {
    print_header "TASK 4A: Httprobe - Find Live Hosts"
    
    if [ ! -f "$MERGED_SUBDOMAINS" ]; then
        print_error "Missing merged subdomains from Task 1"
        return 1
    fi
    
    print_info "Testing subdomains for HTTP/HTTPS responses..."
    print_info "This may take 5-10 minutes depending on target size..."
    
    cat "$MERGED_SUBDOMAINS" | httprobe --prefer-https -c 50 \
        > "${WORKDIR}/task_4/live/live_urls.txt" 2>/dev/null
    
    local count=$(count_lines "${WORKDIR}/task_4/live/live_urls.txt")
    local total=$(count_lines "$MERGED_SUBDOMAINS")
    local percentage=$(echo "scale=1; $count * 100 / $total" | bc)
    
    print_success "Httprobe complete: $count live hosts out of $total ($percentage%)"
}

task_4_httpx() {
    print_header "TASK 4B: Httpx - Detailed Host Information"
    
    local live_file="${WORKDIR}/task_4/live/live_urls.txt"
    
    if [ ! -f "$live_file" ]; then
        print_error "Live URLs file not found"
        return 1
    fi
    
    print_info "Probing live hosts for status codes, titles, and technologies..."
    
    cat "$live_file" | httpx \
        -status-code \
        -title \
        -tech-detect \
        -o "${WORKDIR}/task_4/httpx/detailed_results.txt" \
        2>/dev/null
    
    print_success "Httpx scan complete"
    
    # Create summary
    print_info "Creating summaries..."
    
    echo "=== INTERESTING FINDINGS ===" > "${WORKDIR}/task_4/httpx/summary.txt"
    echo "" >> "${WORKDIR}/task_4/httpx/summary.txt"
    
    echo "Admin/Staging/Dev URLs:" >> "${WORKDIR}/task_4/httpx/summary.txt"
    grep -iE "admin|staging|dev|test" "${WORKDIR}/task_4/httpx/detailed_results.txt" >> "${WORKDIR}/task_4/httpx/summary.txt" 2>/dev/null || echo "None found" >> "${WORKDIR}/task_4/httpx/summary.txt"
    
    echo "" >> "${WORKDIR}/task_4/httpx/summary.txt"
    echo "Forbidden/Access Denied (403):" >> "${WORKDIR}/task_4/httpx/summary.txt"
    grep "\[403\]" "${WORKDIR}/task_4/httpx/detailed_results.txt" >> "${WORKDIR}/task_4/httpx/summary.txt" 2>/dev/null || echo "None found" >> "${WORKDIR}/task_4/httpx/summary.txt"
}

task_4_aquatone() {
    print_header "TASK 4C: Aquatone - Take Screenshots"
    
    local live_file="${WORKDIR}/task_4/live/live_urls.txt"
    
    if [ ! -f "$live_file" ]; then
        print_error "Live URLs file not found"
        return 1
    fi
    
    # Check if Aquatone is installed
    if ! command -v aquatone &> /dev/null; then
        print_info "Aquatone not found, installing..."
        install_optional_tools
    fi
    
    print_info "Taking screenshots of all live hosts..."
    print_info "This will take 20-40 minutes for 200-400 hosts..."
    
    local count=$(wc -l < "$live_file")
    print_info "Total hosts to screenshot: $count"
    
    cat "$live_file" | aquatone \
        -out "${WORKDIR}/task_4/screenshots" \
        -threads 8 \
        -timeout 30 \
        2>/dev/null
    
    print_success "Screenshots captured"
    print_info "View results at: file://${WORKDIR}/task_4/screenshots/aquatone_report.html"
}

task_4_summary() {
    print_header "Creating Task 4 Summary Report"
    
    local live_count=$(count_lines "${WORKDIR}/task_4/live/live_urls.txt" 2>/dev/null || echo 0)
    local total_count=$(count_lines "$MERGED_SUBDOMAINS" 2>/dev/null || echo 0)
    local percentage=$((live_count * 100 / total_count))
    
    cat > "${WORKDIR}/reports/task_4_report.txt" << EOF
=== TASK 4: LIVE ASSET FILTERING & VISUAL RECON REPORT ===

STATISTICS:
Total subdomains enumerated (Task 1): $total_count
Live/Responding hosts: $live_count
Response rate: $percentage%

INTERESTING TARGETS:
(See task_4/httpx/summary.txt for:)
- Admin panels
- Staging environments
- Forbidden responses (403)
- Development environments

SCREENSHOTS CAPTURED:
View: file://${WORKDIR}/task_4/screenshots/aquatone_report.html

KEY OBSERVATIONS:
1. Check staging environments - often less secure
2. Note any outdated software versions
3. Identify interesting login panels
4. Look for exposed admin panels

PRIORITY TARGETS:
1. Staging environments
2. Admin panels
3. APIs
4. Outdated software versions

NEXT STEPS (Week 1 Task 5):
- Vulnerability scanning on priority targets
- Exploit outdated software
- Test API endpoints
- Check for common vulnerabilities (SQL injection, XSS, etc.)
EOF
    
    print_success "Task 4 summary created"
}

# ===== MAIN EXECUTION =====

main() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              WEEK 1 - TASKS 2 & 4 AUTOMATED EXECUTION         ║${NC}"
    echo -e "${BLUE}║                                                                ║${NC}"
    echo -e "${BLUE}║   Task 2: Infrastructure & Tech Profiling                     ║${NC}"
    echo -e "${BLUE}║   Task 3: GitHub Dorking (MANUAL - See guide)                 ║${NC}"
    echo -e "${BLUE}║   Task 4: Live Asset Filtering & Visual Recon                 ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Pre-flight checks
    check_prerequisites
    echo ""
    
    # Setup
    setup_directories
    echo ""
    
    # Task 2
    print_info "Starting TASK 2: Infrastructure & Tech Profiling..."
    echo ""
    
    task_2_whatweb
    echo ""
    
    task_2_wappalyzer
    echo ""
    
    task_2_whois
    echo ""
    
    task_2_dns
    echo ""
    
    task_2_summary
    echo ""
    
    # Task 3 Note
    print_header "TASK 3: GitHub Dorking & Credential Leaks (MANUAL)"
    echo -e "${YELLOW}This task requires manual searching at https://github.com/search${NC}"
    echo -e "${YELLOW}See the guide for search patterns and instructions.${NC}"
    echo ""
    
    # Task 4
    print_info "Starting TASK 4: Live Asset Filtering & Visual Recon..."
    echo ""
    
    install_optional_tools
    echo ""
    
    task_4_httprobe
    echo ""
    
    task_4_httpx
    echo ""
    
    # Ask before taking screenshots (time-consuming)
    echo ""
    read -p "Take screenshots with Aquatone? (y/n - takes 20-40 min): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        task_4_aquatone
    else
        print_info "Skipping Aquatone screenshots"
    fi
    echo ""
    
    task_4_summary
    echo ""
    
    # Final Summary
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    EXECUTION COMPLETE                         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Results saved in: ${WORKDIR}${NC}"
    echo ""
    echo "Directory structure:"
    echo "  task_2/whatweb/      → Technology detection results"
    echo "  task_2/wappalyzer/   → Technology stack details"
    echo "  task_2/whois/        → Domain ownership info"
    echo "  task_2/dns/          → DNS records and infrastructure"
    echo "  task_4/live/         → Live hosts list"
    echo "  task_4/httpx/        → Detailed host information"
    echo "  task_4/screenshots/  → Website screenshots (if captured)"
    echo "  reports/             → Summary reports"
    echo ""
    echo -e "${YELLOW}Important:${NC}"
    echo "1. Review task_2/ results for tech stack and infrastructure"
    echo "2. Perform GitHub Dorking manually (see guide)"
    echo "3. Review task_4/httpx/summary.txt for interesting targets"
    echo "4. View screenshots: file://${WORKDIR}/task_4/screenshots/aquatone_report.html"
    echo ""
    echo -e "${GREEN}Next: Complete TASK 5 - Vulnerability Assessment${NC}"
    echo ""
}

# Error handling
trap 'print_error "Script interrupted"; exit 1' INT TERM

# Run
main "$@"
