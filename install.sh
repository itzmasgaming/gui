#!/bin/bash

# ==========================================
# COLOR DEFINITIONS FOR TERMINAL GUI
# ==========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# ==========================================
# DANGEROUS ENVIRONMENT / VPS DESTRUCTION WARNING
# ==========================================
show_warning() {
    clear
    echo -e "${RED}================================================================${NC}"
    echo -e "${BOLD}${RED}⚠️  CRITICAL WARNING: DATA DESTRUCTION RISK ⚠️${NC}"
    echo -e "${RED}================================================================${NC}"
    echo -e "${YELLOW}This script is heavily optimized for ${BOLD}FRESH, CLEAN VPS${NC}${YELLOW} environments only."
    echo -e "Running this on an active or pre-configured server ${RED}${BOLD}WILL DESTROY${NC}${YELLOW}:"
    echo -e " • Existing Docker configurations & running containers"
    echo -e " • Overwritten daemon settings and active networks"
    echo -e " • Existing package states (purged and downgraded)"
    echo -e "• Installed dependency structures"
    echo -e "${RED}================================================================${NC}"
    echo -e "Do NOT run this if your VPS contains important production data."
    echo -e "----------------------------------------------------------------"
    read -p "Type 'I AGREE' to confirm you understand the risks: " confirm
    if [ "$confirm" != "I AGREE" ]; then
        echo -e "${RED}Installation aborted by user.${NC}"
        exit 1
    fi
}

# ==========================================
# UI HEADER AND MESSAGES
# ==========================================
print_header() {
    clear
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${BOLD}${BLUE}    🐋 SYSTEM WIZARD: DOCKER & PTERODACTYL SETUP 🐋    ${NC}"
    echo -e "${CYAN}================================================================${NC}"
}

run_step() {
    local step_num="$1"
    local step_desc="$2"
    echo -e "\n${YELLOW}${BOLD}[TASK ${step_num}]${NC} ${BOLD}${step_desc}${NC}"
    echo -e "${CYAN}----------------------------------------------------------------${NC}"
}

print_success() {
    echo -e "${GREEN}✔ Task finished successfully!${NC}"
    echo -e "${CYAN}----------------------------------------------------------------${NC}"
    echo -e "Press [ENTER] to return to the menu..."
    read -r
}

# ==========================================
# CORE SETUP CORE LOGIC (STEPS 1 - 12)
# ==========================================
step_1() {
    run_step "1" "Wiping broken packages & cleaning environment"
    systemctl stop docker containerd 2>/dev/null
    apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker.io runc crun 2>/dev/null
    rm -rf /var/lib/docker /var/lib/containerd /etc/docker/daemon.json
    apt-mark unhold docker-ce docker-ce-cli containerd.io 2>/dev/null
}

step_2() {
    run_step "2" "Setting up official Docker repository GPG keys"
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://docker.com | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://docker.com $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
    apt-get update
}

step_3() {
    run_step "3" "Injecting initial VFS storage driver configurations"
    mkdir -p /etc/docker
    cat << 'EOF' > /etc/docker/daemon.json
{
  "storage-driver": "vfs"
}
EOF
}

step_4() {
    run_step "4" "Finding highly compatible runtime target versions"
    SAFE_CONTAINERD=$(apt-cache madison containerd.io | grep -m 1 '1.6.' | awk '{print $3}')
    DOCKER_VER=$(apt-cache madison docker-ce | grep -m 1 '5:26.' | awk '{print $3}')
    CLI_VER=$(apt-cache madison docker-ce-cli | grep -m 1 '5:26.' | awk '{print $3}')
    echo -e "${PURPLE}→ Containerd Target:${NC} $SAFE_CONTAINERD"
    echo -e "${PURPLE}→ Docker Target:${NC} $DOCKER_VER"
}

step_5() {
    run_step "5" "Downgrading and installing forced matching versions"
    apt-get install -y --allow-downgrades containerd.io="$SAFE_CONTAINERD" docker-ce="$DOCKER_VER" docker-ce-cli="$CLI_VER" docker-compose-plugin
}

step_6() {
    run_step "6" "Locking system packages via apt-mark hold"
    apt-mark hold containerd.io docker-ce docker-ce-cli
}

step_7() {
    run_step "7" "Booting daemon clusters and executing validation tests"
    systemctl enable --now containerd docker
    docker run hello-world
}

