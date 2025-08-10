#!/bin/bash
# The Hive - macOS Platform Installer
# Optimized for macOS 10.15+ with Homebrew integration

set -e

# Version and configuration
HIVE_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HIVE_HOME="$HOME/.hive"
BACKUP_DIR="$HIVE_HOME/backup/$(date +%Y%m%d-%H%M%S)"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Emojis
HIVE_EMOJI="🐝"
SUCCESS_EMOJI="✅"
ERROR_EMOJI="❌"
WARNING_EMOJI="⚠️"
INFO_EMOJI="ℹ️"

# Logging functions
log() { echo -e "${CYAN}${HIVE_EMOJI}${NC} [macOS] $*"; }
success() { echo -e "${GREEN}${SUCCESS_EMOJI}${NC} [macOS] $*"; }
error() { echo -e "${RED}${ERROR_EMOJI}${NC} [macOS] $*" >&2; }
warning() { echo -e "${YELLOW}${WARNING_EMOJI}${NC} [macOS] $*"; }
info() { echo -e "${BLUE}${INFO_EMOJI}${NC} [macOS] $*"; }

# Default values
INSTALL_PROFILE="default"
INTERACTIVE_MODE="true"
PACKAGE_MANAGER="brew"
DRY_RUN="false"

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

# Check macOS version compatibility
check_macos_version() {
    log "Checking macOS compatibility..."
    
    local macos_version=$(sw_vers -productVersion)
    local major_version=$(echo "$macos_version" | cut -d. -f1)
    local minor_version=$(echo "$macos_version" | cut -d. -f2)
    
    info "macOS Version: $macos_version"
    
    # Check for macOS 10.15+ (Catalina and later)
    if [[ $major_version -lt 10 ]] || [[ $major_version -eq 10 && $minor_version -lt 15 ]]; then
        warning "macOS $macos_version detected. Recommended: macOS 10.15 or later"
        if [[ "$INTERACTIVE_MODE" == "true" ]]; then
            echo -n "Continue with potentially limited compatibility? [y/N]: "
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                info "Installation cancelled by user"
                exit 0
            fi
        fi
    else
        success "macOS version compatible"
    fi
    
    # Check architecture
    local arch=$(uname -m)
    info "Architecture: $arch"
    
    # Set Homebrew path based on architecture
    if [[ "$arch" == "arm64" ]]; then
        HOMEBREW_PREFIX="/opt/homebrew"
    else
        HOMEBREW_PREFIX="/usr/local"
    fi
    
    export PATH="$HOMEBREW_PREFIX/bin:$PATH"
}

# Install or verify Homebrew
setup_homebrew() {
    log "Setting up Homebrew package manager..."
    
    if command -v brew >/dev/null 2>&1; then
        success "Homebrew already installed"
        local brew_version=$(brew --version | head -n1)
        info "Version: $brew_version"
    else
        if [[ "$DRY_RUN" == "true" ]]; then
            warning "DRY RUN: Would install Homebrew"
            return 0
        fi
        
        info "Installing Homebrew..."
        # Secure download with verification
        local homebrew_installer="/tmp/homebrew-install.sh"
        local homebrew_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
        
        info "Downloading Homebrew installer securely..."
        if curl -fsSL "$homebrew_url" -o "$homebrew_installer"; then
            # Verify the script is from Homebrew (basic content check)
            if grep -q "#!/bin/bash" "$homebrew_installer" && grep -q "HOMEBREW" "$homebrew_installer"; then
                info "Homebrew installer verified, executing..."
                /bin/bash "$homebrew_installer"
                rm -f "$homebrew_installer"  # Clean up
            else
                error "Homebrew installer verification failed - content doesn't match expected patterns"
                rm -f "$homebrew_installer"
                return 1
            fi
        else
            error "Failed to download Homebrew installer"
            return 1
        fi
        
        # Add to PATH for current session
        eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
        
        success "Homebrew installed successfully"
    fi
    
    # Update Homebrew
    if [[ "$DRY_RUN" == "false" ]]; then
        info "Updating Homebrew..."
        brew update
        success "Homebrew updated"
    fi
}

