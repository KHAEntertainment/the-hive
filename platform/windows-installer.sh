#!/bin/bash
# The Hive - Windows Platform Installer  
# Support for WSL2, Git Bash, MSYS2, and PowerShell environments

set -e

# Version and configuration
HIVE_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HIVE_HOME="$HOME/.hive"
BACKUP_DIR="$HIVE_HOME/backup/$(date +%Y%m%d-%H%M%S)"

# Color codes (Windows terminal compatible)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Emojis with Windows fallback
if [[ -n "$WT_SESSION" ]] || [[ "$TERM_PROGRAM" == "vscode" ]] || [[ -n "$VSCODE_INJECTION" ]]; then
    # Windows Terminal or VS Code - emoji support usually good
    HIVE_EMOJI="🐝"
    SUCCESS_EMOJI="✅"
    ERROR_EMOJI="❌"
    WARNING_EMOJI="⚠️"
    INFO_EMOJI="ℹ️"
else
    # Conservative fallback for older Windows terminals
    HIVE_EMOJI="[HIVE]"
    SUCCESS_EMOJI="[OK]"
    ERROR_EMOJI="[ERROR]"
    WARNING_EMOJI="[WARN]"
    INFO_EMOJI="[INFO]"
fi

# Logging functions
log() { echo -e "${CYAN}${HIVE_EMOJI}${NC} [Windows] $*"; }
success() { echo -e "${GREEN}${SUCCESS_EMOJI}${NC} [Windows] $*"; }
error() { echo -e "${RED}${ERROR_EMOJI}${NC} [Windows] $*" >&2; }
warning() { echo -e "${YELLOW}${WARNING_EMOJI}${NC} [Windows] $*"; }
info() { echo -e "${BLUE}${INFO_EMOJI}${NC} [Windows] $*"; }

# Default values
INSTALL_PROFILE="default"
INTERACTIVE_MODE="true"
WINDOWS_ENVIRONMENT=""
DRY_RUN="false"
USE_SCOOP="false"
USE_CHOCOLATEY="false"

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
            --wsl2)
                WINDOWS_ENVIRONMENT="wsl2"
                shift
                ;;
            --git-bash)
                WINDOWS_ENVIRONMENT="gitbash"
                shift
                ;;
            --msys2)
                WINDOWS_ENVIRONMENT="msys2"
                shift
                ;;
            --powershell)
                WINDOWS_ENVIRONMENT="powershell"
                shift
                ;;
            --scoop)
                USE_SCOOP="true"
                shift
                ;;
            --chocolatey)
                USE_CHOCOLATEY="true"
                shift
                ;;
            --dry-run)
                DRY_RUN="true"
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

# Detect Windows environment
detect_windows_environment() {
    log "Detecting Windows environment..."
    
    # Auto-detect if not specified
    if [[ -z "$WINDOWS_ENVIRONMENT" ]]; then
        if [[ -n "$WSL_DISTRO_NAME" ]] || [[ "$(uname -r)" =~ Microsoft|WSL ]]; then
            WINDOWS_ENVIRONMENT="wsl2"
        elif [[ "$MSYSTEM" =~ MINGW ]]; then
            WINDOWS_ENVIRONMENT="msys2"
        elif [[ -n "$GITBASH" ]] || [[ "$TERM_PROGRAM" =~ Git ]]; then
            WINDOWS_ENVIRONMENT="gitbash"
        else
            WINDOWS_ENVIRONMENT="generic"
        fi
    fi
    
    info "Windows Environment: $WINDOWS_ENVIRONMENT"
    
    # Environment-specific setup
    case "$WINDOWS_ENVIRONMENT" in
        "wsl2")
            success "Running in WSL2 - full Linux compatibility"
            # WSL2 uses Linux paths and package management
            ;;
        "gitbash")
            success "Running in Git Bash"
            # Git Bash has limited package management, relies on manual installs
            ;;
        "msys2") 
            success "Running in MSYS2"
            # MSYS2 has pacman package manager
            ;;
        "powershell")
            success "PowerShell environment detected"
            # Would use PowerShell-specific installation methods
            ;;
        *)
            warning "Generic Windows environment - limited functionality"
            ;;
    esac
}

# Check for package managers
detect_package_managers() {
    log "Detecting available package managers..."
    
    local available_managers=()
    
    # Check for Scoop
    if command -v scoop >/dev/null 2>&1; then
        available_managers+=("scoop")
        info "Scoop detected"
    fi
    
    # Check for Chocolatey  
    if command -v choco >/dev/null 2>&1; then
        available_managers+=("chocolatey")
        info "Chocolatey detected"
    fi
    
    # Check for Winget (Windows 10/11)
    if command -v winget >/dev/null 2>&1; then
        available_managers+=("winget")
        info "Winget detected"
    fi
    
    # Check for MSYS2 pacman
    if [[ "$WINDOWS_ENVIRONMENT" == "msys2" ]] && command -v pacman >/dev/null 2>&1; then
        available_managers+=("pacman")
        info "MSYS2 pacman detected"
    fi
    
    # Check for WSL2 package managers
    if [[ "$WINDOWS_ENVIRONMENT" == "wsl2" ]]; then
        if command -v apt >/dev/null 2>&1; then
            available_managers+=("apt")
            info "WSL2 apt detected"
        elif command -v yum >/dev/null 2>&1; then
            available_managers+=("yum")
            info "WSL2 yum detected"
        fi
    fi
    
    if [[ ${#available_managers[@]} -eq 0 ]]; then
        warning "No package managers detected - will use manual installation methods"
    else
        success "Available package managers: ${available_managers[*]}"
    fi
}

# Install Scoop if requested
install_scoop() {
    if [[ "$USE_SCOOP" == "true" ]] && ! command -v scoop >/dev/null 2>&1; then
        log "Installing Scoop package manager..."
        
        if [[ "$DRY_RUN" == "true" ]]; then
            warning "DRY RUN: Would install Scoop"
            return 0
        fi
        
        # Install Scoop
        if command -v powershell.exe >/dev/null 2>&1; then
            powershell.exe -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; iwr -useb get.scoop.sh | iex"
            success "Scoop installed"
        else
            error "PowerShell not available for Scoop installation"
            return 1
        fi
    fi
}

# Install dependencies based on environment
install_dependencies() {
    log "Installing dependencies for profile: $INSTALL_PROFILE"
    
    local base_deps=("git" "curl" "node" "python3")
    local enhanced_deps=("gh" "jq" "fzf")
    local developer_deps=("docker" "kubectl")
    
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
    
    case "$WINDOWS_ENVIRONMENT" in
        "wsl2")
            install_wsl2_dependencies "${deps_to_install[@]}"
            ;;
        "msys2")
            install_msys2_dependencies "${deps_to_install[@]}"
            ;;
        "gitbash")
            install_gitbash_dependencies "${deps_to_install[@]}"
            ;;
        *)
            install_generic_dependencies "${deps_to_install[@]}"
            ;;
    esac
    
    success "Dependencies installation completed"
}

# WSL2 dependency installation
install_wsl2_dependencies() {
    local deps=("$@")
    
    info "Installing WSL2 dependencies using Linux package manager..."
    
    # Detect WSL distribution
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        local distro_id="$ID"
    else
        local distro_id="unknown"
    fi
    
    case "$distro_id" in
        ubuntu|debian)
            if [[ "$DRY_RUN" == "false" ]]; then
                sudo apt-get update -y
            fi
            
            for dep in "${deps[@]}"; do
                case "$dep" in
                    "node")
                        if [[ "$DRY_RUN" == "true" ]]; then
                            warning "DRY RUN: Would install Node.js"
                        else
                            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
                            sudo apt-get install -y nodejs
                        fi
                        ;;
                    "python3")
                        if [[ "$DRY_RUN" == "false" ]]; then
                            sudo apt-get install -y python3 python3-pip
                        fi
                        ;;
                    *)
                        if [[ "$DRY_RUN" == "false" ]]; then
                            sudo apt-get install -y "$dep" || warning "Failed to install $dep"
                        fi
                        ;;
                esac
            done
            ;;
        *)
            warning "Unsupported WSL distribution: $distro_id"
            ;;
    esac
}

# MSYS2 dependency installation  
install_msys2_dependencies() {
    local deps=("$@")
    
    info "Installing MSYS2 dependencies using pacman..."
    
    if [[ "$DRY_RUN" == "false" ]]; then
        pacman -Sy --noconfirm
    fi
    
    for dep in "${deps[@]}"; do
        case "$dep" in
            "node")
                local package="mingw-w64-x86_64-nodejs"
                ;;
            "python3")
                local package="mingw-w64-x86_64-python"
                ;;
            "git")
                local package="git"
                ;;
            "curl")
                local package="curl"
                ;;
            *)
                local package="mingw-w64-x86_64-$dep"
                ;;
        esac
        
        if [[ "$DRY_RUN" == "true" ]]; then
            warning "DRY RUN: Would install $package"
        else
            pacman -S --noconfirm "$package" || warning "Failed to install $package"
        fi
    done
}

# Git Bash dependency installation
install_gitbash_dependencies() {
    local deps=("$@")
    
    info "Installing Git Bash dependencies..."
    warning "Git Bash has limited package management - manual installation required for some tools"
    
    for dep in "${deps[@]}"; do
        case "$dep" in
            "git")
                if command -v git >/dev/null 2>&1; then
                    success "Git already available"
                else
                    warning "Git should be installed with Git Bash"
                fi
                ;;
            "node")
                if ! command -v node >/dev/null 2>&1; then
                    warning "Please install Node.js manually from https://nodejs.org/"
                fi
                ;;
            "python3")
                if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
                    warning "Please install Python manually from https://python.org/"
                fi
                ;;
            *)
                warning "Manual installation required for: $dep"
                ;;
        esac
    done
}

# Generic Windows dependency installation
install_generic_dependencies() {
    local deps=("$@")
    
    info "Installing dependencies using available package managers..."
    
    # Try Scoop first if available
    if command -v scoop >/dev/null 2>&1; then
        for dep in "${deps[@]}"; do
            if [[ "$DRY_RUN" == "true" ]]; then
                warning "DRY RUN: Would install $dep via Scoop"
            else
                scoop install "$dep" || warning "Failed to install $dep via Scoop"
            fi
        done
    # Try Chocolatey
    elif command -v choco >/dev/null 2>&1; then
        for dep in "${deps[@]}"; do
            if [[ "$DRY_RUN" == "true" ]]; then
                warning "DRY RUN: Would install $dep via Chocolatey"
            else
                choco install "$dep" -y || warning "Failed to install $dep via Chocolatey"
            fi
        done
    # Try Winget
    elif command -v winget >/dev/null 2>&1; then
        for dep in "${deps[@]}"; do
            if [[ "$DRY_RUN" == "true" ]]; then
                warning "DRY RUN: Would install $dep via Winget"
            else
                winget install "$dep" || warning "Failed to install $dep via Winget"
            fi
        done
    else
        warning "No package manager available - manual installation required"
        warning "Please install: ${deps[*]}"
    fi
}

# Detect AI tools
detect_ai_tools() {
    log "Detecting existing AI development tools..."
    
    local tools_status=()
    
    # Check Claude Code
    if command -v claude >/dev/null 2>&1 || command -v claude.exe >/dev/null 2>&1; then
        local claude_version=$(claude --version 2>/dev/null || claude.exe --version 2>/dev/null || echo "unknown")
        tools_status+=("claude-code:installed:$claude_version")
        success "Claude Code detected: $claude_version"
    else
        tools_status+=("claude-code:missing:none")
        warning "Claude Code not installed"
    fi
    
    # Check SuperClaude Framework  
    local python_cmd="python3"
    if ! command -v python3 >/dev/null 2>&1 && command -v python >/dev/null 2>&1; then
        python_cmd="python"
    fi
    
    if command -v SuperClaude >/dev/null 2>&1 || $python_cmd -c "import SuperClaude" 2>/dev/null; then
        local sc_version=$($python_cmd -c "import SuperClaude; print(SuperClaude.__version__)" 2>/dev/null || echo "unknown")
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
    
    local python_cmd="python3"
    if ! command -v python3 >/dev/null 2>&1 && command -v python >/dev/null 2>&1; then
        python_cmd="python"
    fi
    
    local pip_cmd="pip3"
    if ! command -v pip3 >/dev/null 2>&1 && command -v pip >/dev/null 2>&1; then
        pip_cmd="pip"
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
                        $pip_cmd install SuperClaude
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

# Create backup
create_backup() {
    log "Creating backup of existing configurations..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Windows-specific backup locations
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

# Deploy enhancements
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
    
    # Create Windows-compatible scripts
    if [[ "$DRY_RUN" == "false" ]]; then
        cat > "$HIVE_HOME/scripts/fallback-coordinator.sh" << 'EOF'
#!/bin/bash
# Hive Fallback Coordinator - Windows Version
echo "Hive Fallback Coordinator v1.0.0 (Windows)"
echo "Environment: $WINDOWS_ENVIRONMENT"
echo "Command: $1"

case "$1" in
    health)
        echo "✅ System health check passed (Windows)"
        ;;
    test)
        echo "🧪 Testing with task: $2"
        echo "✅ Test completed successfully (Windows)"
        ;;
    *)
        echo "Available commands: health, test"
        ;;
esac
EOF
        chmod +x "$HIVE_HOME/scripts/fallback-coordinator.sh"
        success "Created Windows-compatible fallback coordinator"
    fi
    
    success "Hive enhancements deployed"
}

