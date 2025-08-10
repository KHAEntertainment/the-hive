#!/bin/bash
# SuperClaude FastAPI MCP Optional Integration
# Conditional installation and management system

set -e

# Configuration
SCRIPT_VERSION="1.0.0"
FASTAPI_MCP_SERVER="fastapi-mcp-docs"
FASTAPI_MCP_URL="https://fastapi-docs.mcp.io"
CONFIG_DIR="$HOME/.hive"
CONFIG_FILE="$CONFIG_DIR/user_preferences.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Show help information
show_help() {
    cat << 'EOF'
🚀 SuperClaude FastAPI MCP Integration

DESCRIPTION:
  Optional integration system for enhanced FastAPI development capabilities.
  Provides advanced API patterns, security analysis, and performance optimization.

USAGE:
  /sc:api-dev --install                    # Install FastAPI MCP integration
  ./enhancements/scripts/sc-fastapi-mcp.sh [OPTIONS]

OPTIONS:
  --install, --setup        Install FastAPI MCP server and configure integration
  --uninstall, --remove     Remove FastAPI MCP server and disable integration
  --status, --check         Check installation status and health
  --enable                  Enable FastAPI MCP integration (if installed)
  --disable                 Disable FastAPI MCP integration temporarily
  --health                  Run health check on FastAPI MCP server
  --help, -h                Show this help message

FEATURES:
  • Advanced FastAPI routing patterns and optimizations
  • Security-first API development with best practices
  • Comprehensive testing strategies and fixtures
  • Enhanced OpenAPI documentation generation
  • Performance analysis and optimization recommendations
  • Graceful fallback to standard SuperClaude functionality

INTEGRATION:
  Commands enhanced when FastAPI MCP is available:
    /sc:build --api          # Enhanced API builds with FastAPI patterns
    /sc:implement --fastapi  # FastAPI-specific implementations
    /sc:analyze --api-docs   # Deep API documentation analysis
    /sc:improve --api-perf   # API performance optimization
    /sc:test --api           # FastAPI-specific testing patterns

FALLBACK:
  All commands work without FastAPI MCP installed, using:
  • Context7 for general API documentation patterns
  • Sequential for complex API architecture analysis
  • Native SuperClaude knowledge base
  • Basic recommendations with installation suggestions

EOF
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Claude Code is available
    if ! command -v claude &> /dev/null; then
        log_error "Claude Code is required but not found"
        log_info "Please install Claude Code first: https://claude.ai/code"
        exit 1
    fi
    
    # Check if jq is available for JSON processing
    if ! command -v jq &> /dev/null; then
        log_warning "jq not found - using basic JSON processing"
        JQ_AVAILABLE=false
    else
        JQ_AVAILABLE=true
    fi
    
    # Ensure config directory exists
    mkdir -p "$CONFIG_DIR"
    
    # Create config file if it doesn't exist
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_info "Creating user preferences config file"
        create_default_config
    fi
    
    log_success "Prerequisites checked"
}

# Create default configuration file
create_default_config() {
    cat > "$CONFIG_FILE" << 'EOF'
{
  "integrations": {
    "fastapi_mcp": {
      "enabled": false,
      "auto_activate": true,
      "installation_prompted": false,
      "last_health_check": null,
      "features": {
        "api_design": true,
        "documentation": true,
        "validation": true,
        "testing": true,
        "security": true,
        "performance": true
      },
      "fallback_preferences": {
        "use_context7": true,
        "use_sequential": true,
        "suggest_installation": true
      }
    }
  }
}
EOF
}

# Update configuration using jq or basic sed
update_config() {
    local key="$1"
    local value="$2"
    
    if [[ "$JQ_AVAILABLE" == "true" ]]; then
        # Use jq for robust JSON manipulation
        jq "$key = $value" "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    else
        # Basic sed-based approach for environments without jq
        log_warning "Using basic JSON editing - consider installing jq for better reliability"
        case "$key" in
            ".integrations.fastapi_mcp.enabled")
                sed -i 's/"enabled": [^,]*/"enabled": '"$value"'/' "$CONFIG_FILE"
                ;;
            ".integrations.fastapi_mcp.installation_prompted")
                sed -i 's/"installation_prompted": [^,]*/"installation_prompted": '"$value"'/' "$CONFIG_FILE"
                ;;
        esac
    fi
}

# Get configuration value
get_config() {
    local key="$1"
    
    if [[ "$JQ_AVAILABLE" == "true" ]]; then
        jq -r "$key" "$CONFIG_FILE" 2>/dev/null || echo "null"
    else
        # Basic extraction for environments without jq
        case "$key" in
            ".integrations.fastapi_mcp.enabled")
                grep -o '"enabled": [^,]*' "$CONFIG_FILE" | cut -d' ' -f2 | tr -d ',' || echo "false"
                ;;
            *)
                echo "null"
                ;;
        esac
    fi
}

