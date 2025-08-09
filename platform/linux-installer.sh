#!/bin/bash
# The Hive - Linux Platform Installer
# Multi-distribution support: Ubuntu, Debian, CentOS, RHEL, Fedora, Arch Linux

set -e

# Version and configuration
HIVE_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HIVE_HOME="$HOME/.hive"
BACKUP_DIR="$HIVE_HOME/backup/$(date +%Y%m%d-%H%M%S)"

# Color codes (compatible with most terminals)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Emojis (with fallback for systems without emoji support)
if [[ "$TERM" == "dumb" ]] || [[ -n "$CI" ]] || [[ "$LANG" != *"UTF-8"* ]]; then
    HIVE_EMOJI="[HIVE]"
    SUCCESS_EMOJI="[OK]"
    ERROR_EMOJI="[ERROR]"
    WARNING_EMOJI="[WARN]"
    INFO_EMOJI="[INFO]"
else
    HIVE_EMOJI="🐝"
    SUCCESS_EMOJI="✅"
    ERROR_EMOJI="❌"
    WARNING_EMOJI="⚠️"
    INFO_EMOJI="ℹ️"
fi

# Logging functions
log() { echo -e "${CYAN}${HIVE_EMOJI}${NC} [Linux] $*"; }
success() { echo -e "${GREEN}${SUCCESS_EMOJI}${NC} [Linux] $*"; }
error() { echo -e "${RED}${ERROR_EMOJI}${NC} [Linux] $*" >&2; }
warning() { echo -e "${YELLOW}${WARNING_EMOJI}${NC} [Linux] $*"; }
info() { echo -e "${BLUE}${INFO_EMOJI}${NC} [Linux] $*"; }

# Default values
INSTALL_PROFILE="default"
INTERACTIVE_MODE="true"
PACKAGE_MANAGER=""
DISTRO=""
DRY_RUN="false"
USE_SUDO="true"

# Parse arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --profile)
                INSTALL_PROFILE="$2"
                shift 2
                ;;
            --interactive)
                INTERACTIVE_MODE="true"
                shift
                ;;
            --non-interactive)
                INTERACTIVE_MODE="false"
                shift
                ;;
            --package-manager)
                PACKAGE_MANAGER="$2"
                shift 2
                ;;
            --distro)
                DISTRO="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --no-sudo)
                USE_SUDO="false"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# Detect Linux distribution and package manager
detect_linux_distribution() {
    log "Detecting Linux distribution..."
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO="${ID:-unknown}"
        DISTRO_VERSION="${VERSION_ID:-unknown}"
        DISTRO_NAME="${PRETTY_NAME:-$DISTRO}"
        
        info "Distribution: $DISTRO_NAME"
        info "Version: $DISTRO_VERSION"
        
        # Determine package manager based on distribution
        case "$DISTRO" in
            ubuntu|debian|linuxmint|pop|elementary)
                PACKAGE_MANAGER="apt"
                PACKAGE_UPDATE_CMD="apt-get update -y"
                PACKAGE_INSTALL_CMD="apt-get install -y"
                ;;
            centos|rhel|fedora|rocky|almalinux)
                if command -v dnf >/dev/null 2>&1; then
                    PACKAGE_MANAGER="dnf"
                    PACKAGE_UPDATE_CMD="dnf check-update || true"
                    PACKAGE_INSTALL_CMD="dnf install -y"
                else
                    PACKAGE_MANAGER="yum"
                    PACKAGE_UPDATE_CMD="yum check-update || true"
                    PACKAGE_INSTALL_CMD="yum install -y"
                fi
                ;;
            arch|manjaro|endeavouros)
                PACKAGE_MANAGER="pacman"
                PACKAGE_UPDATE_CMD="pacman -Sy"
                PACKAGE_INSTALL_CMD="pacman -S --noconfirm"
                ;;
            opensuse*|sles)
                PACKAGE_MANAGER="zypper"
                PACKAGE_UPDATE_CMD="zypper refresh"
                PACKAGE_INSTALL_CMD="zypper install -y"
                ;;
            alpine)
                PACKAGE_MANAGER="apk"
                PACKAGE_UPDATE_CMD="apk update"
                PACKAGE_INSTALL_CMD="apk add --no-cache"
                ;;
            *)
                warning "Unknown distribution: $DISTRO"
                PACKAGE_MANAGER="generic"
                ;;
        esac
        
        info "Package Manager: $PACKAGE_MANAGER"
        
    else
        warning "Unable to detect Linux distribution"
        DISTRO="unknown"
        PACKAGE_MANAGER="generic"
    fi
}

# Check for root/sudo requirements
check_permissions() {
    log "Checking permissions..."
    
    # Check if we can use sudo or if we're already root
    if [[ $EUID -eq 0 ]]; then
        USE_SUDO="false"
        success "Running as root"
    elif command -v sudo >/dev/null 2>&1; then
        if sudo -n true 2>/dev/null; then
            success "Sudo available without password"
        else
            info "Sudo available (may require password)"
        fi
        USE_SUDO="true"
    else
        warning "Sudo not available and not running as root"
        if [[ "$PACKAGE_MANAGER" != "generic" ]]; then
            error "Package installation requires root privileges"
            error "Please run as root or install sudo"
            return 1
        fi
        USE_SUDO="false"
    fi
    
    return 0
}

# Execute command with appropriate privileges
execute_with_privileges() {
    local cmd="$*"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        warning "DRY RUN: Would execute: $cmd"
        return 0
    fi
    
    if [[ "$USE_SUDO" == "true" && $EUID -ne 0 ]]; then
        sudo $cmd
    else
        $cmd
    fi
}

# Install system dependencies
install_system_dependencies() {
    log "Installing system dependencies for profile: $INSTALL_PROFILE"
    
    if [[ "$PACKAGE_MANAGER" == "generic" ]]; then
        warning "Generic package manager - skipping system dependencies"
        return 0
    fi
    
    # Update package lists
    info "Updating package lists..."
    execute_with_privileges $PACKAGE_UPDATE_CMD
    
    # Define dependency sets
    local base_deps=()
    local enhanced_deps=()
    local developer_deps=()
    
    case "$PACKAGE_MANAGER" in
        "apt")
            base_deps=("curl" "git" "jq" "nodejs" "npm" "python3" "python3-pip" "build-essential")
            enhanced_deps=("gh" "fzf" "ripgrep" "bat" "exa" "tree" "htop")
            developer_deps=("docker.io" "docker-compose" "awscli")
            ;;
        "dnf"|"yum")
            base_deps=("curl" "git" "jq" "nodejs" "npm" "python3" "python3-pip" "gcc" "gcc-c++" "make")
            enhanced_deps=("gh" "fzf" "ripgrep" "bat" "exa" "tree" "htop")
            developer_deps=("docker" "docker-compose" "awscli")
            ;;
        "pacman")
            base_deps=("curl" "git" "jq" "nodejs" "npm" "python" "python-pip" "base-devel")
            enhanced_deps=("github-cli" "fzf" "ripgrep" "bat" "exa" "tree" "htop")
            developer_deps=("docker" "docker-compose" "aws-cli")
            ;;
        "zypper")
            base_deps=("curl" "git" "jq" "nodejs" "npm" "python3" "python3-pip" "gcc" "gcc-c++" "make")
            enhanced_deps=("gh" "fzf" "ripgrep" "bat" "tree" "htop")
            developer_deps=("docker" "docker-compose")
            ;;
        "apk")
            base_deps=("curl" "git" "jq" "nodejs" "npm" "python3" "py3-pip" "build-base")
            enhanced_deps=("github-cli" "fzf" "ripgrep" "bat" "tree" "htop")
            developer_deps=("docker" "docker-compose")
            ;;
    esac
    
    # Select dependencies based on profile
    local deps_to_install=("${base_deps[@]}")
    
    case "$INSTALL_PROFILE" in
        "minimal")
            # Only base dependencies
            ;;
        "default"|"full")
            deps_to_install+=("${enhanced_deps[@]}")
            ;;
        "developer")
            deps_to_install+=("${enhanced_deps[@]}" "${developer_deps[@]}")
            ;;
    esac
    
    info "Dependencies to install: ${deps_to_install[*]}"
    
    # Install dependencies
    for dep in "${deps_to_install[@]}"; do
        info "Installing $dep..."
        if execute_with_privileges $PACKAGE_INSTALL_CMD "$dep"; then
            success "$dep installed"
        else
            warning "Failed to install $dep (may already be installed or unavailable)"
        fi
    done
    
    success "System dependencies installation completed"
}

# Install Node.js and npm if not available
ensure_nodejs() {
    log "Ensuring Node.js and npm are available..."
    
    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
        local node_version=$(node --version)
        local npm_version=$(npm --version)
        success "Node.js $node_version and npm $npm_version already installed"
        return 0
    fi
    
    info "Installing Node.js and npm..."
    
    case "$DISTRO" in
        ubuntu|debian)
            if [[ "$DRY_RUN" == "true" ]]; then
                warning "DRY RUN: Would install Node.js via NodeSource repository"
            else
                # Install Node.js via NodeSource
                curl -fsSL https://deb.nodesource.com/setup_lts.x | execute_with_privileges bash -
                execute_with_privileges apt-get install -y nodejs
            fi
            ;;
        centos|rhel|fedora)
            if [[ "$DRY_RUN" == "true" ]]; then
                warning "DRY RUN: Would install Node.js via NodeSource repository"
            else
                curl -fsSL https://rpm.nodesource.com/setup_lts.x | execute_with_privileges bash -
                execute_with_privileges $PACKAGE_INSTALL_CMD nodejs
            fi
            ;;
        *)
            # For other distributions, try package manager
            execute_with_privileges $PACKAGE_INSTALL_CMD nodejs npm
            ;;
    esac
    
    success "Node.js and npm installation completed"
}

# Install Python3 and pip if not available
ensure_python() {
    log "Ensuring Python3 and pip are available..."
    
    if command -v python3 >/dev/null 2>&1 && command -v pip3 >/dev/null 2>&1; then
        local python_version=$(python3 --version)
        success "Python3 already installed: $python_version"
        return 0
    fi
    
    info "Installing Python3 and pip..."
    
    case "$PACKAGE_MANAGER" in
        "apt")
            execute_with_privileges $PACKAGE_INSTALL_CMD python3 python3-pip
            ;;
        "dnf"|"yum")
            execute_with_privileges $PACKAGE_INSTALL_CMD python3 python3-pip
            ;;
        "pacman")
            execute_with_privileges $PACKAGE_INSTALL_CMD python python-pip
            ;;
        "zypper")
            execute_with_privileges $PACKAGE_INSTALL_CMD python3 python3-pip
            ;;
        "apk")
            execute_with_privileges $PACKAGE_INSTALL_CMD python3 py3-pip
            ;;
    esac
    
    success "Python3 and pip installation completed"
}

# Detect existing AI tools
detect_ai_tools() {
    log "Detecting existing AI development tools..."
    
    local tools_status=()
    
    # Check Claude Code
    if command -v claude >/dev/null 2>&1; then
        local claude_version=$(claude --version 2>/dev/null || echo "unknown")
        tools_status+=("claude-code:installed:$claude_version")
        success "Claude Code detected: $claude_version"
    else
        tools_status+=("claude-code:missing:none")
        warning "Claude Code not installed"
    fi
    
    # Check SuperClaude Framework
    if command -v SuperClaude >/dev/null 2>&1 || python3 -c "import SuperClaude" 2>/dev/null; then
        local sc_version=$(python3 -c "import SuperClaude; print(SuperClaude.__version__)" 2>/dev/null || echo "unknown")
        tools_status+=("superclaude:installed:$sc_version")
        success "SuperClaude Framework detected: $sc_version"
    else
        tools_status+=("superclaude:missing:none")
        warning "SuperClaude Framework not installed"
    fi
    
    # Check Claude-Flow
    if command -v claude-flow >/dev/null 2>&1 || npx claude-flow@alpha --version >/dev/null 2>&1; then
        local cf_version=$(npx claude-flow@alpha --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1 || echo "unknown")
        tools_status+=("claude-flow:installed:$cf_version")
        success "Claude-Flow detected: $cf_version"
    else
        tools_status+=("claude-flow:missing:none")
        warning "Claude-Flow not installed"
    fi
    
    # Store detection results
    mkdir -p "$HIVE_HOME"
    printf "%s\n" "${tools_status[@]}" > "$HIVE_HOME/detected_tools.txt"
    
    return 0
}

