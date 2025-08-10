#!/bin/bash
# The Hive Installation Verification Script
# Use this to verify that The Hive was installed correctly

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

success() { echo -e "${GREEN}✅${NC} $*"; }
error() { echo -e "${RED}❌${NC} $*"; }
warning() { echo -e "${YELLOW}⚠️${NC} $*"; }
info() { echo -e "${BLUE}ℹ️${NC} $*"; }

echo "🐝 The Hive Installation Verification"
echo "===================================="
echo

# Check 1: Hive directory structure
info "Checking Hive directory structure..."
if [[ -d "$HOME/.hive" ]]; then
    success "Hive directory exists: $HOME/.hive"
    
    # List contents
    echo "   Contents:"
    ls -la "$HOME/.hive" 2>/dev/null | head -10 | sed 's/^/     /'
else
    error "Hive directory not found: $HOME/.hive"
fi
echo

# Check 2: Claude Code
info "Checking Claude Code installation..."
if command -v claude &> /dev/null; then
    success "Claude Code found: $(which claude)"
    claude --version 2>/dev/null | sed 's/^/     /' || echo "     Version check failed"
else
    warning "Claude Code not found in PATH"
    info "The Hive can install Claude Code or work with existing installations"
fi
echo

# Check 3: SuperClaude commands
info "Checking SuperClaude commands..."
if [[ -d "$HOME/.claude/commands/sc" ]]; then
    success "SuperClaude commands directory found"
    command_count=$(find "$HOME/.claude/commands/sc" -name "*.md" | wc -l)
    success "Found $command_count SuperClaude commands"
    
    # Show some examples
    echo "   Sample commands:"
    find "$HOME/.claude/commands/sc" -name "*.md" | head -5 | xargs basename | sed 's/\.md$//' | sed 's/^/     \/sc:/'
else
    warning "SuperClaude commands not found"
    info "Expected location: $HOME/.claude/commands/sc"
fi
echo

# Check 4: Essential tools
info "Checking essential tools..."
for tool in curl git jq; do
    if command -v $tool &> /dev/null; then
        success "$tool found: $(which $tool)"
    else
        error "$tool not found"
    fi
done
echo

# Check 5: Configuration files
info "Checking configuration files..."
config_files=(
    "$HOME/.hive/config.json"
    "$HOME/.claude/CLAUDE.md"
    "$HOME/.hive/preferences.json"
)

for config in "${config_files[@]}"; do
    if [[ -f "$config" ]]; then
        success "Config found: $(basename "$config")"
    else
        warning "Config missing: $(basename "$config")"
    fi
done
echo

# Check 6: Try basic functionality
info "Testing basic functionality..."

# Test Hive command if it exists
if command -v the-hive &> /dev/null; then
    if the-hive health &> /dev/null; then
        success "Hive health check passed"
    else
        warning "Hive health check failed"
    fi
else
    info "Hive command not found (may be normal for manual installations)"
fi

# Test Claude MCP if available
if command -v claude &> /dev/null; then
    if claude mcp list &> /dev/null; then
        mcp_count=$(claude mcp list 2>/dev/null | wc -l)
        success "Claude MCP working ($mcp_count servers configured)"
    else
        info "Claude MCP not configured (may be normal for fresh installations)"
    fi
fi

echo
echo "🎯 Installation Summary"
echo "======================"

# Count successes and issues
if [[ -d "$HOME/.hive" ]] && [[ -d "$HOME/.claude/commands/sc" ]]; then
    success "The Hive appears to be installed successfully!"
    echo
    info "Quick start commands:"
    echo "     the-hive health              # Check system health"
    echo "     /sc:orchestrate \"task\"       # Use enhanced SuperClaude"
    echo "     claude mcp list              # List MCP servers"
    echo
    info "Documentation: https://github.com/KHAEntertainment/the-hive/docs"
else
    warning "The Hive installation may be incomplete or failed"
    echo
    info "Try running the installer again:"
    echo "     curl -L https://raw.githubusercontent.com/KHAEntertainment/the-hive/main/install.sh | bash"
    echo
    info "Or check the troubleshooting guide:"
    echo "     https://github.com/KHAEntertainment/the-hive/docs/installer-troubleshooting.md"
fi

echo
echo "🐝 Welcome to The Hive!"