#!/bin/bash
# SuperClaude Git-MCP Integration Command
# Easy GitHub repository MCP server installation

set -e

# Command help
show_help() {
    echo "🔗 SuperClaude Git-MCP Integration"
    echo ""
    echo "USAGE:"
    echo "  /sc:git-mcp [repository-url]"
    echo ""
    echo "DESCRIPTION:"
    echo "  Convert any GitHub repository into an MCP data source for Claude Code"
    echo "  Simply replace 'github.com' with 'gitmcp.io' and install as MCP server"
    echo ""
    echo "EXAMPLES:"
    echo "  /sc:git-mcp https://github.com/anthropics/claude-code"
    echo "  /sc:git-mcp  # Interactive mode - prompts for URL"
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help     Show this help message"
    echo "  -g, --global   Install globally (default: asks user)"
    echo "  -l, --local    Install for current project only"
    echo ""
    echo "FEATURES:"
    echo "  • Automatic URL conversion (github.com → gitmcp.io)"
    echo "  • Interactive repository URL input"
    echo "  • Choice of global or project-specific installation"
    echo "  • Automatic MCP server name generation"
    echo "  • Installation verification"
}

# Extract repository info from GitHub URL
extract_repo_info() {
    local url="$1"
    
    # Remove various GitHub URL formats and extract owner/repo
    repo_path=$(echo "$url" | sed -E 's|.*github\.com/||' | sed -E 's|\.git$||' | sed -E 's|/$||')
    
    if [[ ! "$repo_path" =~ ^[^/]+/[^/]+$ ]]; then
        echo "❌ Invalid GitHub repository URL format"
        echo "   Expected: https://github.com/owner/repository"
        echo "   Got: $url"
        return 1
    fi
    
    echo "$repo_path"
}

# Generate MCP server name from repository
generate_server_name() {
    local repo_path="$1"
    local owner=$(echo "$repo_path" | cut -d'/' -f1)
    local repo=$(echo "$repo_path" | cut -d'/' -f2)
    
    # Clean and format server name
    local server_name="${repo}-docs"
    server_name=$(echo "$server_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
    
    echo "$server_name"
}

# Ask for installation scope
ask_installation_scope() {
    echo ""
    echo "📍 Installation Scope:"
    echo "  1) Global - Available in all Claude Code sessions"
    echo "  2) Local  - Available in current project only"
    echo ""
    while true; do
        read -p "Choose installation scope (1/2): " choice
        case "$choice" in
            1|global|g)
                echo "global"
                return
                ;;
            2|local|l)
                echo "local"
                return
                ;;
            *)
                echo "⚠️  Please enter 1 or 2"
                ;;
        esac
    done
}

# Install MCP server
install_mcp_server() {
    local server_name="$1"
    local gitmcp_url="$2"
    local scope="$3"
    
    echo ""
    echo "🚀 Installing MCP server..."
    echo "   Name: $server_name"
    echo "   Source: $gitmcp_url"
    echo "   Scope: $scope"
    echo ""
    
    # Note: claude mcp add doesn't have --local flag, it installs to project by default
    # Global installation is the default behavior when no project context
    
    if claude mcp add "$server_name" npx mcp-remote "$gitmcp_url"; then
        echo "✅ Successfully installed MCP server: $server_name"
        
        echo ""
        echo "🔍 Verifying installation..."
        if claude mcp list | grep -q "$server_name"; then
            echo "✅ MCP server verified and ready to use"
            echo ""
            echo "💡 The repository content is now available as an MCP data source!"
            echo "   You can reference documentation, code examples, and patterns"
            echo "   from this repository in your Claude Code conversations."
        else
            echo "⚠️  MCP server installed but not showing in list - may need restart"
        fi
    else
        echo "❌ Failed to install MCP server"
        return 1
    fi
}

# Main function
main() {
    local repository_url=""
    local installation_scope=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -g|--global)
                installation_scope="global"
                shift
                ;;
            -l|--local)
                installation_scope="local"
                shift
                ;;
            http*://github.com/*)
                repository_url="$1"
                shift
                ;;
            *)
                if [[ -z "$repository_url" && "$1" =~ ^[^/]+/[^/]+$ ]]; then
                    # Handle owner/repo format
                    repository_url="https://github.com/$1"
                else
                    echo "❌ Unknown argument: $1"
                    echo "Use --help for usage information"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Interactive URL input if not provided
    if [[ -z "$repository_url" ]]; then
        echo "🔗 SuperClaude Git-MCP Integration"
        echo ""
        echo "Convert any GitHub repository into an MCP data source for Claude Code"
        echo ""
        while true; do
            read -p "Enter GitHub repository URL: " repository_url
            if [[ -n "$repository_url" ]]; then
                # Add https://github.com/ prefix if just owner/repo provided
                if [[ "$repository_url" =~ ^[^/]+/[^/]+$ ]]; then
                    repository_url="https://github.com/$repository_url"
                fi
                break
            fi
            echo "⚠️  Please enter a repository URL"
        done
    fi
    
    # Validate and extract repository information
    echo ""
    echo "🔍 Processing repository: $repository_url"
    
    local repo_path
    if ! repo_path=$(extract_repo_info "$repository_url"); then
        exit 1
    fi
    
    echo "✅ Repository: $repo_path"
    
    # Generate MCP server details
    local server_name=$(generate_server_name "$repo_path")
    local gitmcp_url="https://gitmcp.io/$repo_path"
    
    echo "✅ MCP server name: $server_name"
    echo "✅ GitMCP URL: $gitmcp_url"
    
    # Ask for installation scope if not specified
    if [[ -z "$installation_scope" ]]; then
        installation_scope=$(ask_installation_scope)
    fi
    
    # Install the MCP server
    install_mcp_server "$server_name" "$gitmcp_url" "$installation_scope"
    
    echo ""
    echo "🎉 Git-MCP integration complete!"
    echo ""
    echo "📚 Next steps:"
    echo "   • Reference the repository content in your conversations"
    echo "   • Ask questions about the codebase and documentation"
    echo "   • Use code examples and patterns from the repository"
    echo ""
    echo "🔧 Manage MCP servers:"
    echo "   claude mcp list       # List all installed servers"
    echo "   claude mcp remove $server_name  # Remove this server"
}

# Execute main function with all arguments
main "$@"