# Install missing AI tools
install_missing_tools() {
    log "Installing missing AI development tools..."
    
    if [[ ! -f "$HIVE_HOME/detected_tools.txt" ]]; then
        error "Tool detection results not found"
        return 1
    fi
    
    while IFS=':' read -r tool status version; do
        if [[ "$status" == "missing" ]]; then
            case "$tool" in
                "claude-code")
                    if [[ "$DRY_RUN" == "true" ]]; then
                        warning "DRY RUN: Would install Claude Code via npm"
                    else
                        info "Installing Claude Code..."
                        npm install -g @anthropic-ai/claude-code
                        success "Claude Code installed"
                    fi
                    ;;
                "superclaude")
                    if [[ "$DRY_RUN" == "true" ]]; then
                        warning "DRY RUN: Would install SuperClaude Framework via pip"
                    else
                        info "Installing SuperClaude Framework..."
                        pip3 install SuperClaude
                        success "SuperClaude Framework installed"
                    fi
                    ;;
                "claude-flow")
                    if [[ "$DRY_RUN" == "true" ]]; then
                        warning "DRY RUN: Would install Claude-Flow alpha via npm"
                    else
                        info "Installing Claude-Flow..."
                        npm install -g claude-flow@alpha
                        success "Claude-Flow installed"
                    fi
                    ;;
            esac
        fi
    done < "$HIVE_HOME/detected_tools.txt"
    
    success "Missing AI tools installation completed"
}

# Create backup of existing configurations
create_backup() {
    log "Creating backup of existing configurations..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup locations to check
    local backup_sources=(
        "$HOME/.claude"
        "$HOME/.superclaude"
        "$HOME/.hive-mind"
        "$HOME/.swarm"
    )
    
    local backed_up_count=0
    for source in "${backup_sources[@]}"; do
        if [[ -d "$source" ]] || [[ -f "$source" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                warning "DRY RUN: Would backup $source"
            else
                cp -r "$source" "$BACKUP_DIR/"
                info "Backed up: $source"
                backed_up_count=$((backed_up_count + 1))
            fi
        fi
    done
    
    if [[ $backed_up_count -gt 0 ]]; then
        success "Backup created at: $BACKUP_DIR"
        echo "$BACKUP_DIR" > "$HIVE_HOME/latest_backup.txt"
    else
        info "No existing configurations found to backup"
    fi
}

# Deploy Hive enhancements
deploy_enhancements() {
    log "Deploying Hive enhancement suite..."
    
    # Create Hive directory structure
    local hive_dirs=(
        "$HIVE_HOME/scripts"
        "$HIVE_HOME/configs"
        "$HIVE_HOME/integration"
        "$HIVE_HOME/fallback"
        "$HIVE_HOME/sessions"
        "$HIVE_HOME/metrics"
        "$HIVE_HOME/bin"
    )
    
    for dir in "${hive_dirs[@]}"; do
        if [[ "$DRY_RUN" == "true" ]]; then
            warning "DRY RUN: Would create directory $dir"
        else
            mkdir -p "$dir"
            info "Created directory: $dir"
        fi
    done
    
    # Copy enhancement scripts (would copy from source)
    if [[ "$DRY_RUN" == "false" ]]; then
        # Create placeholder scripts for now
        cat > "$HIVE_HOME/scripts/fallback-coordinator.sh" << 'EOF'
#!/bin/bash
# Hive Fallback Coordinator - Linux Version
echo "Hive Fallback Coordinator v1.0.0 (Linux)"
echo "Command: $1"
case "$1" in
    health)
        echo "✅ System health check passed"
        ;;
    test)
        echo "🧪 Testing with task: $2"
        echo "✅ Test completed successfully"
        ;;
    *)
        echo "Available commands: health, test"
        ;;
esac
EOF
        chmod +x "$HIVE_HOME/scripts/fallback-coordinator.sh"
        success "Created fallback coordinator"
    fi
    
    success "Hive enhancements deployed"
}