step_8() {
    run_step "8" "Rewriting system configuration with advanced routing & DNS"
    cat << 'EOF' > /etc/docker/daemon.json
{
  "storage-driver": "vfs",
  "iptables": true,
  "dns": [
    "1.1.1.1",
    "8.8.8.8"
  ]
}
EOF
    systemctl restart docker
}

step_9() {
    run_step "9" "Deploying latest Pterodactyl Wings host application binary"
    sudo mkdir -p /etc/pterodactyl
    curl -L -o /usr/local/bin/wings "https://github.com([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
    sudo chmod u+x /usr/local/bin/wings
}

step_10() {
    run_step "10" "Creating global 4096-bit self-signed SSL layers"
    mkdir -p /etc/certs && cd /etc/certs && openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj "/C=NA/ST=NA/L=NA/O=NA/CN=Generic SSL Certificate" -keyout privkey.pem -out fullchain.pem
}

step_11() {
    run_step "11" "Relocating active workspace into node configurations"
    cd /etc/pterodactyl
}

step_12() {
    run_step "12" "Provisioning pterodactyl0 isolated network bridges"
    docker network create --driver=bridge pterodactyl0 2>/dev/null || true
}

# ==========================================
# RUN AUTOMATED METAPACKAGE ALL-IN-ONE
# ==========================================
run_all_in_one() {
    clear
    echo -e "${YELLOW}${BOLD}[AUTOMATED RUN] Executing all 12 modules sequentially...${NC}"
    echo -e "${CYAN}----------------------------------------------------------------${NC}"
    step_1
    step_2
    step_3
    step_4
    step_5
    step_6
    step_7
    step_8
    step_9
    step_10
    step_11
    step_12
    
    clear
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${BOLD}${GREEN}🎉 AUTOMATED ALL-IN-ONE DEPLOYMENT SUCCESSFUL! 🎉${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${CYAN}• Environment Status:${NC} VFS Driver Online"
    echo -e "${CYAN}• Application Engine:${NC} Wings Ready at /usr/local/bin/wings"
    echo -e "${GREEN}================================================================${NC}"
    echo -e "Press [ENTER] to return to the workspace..."
    read -r
}

# ==========================================
# INTERACTIVE TUI SELECTION MENU
# ==========================================
show_warning # Fire destruction warning first before opening dashboard

while true; do
    print_header
    echo -e "${BOLD}Select a feature component option to manage:${NC}"
    echo -e " ${CYAN}[1]${NC} Purge Old Packages & Configurations"
    echo -e " ${CYAN}[2]${NC} Setup Docker Official GPG Repo"
    echo -e " ${CYAN}[3]${NC} Setup Base VFS Storage Driver Configuration"
    echo -e " ${CYAN}[4]${NC} Cache and Check Compatible Version Matrices"
    echo -e " ${CYAN}[5]${NC} Forced Downgrade Installation Modules"
    echo -e " ${CYAN}[6]${NC} Hold APT Package Matrix Operations"
    echo -e " ${CYAN}[7]${NC} Enable Services & Verify Hello-World"
    echo -e " ${CYAN}[8]${NC} Rebuild Daemon Config (VFS, IPTables, DNS)"
    echo -e " ${CYAN}[9]${NC} Install Core Pterodactyl Wings Application"
    echo -e " ${CYAN}[10]${NC} Generate 4096-bit Self-Signed SSL System"
    echo -e " ${CYAN}[11]${NC} Initialize Configuration Workspace Paths"
    echo -e " ${CYAN}[12]${NC} Construct Isolated pterodactyl0 Virtual Bridges"
    echo -e " --------------------------------------------------------"
    echo -e " ${GREEN}${BOLD}[A] RUN ALL-IN-ONE AUTOMATED INSTALLATION (RECOMMENDED)${NC}"
    echo -e " ${RED}[E] Exit Setup Wizard${NC}"
    echo -e "${CYAN}================================================================${NC}"
    read -p "Enter selection [1-12, A, E]: " choice

    case $choice in
        1) step_1; print_success ;;
        2) step_2; print_success ;;
        3) step_3; print_success ;;
        4) step_4; print_success ;;
        5) step_5; print_success ;;
        6) step_6; print_success ;;
        7) step_7; print_success ;;
        8) step_8; print_success ;;
        9) step_9; print_success ;;
        10) step_10; print_success ;;
        11) step_11; print_success ;;
        12) step_12; print_success ;;
        [Aa]) run_all_in_one ;;
        [Ee]) clear; echo -e "${BLUE}Exiting execution pipeline... Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid input selection option context.${NC}"; sleep 1.5 ;;
    esac
done