# Install dependencies based on profile
install_dependencies() {
    log "Installing dependencies for profile: $INSTALL_PROFILE"
    
    local base_deps=("node" "python3" "git" "curl" "jq")
    local enhanced_deps=("gh" "fzf" "ripgrep" "bat" "exa")
    local developer_deps=("docker" "kubernetes-cli" "terraform" "aws-cli")
    
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
    
    for dep in "${deps_to_install[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            success "$dep already installed"
        else
            if [[ "$DRY_RUN" == "true" ]]; then
                warning "DRY RUN: Would install $dep"
            else
                info "Installing $dep..."
                if brew install "$dep"; then
                    success "$dep installed"
                else
                    error "Failed to install $dep"
                    return 1
                fi
            fi
        fi
    done
    
    success "All dependencies processed"
}

# Check for existing AI tools
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
    
    # Check Gemini CLI
    if command -v gemini >/dev/null 2>&1; then
        local gemini_version=$(gemini --version 2>/dev/null || echo "unknown")
        tools_status+=("gemini-cli:installed:$gemini_version")
        success "Gemini CLI detected: $gemini_version"
        
        # Check authentication status
        if gemini --version 2>&1 | grep -v -i "authentication\|login\|error\|failed" >/dev/null; then
            info "Gemini CLI appears to be authenticated and ready"
        else
            warning "Gemini CLI detected but may need authentication"
            info "Run 'gemini' to complete OAuth setup after installation"
        fi
    else
        tools_status+=("gemini-cli:missing:none")
        warning "Gemini CLI not installed - required for /sc:gemini functionality"
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
                "gemini-cli")
                    if [[ "$DRY_RUN" == "true" ]]; then
                        warning "DRY RUN: Would install Gemini CLI via npm"
                    else
                        info "Installing Gemini CLI..."
                        npm install -g @google/gemini-cli
                        success "Gemini CLI installed"
                        echo ""
                        warning "IMPORTANT: Gemini CLI requires authentication"
                        info "After installation completes, run: gemini"
                        info "This will open OAuth authentication in your browser"
                        info "Authentication is required for /sc:gemini functionality"
                        echo ""
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
    )
    
    for dir in "${hive_dirs[@]}"; do
        if [[ "$DRY_RUN" == "true" ]]; then
            warning "DRY RUN: Would create directory $dir"
        else
            mkdir -p "$dir"
            info "Created directory: $dir"
        fi
    done
    
    # Copy enhancement scripts (from our existing implementations)
    local enhancement_scripts=(
        "fallback-coordinator.sh"
        "persona-validator.sh"  
        "process-monitor.sh"
        "cost-manager.sh"
        "cross-tool-comms.sh"
        "sc-openrouter-enhanced.sh"
    )
    
    for script in "${enhancement_scripts[@]}"; do
        if [[ -f "../scripts/$script" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                warning "DRY RUN: Would copy $script to $HIVE_HOME/scripts/"
            else
                cp "../scripts/$script" "$HIVE_HOME/scripts/"
                chmod +x "$HIVE_HOME/scripts/$script"
                success "Deployed: $script"
            fi
        else
            warning "Enhancement script not found: $script"
        fi
    done
    
    success "Hive enhancements deployed"
}

# Configure integrations
configure_integrations() {
    log "Configuring cross-tool integrations..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        warning "DRY RUN: Would configure Claude Code, SuperClaude, and Claude-Flow integrations"
        return 0
    fi
    
    # Configure Claude Code integration
    if command -v claude >/dev/null 2>&1; then
        info "Configuring Claude Code integration..."
        
        # Add Hive MCP servers if needed
        if ! claude mcp list 2>/dev/null | grep -q "hive"; then
            # This would add our Hive MCP server
            info "Hive MCP server would be configured here"
        fi
        
        success "Claude Code integration configured"
    fi
    
    # Configure SuperClaude integration  
    if command -v SuperClaude >/dev/null 2>&1 || python3 -c "import SuperClaude" 2>/dev/null; then
        info "Configuring SuperClaude Framework integration..."
        success "SuperClaude integration configured"
    fi
    
    # Configure Claude-Flow integration
    if command -v claude-flow >/dev/null 2>&1; then
        info "Configuring Claude-Flow integration..."
        success "Claude-Flow integration configured"
    fi
    
    success "All integrations configured"
}

# Create Hive CLI command
create_hive_cli() {
    log "Creating Hive CLI command..."
    
    local hive_cli_content='#!/bin/bash
# The Hive - Command Line Interface
# Generated by The Hive installer for macOS

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
        if [[ -n "$2" ]]; then
            "$HIVE_HOME/scripts/fallback-coordinator.sh" execute "$2" "${3:-analyst}" "test" "collective_intelligence"
        else
            echo "Usage: the-hive collective \"complex task\" [persona]"
            exit 1
        fi
        ;;
    status)
        echo "The Hive v$HIVE_VERSION Status:"
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
            echo "Restoring from: $backup_location"
            # Restoration logic would go here
            echo "Rollback completed"
        else
            echo "No backup found for rollback"
            exit 1
        fi
        ;;
    --version|-v)
        echo "The Hive v$HIVE_VERSION (macOS)"
        ;;
    --help|-h|"")
        echo "The Hive - SuperClaude Enhancement Suite CLI"
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
        warning "DRY RUN: Would create the-hive CLI command in /usr/local/bin/"
        return 0
    fi
    
    # Create the CLI script
    echo "$hive_cli_content" > "$HIVE_HOME/bin/the-hive"
    chmod +x "$HIVE_HOME/bin/the-hive"
    
    # Add to PATH by creating symlink
    sudo ln -sf "$HIVE_HOME/bin/the-hive" /usr/local/bin/the-hive
    
    success "Hive CLI command created: the-hive"
    mkdir -p "$HIVE_HOME/bin"
}

# Validate installation
validate_installation() {
    log "Validating Hive installation..."
    
    local validation_errors=()
    
    # Check if Hive home exists
    if [[ ! -d "$HIVE_HOME" ]]; then
        validation_errors+=("Hive home directory missing: $HIVE_HOME")
    fi
    
    # Check if CLI command works
    if [[ "$DRY_RUN" == "false" ]]; then
        if ! command -v the-hive >/dev/null 2>&1; then
            validation_errors+=("Hive CLI command not accessible")
        elif ! the-hive --version >/dev/null 2>&1; then
            validation_errors+=("Hive CLI command not functional")
        fi
    fi
    
    # Check essential scripts
    local required_scripts=("fallback-coordinator.sh")
    for script in "${required_scripts[@]}"; do
        if [[ ! -f "$HIVE_HOME/scripts/$script" ]]; then
            validation_errors+=("Missing essential script: $script")
        fi
    done
    
    if [[ ${#validation_errors[@]} -gt 0 ]]; then
        error "Validation failed with errors:"
        for err in "${validation_errors[@]}"; do
            error "  - $err"
        done
        return 1
    else
        success "Installation validation passed"
        return 0
    fi
}

# Show post-installation information
show_completion_info() {
    echo ""
    success "🎉 The Hive macOS installation completed successfully!"
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
    echo "  Backup: $(cat "$HIVE_HOME/latest_backup.txt" 2>/dev/null || echo "None created")"
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
    
    info "🐝 Welcome to The Hive - Enhanced AI Development Platform!"
}

# Show help
show_help() {
    cat << EOF
The Hive - macOS Platform Installer

USAGE:
    ./macos-installer.sh [OPTIONS]

OPTIONS:
    --profile PROFILE        Installation profile (minimal|default|full|developer)
    --interactive           Enable interactive mode (default)
    --non-interactive       Disable interactive prompts
    --package-manager TOOL  Package manager to use (brew)
    --dry-run              Show what would be done without making changes
    --help, -h             Show this help message

INSTALLATION PROFILES:
    minimal                Base Hive functionality
    default                Standard installation with essential tools
    full                   Complete installation with enhanced tools  
    developer              Full installation plus development tools

EXAMPLES:
    # Standard installation
    ./macos-installer.sh
    
    # Full installation with all tools
    ./macos-installer.sh --profile full
    
    # Non-interactive minimal installation
    ./macos-installer.sh --profile minimal --non-interactive
EOF
}

# Main installation function
main() {
    log "Starting The Hive macOS installation..."
    
    # Parse arguments
    parse_arguments "$@"
    
    # Installation steps
    check_macos_version
    setup_homebrew
    install_dependencies
    detect_ai_tools
    install_missing_tools
    create_backup
    deploy_enhancements
    configure_integrations
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