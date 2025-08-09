# 🐝 The Hive - Installation Guide

Complete installation instructions for The Hive SuperClaude Enhancement Suite across all supported platforms.

## 🚀 Quick Installation

### One-Command Install (All Platforms)
```bash
curl -L https://raw.githubusercontent.com/KHAEntertainment/the-hive/main/install.sh | bash
```

This single command:
- Detects your platform automatically  
- Installs missing dependencies
- Deploys The Hive enhancements
- Configures cross-tool integration
- Validates the installation

## 📋 System Requirements

### Minimum Requirements
- **Operating System**: macOS 10.15+, Linux (Ubuntu 20.04+, CentOS 8+, Arch), Windows (WSL2 recommended)
- **Memory**: 2GB RAM
- **Storage**: 500MB free space
- **Network**: Internet connection for initial setup

### Required Tools
- `bash` 4.0+ (macOS users: pre-installed bash 3.2 is compatible)
- `curl` for downloading components
- `git` for repository operations

### Optional but Recommended
- `jq` for JSON processing
- `node.js` 16+ and `npm` for Claude-Flow
- `python3` and `pip3` for SuperClaude Framework

## 🖥️ Platform-Specific Installation

### macOS Installation

#### Prerequisites
```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install essential tools
brew install curl git jq node python3
```

#### Installation Options
```bash
# Standard installation
./install.sh --platform macos

# Full installation with all enhancements
./install.sh --platform macos --profile full

# Minimal installation
./install.sh --platform macos --profile minimal --non-interactive
```

#### macOS-Specific Features
- ✅ Homebrew integration for dependency management
- ✅ Bash 3.2 compatibility (pre-installed macOS bash)
- ✅ Native macOS path handling
- ✅ Apple Silicon and Intel support

### Linux Installation

#### Ubuntu/Debian
```bash
# Update system and install dependencies
sudo apt update
sudo apt install -y curl git jq nodejs npm python3 python3-pip

# Install The Hive
./install.sh --platform linux
```

#### CentOS/RHEL/Fedora
```bash
# Install dependencies
sudo dnf install -y curl git jq nodejs npm python3 python3-pip
# or for older systems: sudo yum install -y curl git jq nodejs npm python3 python3-pip

# Install The Hive
./install.sh --platform linux --package-manager dnf
```

#### Arch Linux
```bash
# Install dependencies  
sudo pacman -S curl git jq nodejs npm python python-pip

# Install The Hive
./install.sh --platform linux --package-manager pacman
```

#### Linux-Specific Features
- ✅ Multi-distribution support (Ubuntu, Debian, CentOS, RHEL, Fedora, Arch)
- ✅ Automatic package manager detection
- ✅ Systemd service integration (optional)
- ✅ Permission handling for non-root users

### Windows Installation

#### WSL2 (Recommended)
```bash
# Ensure WSL2 is installed and updated
wsl --update

# Inside WSL2 Ubuntu
sudo apt update
sudo apt install -y curl git jq nodejs npm python3 python3-pip

# Install The Hive
./install.sh --platform windows --wsl2
```

#### Git Bash
```bash
# Ensure Git for Windows is installed with Git Bash
# Download from: https://git-scm.com/download/win

# In Git Bash
./install.sh --platform windows --git-bash
```

#### MSYS2
```bash
# Install dependencies in MSYS2
pacman -S curl git nodejs python

# Install The Hive
./install.sh --platform windows --msys2
```

#### Windows-Specific Features
- ✅ WSL2, Git Bash, and MSYS2 support
- ✅ Windows Terminal emoji support
- ✅ PowerShell integration (basic)
- ✅ Path handling for Windows environments

## 🔧 Installation Profiles

### Minimal Profile
**Best for**: Basic functionality, resource-constrained systems
```bash
./install.sh --profile minimal
```
**Includes**:
- Core Hive functionality
- Basic fallback system
- Essential CLI commands
- Minimal dependencies

### Default Profile (Recommended)
**Best for**: Most users, balanced feature set
```bash
./install.sh --profile default
```
**Includes**:
- Full Hive enhancement suite
- Intelligent fallback coordination
- All CLI commands
- Process transparency
- Cost management
- Persona validation

### Full Profile
**Best for**: Power users, complete feature set
```bash
./install.sh --profile full
```
**Includes**:
- Everything in Default
- Advanced GitHub integration
- Performance monitoring
- Enhanced debugging tools
- Extended testing framework

### Developer Profile
**Best for**: Contributors, testing, development
```bash
./install.sh --profile developer
```
**Includes**:
- Everything in Full
- Development tools (Docker, kubectl, etc.)
- Testing framework
- Debug logging
- Source code access

## ⚙️ Installation Options

### Interactive vs Non-Interactive
```bash
# Interactive installation (default) - prompts for confirmation
./install.sh --interactive

# Non-interactive installation - no prompts
./install.sh --non-interactive
```

### Dry Run Mode
```bash
# See what would be installed without making changes
./install.sh --dry-run --verbose
```

### Dependency Management
```bash
# Skip dependency installation (if already installed)
./install.sh --skip-deps

# Force specific package manager
./install.sh --package-manager brew  # macOS
./install.sh --package-manager apt   # Ubuntu/Debian
./install.sh --package-manager dnf   # Fedora/CentOS 8+
./install.sh --package-manager yum   # CentOS 7/RHEL 7
./install.sh --package-manager pacman # Arch Linux
```

## 🧪 Installation Testing

### Quick Validation
```bash
# Test installation immediately after setup
cd the-hive/testing
./hive-test-suite.sh --quick
```

### Comprehensive Testing
```bash
# Run full test suite
./hive-test-suite.sh --full

# Platform-specific tests
./hive-test-suite.sh --platform

# Performance testing
./hive-test-suite.sh --performance
```

## 🔍 Verifying Installation

### Check Installation Status
```bash
# Verify Hive CLI is available
the-hive status

# Check system health
the-hive health

# Show version information
the-hive --version
```

### Expected Output
```
The Hive v1.0.0 Status (macOS):
Home: /Users/username/.hive
Scripts: 6 enhancement scripts
Backup: None
```

### Test Basic Functionality
```bash
# Test the fallback system
the-hive test "Create a simple React component"

# Test collective intelligence
the-hive collective "Design a scalable API architecture"
```

## 🛠️ Post-Installation Configuration

### Configure API Keys (Optional)
```bash
# Set OpenRouter API key
export OPENROUTER_API_KEY="your-api-key-here"

# Set Gemini CLI API key  
export GEMINI_API_KEY="your-api-key-here"
```

### Customize Preferences
```bash
# Edit Hive preferences
nano ~/.hive/configs/preferences.json

# Or use the template
cp ~/.hive/configs/preferences-template.json ~/.hive/configs/preferences.json
```

### Enable Advanced Features
```bash
# Enable collective intelligence
the-hive collective --help

# Configure cost management
# Edit monthly limits in preferences.json
```

## 📁 Installation Locations

### Standard Locations
- **Hive Home**: `~/.hive/`
- **Scripts**: `~/.hive/scripts/`
- **Configs**: `~/.hive/configs/`
- **CLI Command**: `/usr/local/bin/the-hive` (macOS/Linux) or `~/.local/bin/the-hive`
- **Backups**: `~/.hive/backup/YYYYMMDD-HHMMSS/`

### Logs and Data
- **Session Data**: `~/.hive/sessions/`
- **Metrics**: `~/.hive/metrics/`
- **Test Results**: `~/.hive/testing/results/`

## 🚨 Troubleshooting Installation

### Common Issues

#### "Command not found: the-hive"
```bash
# Check if installed in local bin
ls -la ~/.local/bin/the-hive

# Add to PATH if needed
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

#### Permission Denied Errors
```bash
# Make sure scripts are executable
chmod +x ~/.hive/scripts/*.sh
chmod +x ~/.hive/bin/the-hive
```

#### Missing Dependencies
```bash
# Re-run installation with verbose output
./install.sh --verbose

# Install dependencies manually
# macOS: brew install curl git jq node python3
# Ubuntu: sudo apt install curl git jq nodejs npm python3 python3-pip
# CentOS: sudo dnf install curl git jq nodejs npm python3 python3-pip
```

#### WSL2 Issues (Windows)
```bash
# Update WSL2
wsl --update

# Check WSL version
wsl --list --verbose

# Ensure using WSL2 not WSL1
wsl --set-version Ubuntu 2
```

### Getting Help

If you encounter issues:

1. **Check the logs**: Installation logs are saved to `/tmp/hive-install.log`
2. **Run diagnostics**: `the-hive health` and `./hive-test-suite.sh --quick`
3. **Check documentation**: See [troubleshooting guide](troubleshooting.md)
4. **Report issues**: https://github.com/KHAEntertainment/the-hive/issues

## 🔄 Updating The Hive

### Check for Updates
```bash
# Check current version
the-hive --version

# Manual update (re-run installer)
curl -L https://raw.githubusercontent.com/KHAEntertainment/the-hive/main/install.sh | bash
```

### Backup Before Updates
The installer automatically creates backups, but you can also:
```bash
# Manual backup
cp -r ~/.hive ~/.hive-backup-$(date +%Y%m%d)

# Show current backup
the-hive backup
```

## 🗑️ Uninstalling The Hive

### Complete Removal
```bash
# Remove Hive directory
rm -rf ~/.hive

# Remove CLI command
sudo rm -f /usr/local/bin/the-hive
rm -f ~/.local/bin/the-hive

# Remove from PATH (edit ~/.bashrc manually)
```

### Restore Original Configurations
```bash
# If you have a backup from installation
the-hive rollback
```

---

## 🎉 Next Steps

After successful installation:

1. **Read the [User Guide](user-guide.md)** to learn about all features
2. **Try the [Quick Start Tutorial](../README.md#quick-start)** 
3. **Configure your [AI service preferences](user-guide.md#configuration)**
4. **Join the community** at https://github.com/KHAEntertainment/the-hive

Welcome to The Hive! 🐝