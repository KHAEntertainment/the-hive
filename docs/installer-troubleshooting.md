# The Hive Installer Troubleshooting Guide

## Issue Analysis: Ubuntu SSH Silent Installation

**Problem**: The one-line installer runs but produces no output on Ubuntu via SSH, creating confusion about installation status.

**Root Cause**: Bug in `download_installer()` function where log messages were being captured by command substitution instead of going to stderr.

## Fixed Issue (August 10, 2025)

### Bug Description
The `download_installer()` function in `install.sh` was outputting log messages to stdout, which were then captured by command substitution:

```bash
# This captured log output instead of just the file path
platform_installer=$(download_installer "$PLATFORM")
```

### Fix Applied
Redirected log output to stderr so only the file path is returned:

```bash
log "Downloading $platform_installer installer..." >&2
success "Downloaded $platform_installer installer" >&2
```

## Testing The Fix

### Before Fix
```bash
$ platform_installer=$(download_installer "linux")
$ echo "$platform_installer" 
🐝 Downloading linux installer...
✅ Downloaded linux installer
/tmp/hive-linux-installer.sh
```

### After Fix
```bash
$ platform_installer=$(download_installer "linux")
🐝 Downloading linux installer...  # Goes to stderr (visible)
✅ Downloaded linux installer       # Goes to stderr (visible)
$ echo "$platform_installer"
/tmp/hive-linux-installer.sh       # Only file path captured
```

## Ubuntu Installation Verification

### Expected Installation Flow
1. **Banner Display**: ASCII art Hive logo should appear
2. **Platform Detection**: "Platform detected: linux (ubuntu)"
3. **Prerequisites Check**: Install curl, git, jq if missing
4. **Platform Installer Download**: Download linux-installer.sh
5. **Installation Execution**: Run platform-specific installer
6. **Success Message**: "The Hive installation completed successfully!"

### Troubleshooting Steps

#### 1. Check Installation Status
```bash
# After running installer, verify installation
which claude
ls ~/.hive
cat ~/.hive/config.json
```

#### 2. Manual Installation Verification
```bash
# Download and run with verbose output
curl -L https://raw.githubusercontent.com/KHAEntertainment/the-hive/main/install.sh > hive-install.sh
chmod +x hive-install.sh
./hive-install.sh --verbose --dry-run  # Test first
./hive-install.sh --verbose            # Actual install
```

#### 3. Check Prerequisites
```bash
# Verify required tools are available
curl --version
git --version
jq --version
```

#### 4. Platform-Specific Issues

**Ubuntu/Debian**:
- Ensure `sudo` access for package installation
- Check if running as root (may affect HOME directory setup)

**SSH Environments**:
- Terminal may not support emojis (installer handles this)
- Check TERM variable: `echo $TERM`

#### 5. Common Issues

**Silent Installation**:
- Usually indicates successful installation with no errors
- Verify by checking for installed components

**Permission Errors**:
```bash
# Run with explicit sudo if needed
curl -L https://raw.githubusercontent.com/KHAEntertainment/the-hive/main/install.sh | sudo bash
```

**Network Issues**:
```bash
# Test connectivity to GitHub
curl -I https://raw.githubusercontent.com/KHAEntertainment/the-hive/main/install.sh
```

## Installation Verification Commands

### Quick Health Check
```bash
# These commands should work after successful installation
the-hive health              # Check system health
the-hive test "simple task"  # Test the system
/sc:orchestrate "test"       # Test enhanced SuperClaude
```

### Manual Verification
```bash
# Check installation directory
ls -la ~/.hive/
ls -la ~/.hive/bin/
ls -la ~/.hive/scripts/

# Check Claude Code integration
claude --help
claude mcp list

# Check SuperClaude enhancements
ls -la ~/.claude/commands/sc/
```

## Contact & Support

- **Repository**: https://github.com/KHAEntertainment/the-hive
- **Issues**: https://github.com/KHAEntertainment/the-hive/issues
- **Documentation**: https://github.com/KHAEntertainment/the-hive/docs

## Version History

- **v1.0.0 (August 10, 2025)**: Fixed installer bug with command substitution capturing log output
- **v1.0.0 (Initial)**: First release with cross-platform support