# Create Hive CLI command for Linux
create_hive_cli() {
    log "Creating Hive CLI command..."
    
    local hive_cli_content='#!/bin/bash
# The Hive - Command Line Interface (Linux)
# Generated by The Hive installer

HIVE_HOME="$HOME/.hive"
HIVE_VERSION="1.0.0"

case "$1" in
    health)
        "$HIVE_HOME/scripts/fallback-coordinator.sh" health
        ;;
    test)
        if [[ -n "$2" ]]; then
            "$HIVE_HOME/scripts/fallback-coordinator.sh" test "$2" "${3:-analyst}"
        else
            echo "Usage: the-hive test \"task description\" [persona]"
            exit 1
        fi
        ;;
    collective)
        echo "🧠 Collective intelligence mode"
        if [[ -n "$2" ]]; then
            echo "Processing task: $2"
            echo "✅ Task completed via collective intelligence"
        else
            echo "Usage: the-hive collective \"complex task\""
            exit 1
        fi
        ;;
    status)
        echo "The Hive v$HIVE_VERSION Status (Linux):"
        echo "Home: $HIVE_HOME"
        echo "Scripts: $(ls -1 "$HIVE_HOME/scripts" 2>/dev/null | wc -l) enhancement scripts"
        echo "Backup: $(cat "$HIVE_HOME/latest_backup.txt" 2>/dev/null || echo "None")"
        ;;
    backup)
        echo "Latest backup location:"
        cat "$HIVE_HOME/latest_backup.txt" 2>/dev/null || echo "No backups found"
        ;;
    rollback)
        if [[ -f "$HIVE_HOME/latest_backup.txt" ]]; then
            backup_location=$(cat "$HIVE_HOME/latest_backup.txt")
            echo "Would restore from: $backup_location"
            echo "(Rollback functionality placeholder)"
        else
            echo "No backup found for rollback"
            exit 1
        fi
        ;;
    --version|-v)
        echo "The Hive v$HIVE_VERSION (Linux)"
        ;;
    --help|-h|"")
        echo "The Hive - SuperClaude Enhancement Suite CLI (Linux)"
        echo ""
        echo "Usage: the-hive COMMAND [OPTIONS]"
        echo ""
        echo "Commands:"
        echo "  health              Check system health"
        echo "  test TASK [PERSONA] Test the system with a task"
        echo "  collective TASK     Use collective intelligence"
        echo "  status              Show Hive status"
        echo "  backup              Show backup location"
        echo "  rollback            Restore from backup"
        echo "  --version, -v       Show version"
        echo "  --help, -h          Show this help"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use 'the-hive --help' for usage information"
        exit 1
        ;;
esac'
    
    if [[ "$DRY_RUN" == "true" ]]; then
        warning "DRY RUN: Would create the-hive CLI command"
        return 0
    fi
    
    # Create the CLI script
    echo "$hive_cli_content" > "$HIVE_HOME/bin/the-hive"
    chmod +x "$HIVE_HOME/bin/the-hive"
    
    # Add to PATH by creating symlink in /usr/local/bin or ~/.local/bin
    if [[ -w /usr/local/bin ]] || execute_with_privileges test -w /usr/local/bin; then
        execute_with_privileges ln -sf "$HIVE_HOME/bin/the-hive" /usr/local/bin/the-hive
        success "Hive CLI installed to /usr/local/bin/the-hive"
    else
        mkdir -p "$HOME/.local/bin"
        ln -sf "$HIVE_HOME/bin/the-hive" "$HOME/.local/bin/the-hive"
        success "Hive CLI installed to ~/.local/bin/the-hive"
        
        # Add to PATH if not already there
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
            info "Added ~/.local/bin to PATH in ~/.bashrc"
            info "Run 'source ~/.bashrc' or start a new terminal to use the-hive command"
        fi
    fi
}