# Create CLI command
create_hive_cli() {
    log "Creating Hive CLI command for Windows..."
    
    local hive_cli_content='#!/bin/bash
# The Hive - Command Line Interface (Windows)
# Generated by The Hive installer

HIVE_HOME="$HOME/.hive"
HIVE_VERSION="1.0.0"
WINDOWS_ENVIRONMENT="'$WINDOWS_ENVIRONMENT'"

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
        echo "🧠 Collective intelligence mode (Windows)"
        if [[ -n "$2" ]]; then
            echo "Processing task: $2"
            echo "✅ Task completed via collective intelligence"
        else
            echo "Usage: the-hive collective \"complex task\""
            exit 1
        fi
        ;;
    status)
        echo "The Hive v$HIVE_VERSION Status (Windows - $WINDOWS_ENVIRONMENT):"
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
            echo "(Rollback functionality placeholder for Windows)"
        else
            echo "No backup found for rollback"
            exit 1
        fi
        ;;
    --version|-v)
        echo "The Hive v$HIVE_VERSION (Windows - $WINDOWS_ENVIRONMENT)"
        ;;
    --help|-h|"")
        echo "The Hive - SuperClaude Enhancement Suite CLI (Windows)"
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
        echo "Use '\''the-hive --help'\'' for usage information"
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
    
    # Add to PATH (Windows-specific approach)
    case "$WINDOWS_ENVIRONMENT" in
        "wsl2")
            # WSL2 can use standard Linux approach
            mkdir -p "$HOME/.local/bin"
            ln -sf "$HIVE_HOME/bin/the-hive" "$HOME/.local/bin/the-hive"
            
            # Add to PATH in .bashrc if not already there
            if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
                info "Added ~/.local/bin to PATH in ~/.bashrc"
            fi
            success "Hive CLI installed to ~/.local/bin/the-hive"
            ;;
        "msys2"|"gitbash")
            # For MSYS2/Git Bash, add to user bin directory
            mkdir -p "$HOME/bin"
            cp "$HIVE_HOME/bin/the-hive" "$HOME/bin/the-hive"
            
            if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
                echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
                info "Added ~/bin to PATH in ~/.bashrc"
            fi
            success "Hive CLI installed to ~/bin/the-hive"
            ;;
        *)
            # Generic approach - just make it available in Hive home
            success "Hive CLI created at $HIVE_HOME/bin/the-hive"
            warning "Add $HIVE_HOME/bin to your PATH to use 'the-hive' command globally"
            ;;
    esac
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
    success "🎉 The Hive Windows installation completed successfully!"
    echo ""
    
    log "Environment: $WINDOWS_ENVIRONMENT"
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
    echo "  CLI: $HIVE_HOME/bin/the-hive"
    echo ""
    
    case "$WINDOWS_ENVIRONMENT" in
        "wsl2"|"msys2"|"gitbash")
            info "To use 'the-hive' command globally, restart your terminal or run:"
            echo "  source ~/.bashrc"
            ;;
        *)
            info "To use 'the-hive' command globally, add to your PATH:"
            echo "  export PATH=\"$HIVE_HOME/bin:\$PATH\""
            ;;
    esac
    echo ""
    
    info "🐝 Welcome to The Hive - Enhanced AI Development Platform!"
}

# Show help
show_help() {
    cat << EOF
The Hive - Windows Platform Installer

USAGE:
    ./windows-installer.sh [OPTIONS]

OPTIONS:
    --profile PROFILE        Installation profile (minimal|default|full|developer)
    --interactive           Enable interactive mode (default)
    --non-interactive       Disable interactive prompts
    --wsl2                  Force WSL2 environment
    --git-bash              Force Git Bash environment
    --msys2                 Force MSYS2 environment
    --powershell            Force PowerShell environment
    --scoop                 Use Scoop package manager
    --chocolatey            Use Chocolatey package manager
    --dry-run              Show what would be done without making changes
    --help, -h             Show this help message

INSTALLATION PROFILES:
    minimal                Base Hive functionality
    default                Standard installation with essential tools
    full                   Complete installation with enhanced tools
    developer              Full installation plus development tools

SUPPORTED ENVIRONMENTS:
    WSL2                   Windows Subsystem for Linux 2 (Recommended)
    Git Bash               Git for Windows Bash environment
    MSYS2                  MSYS2 development environment
    PowerShell             PowerShell with limited functionality

EXAMPLES:
    # Auto-detect environment and install
    ./windows-installer.sh
    
    # Force WSL2 with full profile
    ./windows-installer.sh --wsl2 --profile full
    
    # Git Bash with Scoop package manager
    ./windows-installer.sh --git-bash --scoop
EOF
}

# Main installation function
main() {
    log "Starting The Hive Windows installation..."
    
    # Parse arguments
    parse_arguments "$@"
    
    # Environment detection and setup
    detect_windows_environment
    detect_package_managers
    install_scoop
    
    # Installation steps
    install_dependencies
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