# Check if FastAPI MCP is installed
is_fastapi_mcp_installed() {
    claude mcp list 2>/dev/null | grep -q "$FASTAPI_MCP_SERVER"
}

# Check FastAPI MCP server health
check_fastapi_mcp_health() {
    local timeout=5
    
    log_info "Checking FastAPI MCP server health..."
    
    if ! is_fastapi_mcp_installed; then
        log_error "FastAPI MCP server not installed"
        return 1
    fi
    
    # Test server connectivity with timeout
    if timeout "$timeout" claude mcp call "$FASTAPI_MCP_SERVER" health_check >/dev/null 2>&1; then
        log_success "FastAPI MCP server is healthy and responding"
        
        # Update last health check timestamp
        if [[ "$JQ_AVAILABLE" == "true" ]]; then
            update_config ".integrations.fastapi_mcp.last_health_check" "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
        fi
        
        return 0
    else
        log_warning "FastAPI MCP server not responding (timeout after ${timeout}s)"
        return 1
    fi
}

# Install FastAPI MCP server
install_fastapi_mcp() {
    log_info "Installing FastAPI MCP integration..."
    
    # Check if already installed
    if is_fastapi_mcp_installed; then
        log_warning "FastAPI MCP server already installed"
        
        # Run health check
        if check_fastapi_mcp_health; then
            log_info "FastAPI MCP integration is ready to use"
            return 0
        else
            log_warning "FastAPI MCP server installed but not healthy - reinstalling..."
            uninstall_fastapi_mcp_server
        fi
    fi
    
    # Install the MCP server
    log_info "Adding FastAPI MCP server to Claude Code..."
    if claude mcp add "$FASTAPI_MCP_SERVER" npx mcp-remote "$FASTAPI_MCP_URL"; then
        log_success "FastAPI MCP server installed successfully"
        
        # Verify installation
        log_info "Verifying installation..."
        if is_fastapi_mcp_installed; then
            log_success "FastAPI MCP server verified in MCP list"
            
            # Run health check
            sleep 2  # Give server time to initialize
            if check_fastapi_mcp_health; then
                # Update configuration
                update_config ".integrations.fastapi_mcp.enabled" "true"
                update_config ".integrations.fastapi_mcp.installation_prompted" "true"
                
                log_success "FastAPI MCP integration installed and configured"
                show_usage_examples
                return 0
            else
                log_warning "Server installed but health check failed"
                log_info "The server may need time to initialize - try running health check later"
                return 1
            fi
        else
            log_error "Installation verification failed"
            return 1
        fi
    else
        log_error "Failed to install FastAPI MCP server"
        log_info "This may be due to network issues or MCP server unavailability"
        return 1
    fi
}

# Uninstall FastAPI MCP server
uninstall_fastapi_mcp_server() {
    if is_fastapi_mcp_installed; then
        log_info "Removing FastAPI MCP server..."
        if claude mcp remove "$FASTAPI_MCP_SERVER"; then
            log_success "FastAPI MCP server removed"
        else
            log_error "Failed to remove FastAPI MCP server"
            return 1
        fi
    fi
}

# Uninstall FastAPI MCP integration
uninstall_fastapi_mcp() {
    log_info "Uninstalling FastAPI MCP integration..."
    
    # Remove MCP server
    uninstall_fastapi_mcp_server
    
    # Update configuration
    update_config ".integrations.fastapi_mcp.enabled" "false"
    
    log_success "FastAPI MCP integration uninstalled"
    log_info "SuperClaude will use standard fallback patterns for API development"
}

# Enable FastAPI MCP integration
enable_fastapi_mcp() {
    if ! is_fastapi_mcp_installed; then
        log_error "FastAPI MCP server not installed"
        log_info "Run with --install to install the server first"
        return 1
    fi
    
    update_config ".integrations.fastapi_mcp.enabled" "true"
    log_success "FastAPI MCP integration enabled"
}

# Disable FastAPI MCP integration
disable_fastapi_mcp() {
    update_config ".integrations.fastapi_mcp.enabled" "false"
    log_success "FastAPI MCP integration disabled"
    log_info "Commands will use standard SuperClaude patterns"
}

# Show installation status
show_status() {
    echo "🔍 FastAPI MCP Integration Status"
    echo "================================"
    echo
    
    # Check if server is installed
    if is_fastapi_mcp_installed; then
        log_success "FastAPI MCP server: Installed"
        
        # Check health
        if check_fastapi_mcp_health; then
            echo -e "   ${GREEN}Server Status: Healthy${NC}"
        else
            echo -e "   ${YELLOW}Server Status: Not responding${NC}"
        fi
    else
        log_error "FastAPI MCP server: Not installed"
    fi
    
    # Check configuration
    local enabled=$(get_config ".integrations.fastapi_mcp.enabled")
    if [[ "$enabled" == "true" ]]; then
        log_success "Integration: Enabled"
    else
        echo -e "${YELLOW}ℹ️  Integration: Disabled${NC}"
    fi
    
    # Show last health check
    local last_check=$(get_config ".integrations.fastapi_mcp.last_health_check")
    if [[ "$last_check" != "null" && "$last_check" != '""' ]]; then
        echo -e "${BLUE}ℹ️  Last Health Check: $last_check${NC}"
    fi
    
    echo
    echo "Enhanced Commands (when enabled):"
    echo "  /sc:build --api          # Enhanced API builds"
    echo "  /sc:implement --fastapi  # FastAPI implementations"
    echo "  /sc:analyze --api-docs   # API documentation analysis"
    echo "  /sc:improve --api-perf   # Performance optimization"
    echo "  /sc:test --api           # Testing strategies"
}

# Show usage examples
show_usage_examples() {
    echo
    log_success "FastAPI MCP Integration Ready!"
    echo
    echo "🎯 Enhanced Commands Available:"
    echo "   /sc:build --api                    # FastAPI-enhanced API builds"
    echo "   /sc:implement --fastapi           # Advanced FastAPI implementations"
    echo "   /sc:analyze --api-docs --security # Deep API security analysis"
    echo "   /sc:improve --api-perf --async    # Async performance optimization"
    echo "   /sc:test --api --fixtures         # Advanced testing with fixtures"
    echo
    echo "💡 These commands automatically use FastAPI MCP when available"
    echo "   and gracefully fall back to standard SuperClaude functionality"
    echo
    echo "🔧 Management Commands:"
    echo "   ./enhancements/scripts/sc-fastapi-mcp.sh --status   # Check status"
    echo "   ./enhancements/scripts/sc-fastapi-mcp.sh --health   # Health check"
    echo "   ./enhancements/scripts/sc-fastapi-mcp.sh --disable  # Temporarily disable"
    echo
}

# Prompt user for installation (if not already prompted)
prompt_installation_if_needed() {
    local already_prompted=$(get_config ".integrations.fastapi_mcp.installation_prompted")
    
    if [[ "$already_prompted" == "true" ]]; then
        return 0  # Already prompted, don't ask again
    fi
    
    echo
    echo "🚀 Enhanced FastAPI Development Available!"
    echo
    echo "FastAPI MCP provides advanced API development features:"
    echo "  • Optimized routing patterns and performance recommendations"
    echo "  • Advanced authentication and security patterns"
    echo "  • Comprehensive testing strategies with fixtures"
    echo "  • Enhanced OpenAPI documentation generation"
    echo "  • Real-time security analysis and validation"
    echo
    read -p "Would you like to install FastAPI MCP integration? (y/n): " choice
    
    # Mark as prompted regardless of choice
    update_config ".integrations.fastapi_mcp.installation_prompted" "true"
    
    case "$choice" in
        y|Y|yes|YES)
            install_fastapi_mcp
            ;;
        *)
            log_info "FastAPI MCP installation skipped"
            log_info "You can install later with: /sc:api-dev --install"
            ;;
    esac
}

# Main function
main() {
    local action=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --install|--setup)
                action="install"
                shift
                ;;
            --uninstall|--remove)
                action="uninstall"
                shift
                ;;
            --status|--check)
                action="status"
                shift
                ;;
            --enable)
                action="enable"
                shift
                ;;
            --disable)
                action="disable"
                shift
                ;;
            --health)
                action="health"
                shift
                ;;
            --prompt)
                action="prompt"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Default action is to show status
    if [[ -z "$action" ]]; then
        action="status"
    fi
    
    # Check prerequisites for most actions
    if [[ "$action" != "help" ]]; then
        check_prerequisites
    fi
    
    # Execute action
    case "$action" in
        install)
            install_fastapi_mcp
            ;;
        uninstall)
            uninstall_fastapi_mcp
            ;;
        status)
            show_status
            ;;
        enable)
            enable_fastapi_mcp
            ;;
        disable)
            disable_fastapi_mcp
            ;;
        health)
            check_fastapi_mcp_health
            ;;
        prompt)
            prompt_installation_if_needed
            ;;
        *)
            log_error "Unknown action: $action"
            exit 1
            ;;
    esac
}

# Handle the /sc:api-dev command pattern
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly
    main "$@"
elif [[ "$1" == "--install" ]]; then
    # Called as /sc:api-dev --install
    main --install
else
    # Called without arguments, show status
    main --status
fi