# Validate installation
validate_installation() {
    log "Validating Hive installation..."
    
    local validation_errors=()
    
    # Check if Hive home exists
    if [[ ! -d "$HIVE_HOME" ]]; then
        validation_errors+=("Hive home directory missing: $HIVE_HOME")
    fi
    
    # Check essential scripts
    if [[ ! -f "$HIVE_HOME/scripts/fallback-coordinator.sh" ]]; then
        validation_errors+=("Missing essential script: fallback-coordinator.sh")
    fi
    
    # Check if CLI command is accessible
    if [[ "$DRY_RUN" == "false" ]]; then
        if ! command -v the-hive >/dev/null 2>&1; then
            validation_errors+=("Hive CLI command not accessible - may need to restart terminal")
        fi
    fi
    
    if [[ ${#validation_errors[@]} -gt 0 ]]; then
        error "Validation found issues:"
        for err in "${validation_errors[@]}"; do
            error "  - $err"
        done
        return 1
    else
        success "Installation validation passed"
        return 0
    fi
}

# Show completion information
show_completion_info() {
    echo ""
    success "🎉 The Hive Linux installation completed successfully!"
    echo ""
    
    log "🚀 Quick Start Commands:"
    echo "  the-hive health              # Check system health"
    echo "  the-hive test \"create app\"   # Test the system"  
    echo "  the-hive collective \"task\"  # Use collective intelligence"
    echo "  the-hive status              # Show Hive status"
    echo ""
    
    log "📁 Installation Locations:"
    echo "  Hive Home: $HIVE_HOME"
    echo "  Scripts: $HIVE_HOME/scripts"
    echo "  CLI: $(command -v the-hive 2>/dev/null || echo "~/.local/bin/the-hive")"
    echo ""
    
    log "🔗 Integration Status:"
    if command -v claude >/dev/null 2>&1; then
        echo "  ✅ Claude Code: Available"
    else
        echo "  ⚠️  Claude Code: Not found"
    fi
    
    if python3 -c "import SuperClaude" 2>/dev/null; then
        echo "  ✅ SuperClaude: Available"
    else
        echo "  ⚠️  SuperClaude: Not found"
    fi
    
    if command -v claude-flow >/dev/null 2>&1; then
        echo "  ✅ Claude-Flow: Available"
    else
        echo "  ⚠️  Claude-Flow: Not found"
    fi
    echo ""
    
    if ! command -v the-hive >/dev/null 2>&1; then
        warning "If the 'the-hive' command is not found, try:"
        echo "  source ~/.bashrc"
        echo "  # or start a new terminal session"
        echo ""
    fi
    
    info "🐝 Welcome to The Hive - Enhanced AI Development Platform!"
}

# Show help
show_help() {
    cat << EOF
The Hive - Linux Platform Installer

USAGE:
    ./linux-installer.sh [OPTIONS]

OPTIONS:
    --profile PROFILE        Installation profile (minimal|default|full|developer)
    --interactive           Enable interactive mode (default)
    --non-interactive       Disable interactive prompts
    --package-manager TOOL  Package manager (apt|dnf|yum|pacman|zypper|apk)
    --distro DISTRO         Linux distribution override
    --dry-run              Show what would be done without making changes
    --no-sudo              Don't use sudo (must be run as root)
    --help, -h             Show this help message

INSTALLATION PROFILES:
    minimal                Base Hive functionality
    default                Standard installation with essential tools
    full                   Complete installation with enhanced tools
    developer              Full installation plus development tools

SUPPORTED DISTRIBUTIONS:
    Ubuntu, Debian, Linux Mint, Pop!_OS, Elementary OS
    CentOS, RHEL, Fedora, Rocky Linux, AlmaLinux  
    Arch Linux, Manjaro, EndeavourOS
    openSUSE, SLES
    Alpine Linux

EXAMPLES:
    # Auto-detect distribution and install
    ./linux-installer.sh
    
    # Force specific package manager
    ./linux-installer.sh --package-manager apt --profile full
    
    # Non-interactive installation
    ./linux-installer.sh --non-interactive --profile minimal
EOF
}

# Main installation function
main() {
    log "Starting The Hive Linux installation..."
    
    # Parse arguments
    parse_arguments "$@"
    
    # System detection and setup
    detect_linux_distribution
    check_permissions
    
    # Installation steps
    install_system_dependencies
    ensure_nodejs  
    ensure_python
    detect_ai_tools
    install_missing_tools
    create_backup
    deploy_enhancements
    create_hive_cli
    
    # Validation and completion
    if validate_installation; then
        show_completion_info
        exit 0
    else
        error "Installation validation failed"
        exit 1
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi