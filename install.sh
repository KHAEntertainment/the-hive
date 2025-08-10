#!/bin/bash
# The Hive - Universal Cross-Platform Installer
# SuperClaude Enhancement Suite Distribution System
# Repository: https://github.com/KHAEntertainment/the-hive

set -e

# Version and metadata
HIVE_VERSION="1.0.0"
HIVE_REPO="https://github.com/KHAEntertainment/the-hive.git"
HIVE_RAW_BASE="https://raw.githubusercontent.com/KHAEntertainment/the-hive/main"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Emoji support detection
if [[ "$TERM" == "dumb" ]] || [[ -n "$CI" ]]; then
    # Disable emojis in non-interactive environments
    HIVE_EMOJI="[HIVE]"
    SUCCESS_EMOJI="[OK]"
    ERROR_EMOJI="[ERROR]"
    WARNING_EMOJI="[WARN]"
    INFO_EMOJI="[INFO]"
else
    HIVE_EMOJI="🐝"
    SUCCESS_EMOJI="✅"
    ERROR_EMOJI="❌"
    WARNING_EMOJI="⚠️ "
    INFO_EMOJI="ℹ️ "
fi

# Logging functions
log() {
    echo -e "${CYAN}${HIVE_EMOJI}${NC} $*"
}

success() {
    echo -e "${GREEN}${SUCCESS_EMOJI}${NC} $*"
}

error() {
    echo -e "${RED}${ERROR_EMOJI}${NC} $*" >&2
}

warning() {
    echo -e "${YELLOW}${WARNING_EMOJI}${NC} $*"
}

info() {
    echo -e "${BLUE}${INFO_EMOJI}${NC} $*"
}

# Show banner
show_banner() {
    echo -e "${YELLOW}"
    cat << 'EOF'
                                                                                                                                      
                                                                                                                                      
                                                              #### ##                                                                 
                                                          ######## %#####                                                             
                                                       ########### %#######                                                           
                                                    ############## %%##########                                                       
                                                    %%%#########    %%%#########                                                      
                                               #####   %%####  ######  #%%###  ######                                                 
                                            ###########  #  ############    ############                                              
                                          %##############  %############## %%##############                                           
                                      ##  %##############  %############## %%############## ###                                       
                                   ##### %%##############  %############## %%############## %%####                                    
                                ######## %%##############  %############## %%############## %%#######                                 
                               %######## %%%#############  %%%%##########  %%%############    %%%####                                 
                               %%####  ##   %%%#######         %%%%##          %%%#####  #####   %%##                                 
                               %%#  ########   %%##                               %#  ###########  ##                                 
                                 ##############          %%###        ######        %%#############                                   
                                %%##############            %%#      ###            %###############                                  
                                 %##############             %%#    ###             %%##############                                  
                                 %##############             #########              %%##############                                  
                                 %##############            %###########            %%##############                                  
                                 %%%###########            %%############            %%%###########                                   
                               ##   %%%######              %%############              %%%%#####                                      
                               %####   %%                   %%%#########                   #    #####                                 
                               %%#######       ############   %%%%%###   %%##########        ########                                 
                               %%#######     ##############               %%###########      %#######                                 
                               %%#######    %%############   ###########   %%###########     %#######                                 
                               %%#######    %%##########   %%############   %%##########     %#######                                 
                               %%#######      %%%######   %%%#############    %%%#####       %%######                                 
                               %%######           %                                           %%%####                                 
                               %%##   ####                                                ####   %%##                                 
                                   ###########           #%################          ############                                     
                                 %##############          %%###############         %%##############                                  
                                 %##############           %%##%%##%%%%###          %%##############                                  
                                 %##############                                    %%##############                                  
                                 %##############             ###########            %%##############                                  
                                 %%%############              %%######               %%############                                   
                                    %%#######   ##              %%###             ###  %%%#######                                     
                                      %%%#   #########           ###          ##########  %%##                                        
                                          %%#############   #############  %%#############                                            
                                            %%###########  %############## %%############                                             
                                              %%%########  %############## %%#########                                                
                                                  %%%####  %############## %%#####                                                    
                                                     %%##  %%############# %%##                                                       
                                                            %%%##########                                                             
                                                               %%%####                                                                
                                                                  %                                                                   
                                                                                                                                      
                                                                                                                                      
                                                                                                                                      
                                                                                                                                      
                     #################      ####  ############     ####       ###  #######       #################                    
                     #################      ####  ############     ####       ###  ########      ### #############                    
                          ###     ####      ####  ###              ####       ###  #### ###     #### ####                             
                          ###     ####      ####  ###              ####       ###  #### ####    ###  ####                             
                          ###     ##############  ###########      ##############  ####  ###   ####  ###########                      
                          ###     ##############  ###########      ##############  ####  ####  ###   ###########                      
                          ###     ####      ####  ###              ####       ###  ####   ### ###    ####                             
                          ###     ####      ####  ###              ####       ###  ####   #######    ####                             
                          ###     ####      ####  ###              ####       ###  ####    #####     ####                             
                          ###     ####      ####  ############     ####       ###  ####     ####     #############                    
                                                                                                                                      
                                                                                                                                      
EOF
    echo -e "${NC}"
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}                    ${HIVE_EMOJI} ${YELLOW}THE HIVE${NC}                    ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}            ${CYAN}SuperClaude Enhancement Suite${NC}             ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}              ${CYAN}Cross-Platform AI Coordination${NC}            ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Version: ${HIVE_VERSION}${NC}"
    echo -e "${CYAN}Repository: ${HIVE_REPO}${NC}"
    echo ""
}

# Platform detection
detect_platform() {
    case "$(uname -s)" in
        Darwin*)
            PLATFORM="macos"
            DISTRO="macos"
            PACKAGE_MANAGER="brew"
            ;;
        Linux*)
            PLATFORM="linux"
            # Detect Linux distribution
            if [[ -f /etc/os-release ]]; then
                . /etc/os-release
                DISTRO="$ID"
                case "$DISTRO" in
                    ubuntu|debian)
                        PACKAGE_MANAGER="apt"
                        ;;
                    centos|rhel|fedora)
                        PACKAGE_MANAGER="yum"
                        ;;
                    arch|manjaro)
                        PACKAGE_MANAGER="pacman"
                        ;;
                    *)
                        PACKAGE_MANAGER="generic"
                        ;;
                esac
            else
                DISTRO="unknown"
                PACKAGE_MANAGER="generic"
            fi
            ;;
        MINGW*|CYGWIN*|MSYS*)
            PLATFORM="windows"
            DISTRO="windows"
            PACKAGE_MANAGER="scoop"
            ;;
        *)
            PLATFORM="unknown"
            DISTRO="unknown"
            PACKAGE_MANAGER="generic"
            ;;
    esac
    
    info "Platform detected: $PLATFORM ($DISTRO)"
    info "Package manager: $PACKAGE_MANAGER"
}

# Check prerequisites
check_prerequisites() {
    log "Checking system prerequisites..."
    
    local missing_tools=()
    
    # Check for essential tools
    if ! command -v curl >/dev/null 2>&1; then
        missing_tools+=("curl")
    fi
    
    if ! command -v git >/dev/null 2>&1; then
        missing_tools+=("git")
    fi
    
    if ! command -v jq >/dev/null 2>&1 && [[ "$PLATFORM" != "windows" ]]; then
        missing_tools+=("jq")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        error "Missing required tools: ${missing_tools[*]}"
        info "The installer will attempt to install these automatically."
        return 1
    fi
    
    success "All prerequisites available"
    return 0
}

# Install missing prerequisites
install_prerequisites() {
    log "Installing missing prerequisites for $PLATFORM..."
    
    case "$PLATFORM" in
        "macos")
            # Check if Homebrew is available
            if ! command -v brew >/dev/null 2>&1; then
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
                
                # Add Homebrew to PATH for current session
                if [[ -f /opt/homebrew/bin/brew ]]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                elif [[ -f /usr/local/bin/brew ]]; then
                    eval "$(/usr/local/bin/brew shellenv)"
                fi
            fi
            
            # Install missing tools
            if ! command -v curl >/dev/null 2>&1; then
                brew install curl
            fi
            if ! command -v git >/dev/null 2>&1; then
                brew install git
            fi
            if ! command -v jq >/dev/null 2>&1; then
                brew install jq
            fi
            ;;
        "linux")
            case "$PACKAGE_MANAGER" in
                "apt")
                    sudo apt-get update -y
                    sudo apt-get install -y curl git jq
                    ;;
                "yum")
                    sudo yum install -y curl git jq
                    ;;
                "pacman")
                    sudo pacman -Sy --noconfirm curl git jq
                    ;;
                *)
                    error "Unsupported package manager: $PACKAGE_MANAGER"
                    error "Please install curl, git, and jq manually."
                    return 1
                    ;;
            esac
            ;;
        "windows")
            # For Windows, we'll handle this in the Windows-specific installer
            warning "Windows prerequisite installation will be handled by platform-specific installer"
            ;;
        *)
            error "Unknown platform: $PLATFORM"
            return 1
            ;;
    esac
    
    success "Prerequisites installed successfully"
}

# Download platform-specific installer
download_installer() {
    local platform_installer="$1"
    local temp_installer="/tmp/hive-${platform_installer}-installer.sh"
    
    log "Downloading $platform_installer installer..." >&2
    
    if curl -fsSL "${HIVE_RAW_BASE}/platform/${platform_installer}-installer.sh" -o "$temp_installer"; then
        chmod +x "$temp_installer"
        success "Downloaded $platform_installer installer" >&2
        echo "$temp_installer"
        return 0
    else
        error "Failed to download $platform_installer installer" >&2
        return 1
    fi
}

# Parse command line arguments
parse_arguments() {
    INTERACTIVE_MODE="true"
    FORCE_PLATFORM=""
    INSTALL_PROFILE="default"
    DRY_RUN="false"
    VERBOSE="false"
    SKIP_DEPS="false"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --platform)
                FORCE_PLATFORM="$2"
                shift 2
                ;;
            --profile)
                INSTALL_PROFILE="$2"
                shift 2
                ;;
            --non-interactive)
                INTERACTIVE_MODE="false"
                shift
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --verbose)
                VERBOSE="true"
                set -x
                shift
                ;;
            --skip-deps)
                SKIP_DEPS="true"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Override platform if specified
    if [[ -n "$FORCE_PLATFORM" ]]; then
        PLATFORM="$FORCE_PLATFORM"
        info "Platform overridden to: $PLATFORM"
    fi
}

# Show help
show_help() {
    cat << EOF
The Hive - SuperClaude Enhancement Suite Installer

USAGE:
    ./install.sh [OPTIONS]

OPTIONS:
    --platform PLATFORM     Force specific platform (macos|linux|windows)
    --profile PROFILE        Installation profile (minimal|default|full|developer)
    --non-interactive        Run in non-interactive mode
    --dry-run               Show what would be installed without making changes
    --verbose               Enable verbose output
    --skip-deps             Skip dependency installation
    --help, -h              Show this help message

INSTALLATION PROFILES:
    minimal      Core Hive functionality only
    default      Standard installation with essential features
    full         Complete installation with all enhancements
    developer    Full installation plus development tools

EXAMPLES:
    # Standard installation
    ./install.sh
    
    # Force macOS installation with Homebrew dependencies
    ./install.sh --platform macos --profile full
    
    # Linux installation with minimal profile
    ./install.sh --platform linux --profile minimal
    
    # Dry run to see what would be installed
    ./install.sh --dry-run --verbose

SUPPORTED PLATFORMS:
    macOS        macOS 10.15+ with Homebrew support
    Linux        Ubuntu 20.04+, CentOS 8+, Arch Linux
    Windows      WSL2, Git Bash, PowerShell

For more information, visit: ${HIVE_REPO}
EOF
}

# Main installation orchestrator
main() {
    show_banner
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Platform detection
    if [[ -z "$FORCE_PLATFORM" ]]; then
        detect_platform
    fi
    
    # Show installation plan
    log "Installation Plan:"
    info "  Platform: $PLATFORM ($DISTRO)"
    info "  Profile: $INSTALL_PROFILE"
    info "  Interactive: $INTERACTIVE_MODE"
    info "  Package Manager: $PACKAGE_MANAGER"
    echo ""
    
    # Confirm installation in interactive mode
    if [[ "$INTERACTIVE_MODE" == "true" && "$DRY_RUN" == "false" ]]; then
        echo -n "Proceed with The Hive installation? [Y/n]: "
        read -r response
        if [[ "$response" =~ ^[Nn]$ ]]; then
            info "Installation cancelled by user"
            exit 0
        fi
    fi
    
    # Check prerequisites
    if [[ "$SKIP_DEPS" == "false" ]]; then
        if ! check_prerequisites; then
            if [[ "$DRY_RUN" == "true" ]]; then
                warning "DRY RUN: Would install missing prerequisites"
            else
                install_prerequisites || {
                    error "Failed to install prerequisites"
                    exit 1
                }
            fi
        fi
    fi
    
    # Download and execute platform-specific installer
    log "Executing platform-specific installation..."
    
    local platform_installer
    if platform_installer=$(download_installer "$PLATFORM"); then
        if [[ "$DRY_RUN" == "true" ]]; then
            warning "DRY RUN: Would execute platform installer: $platform_installer"
            warning "DRY RUN: Platform installer arguments: --profile $INSTALL_PROFILE --interactive $INTERACTIVE_MODE"
        else
            # Execute platform-specific installer
            "$platform_installer" \
                --profile "$INSTALL_PROFILE" \
                --$([ "$INTERACTIVE_MODE" == "true" ] && echo "interactive" || echo "non-interactive") \
                --package-manager "$PACKAGE_MANAGER" \
                --distro "$DISTRO"
            
            local exit_code=$?
            if [[ $exit_code -eq 0 ]]; then
                success "The Hive installation completed successfully!"
                echo ""
                log "🚀 Quick Start:"
                echo "  the-hive health              # Check system health"
                echo "  the-hive test \"task\"         # Test the system"
                echo "  /sc:orchestrate \"objective\"  # Use enhanced SuperClaude"
                echo ""
                log "📚 Documentation: ${HIVE_REPO}/docs"
                log "🐛 Issues: ${HIVE_REPO}/issues"
                echo ""
                success "Welcome to The Hive! 🐝"
            else
                error "Platform installer failed with exit code: $exit_code"
                exit $exit_code
            fi
        fi
    else
        error "Failed to download platform installer for: $PLATFORM"
        exit 1
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi