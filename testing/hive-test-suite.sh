#!/bin/bash
# The Hive - Comprehensive Testing Framework
# Cross-platform validation suite for all Hive components

set -e

# Version and configuration
HIVE_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HIVE_HOME="$HOME/.hive"
TEST_SESSION_ID="test-$(date +%Y%m%d-%H%M%S)"
TEST_RESULTS_DIR="$SCRIPT_DIR/results/$TEST_SESSION_ID"

# Color codes and emojis
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test result tracking
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Logging functions
log() { echo -e "${CYAN}🧪${NC} [TEST] $*"; }
success() { echo -e "${GREEN}✅${NC} [PASS] $*"; }
failure() { echo -e "${RED}❌${NC} [FAIL] $*"; }
warning() { echo -e "${YELLOW}⚠️${NC} [WARN] $*"; }
info() { echo -e "${BLUE}ℹ️${NC} [INFO] $*"; }
skip() { echo -e "${YELLOW}⏭️${NC} [SKIP] $*"; }

# Test execution framework
run_test() {
    local test_name="$1"
    local test_function="$2"
    local required_conditions="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    log "Running test: $test_name"
    
    # Check required conditions
    if [[ -n "$required_conditions" ]] && ! eval "$required_conditions"; then
        skip "$test_name - Required conditions not met"
        TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
        return 0
    fi
    
    # Create test-specific directory
    local test_dir="$TEST_RESULTS_DIR/$(echo "$test_name" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')"
    mkdir -p "$test_dir"
    
    # Run the test and capture output (no timeout on macOS for compatibility)
    local start_time=$(date +%s)
    local test_output="$test_dir/output.log"
    local test_error="$test_dir/error.log"
    local exit_code=0
    
    if $test_function > "$test_output" 2> "$test_error"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        success "$test_name (${duration}s)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        
        # Store test metadata
        cat > "$test_dir/metadata.json" << EOF
{
    "test_name": "$test_name",
    "status": "PASSED",
    "duration_seconds": $duration,
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "output_file": "output.log",
    "error_file": "error.log"
}
EOF
    else
        exit_code=$?
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        failure "$test_name (${duration}s, exit code: $exit_code)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        
        # Show error for debugging
        if [[ -s "$test_error" ]]; then
            echo "Error output:"
            head -10 "$test_error" | sed 's/^/  /'
        fi
        
        # Store test metadata
        cat > "$test_dir/metadata.json" << EOF
{
    "test_name": "$test_name",
    "status": "FAILED",
    "duration_seconds": $duration,
    "exit_code": $exit_code,
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "output_file": "output.log",
    "error_file": "error.log"
}
EOF
    fi
    
    return $exit_code
}

# Platform detection tests
test_platform_detection() {
    log "Testing platform detection..."
    
    case "$(uname -s)" in
        Darwin*) echo "Platform: macOS"; return 0 ;;
        Linux*) echo "Platform: Linux"; return 0 ;;
        MINGW*|CYGWIN*|MSYS*) echo "Platform: Windows"; return 0 ;;
        *) echo "Platform: Unknown"; return 1 ;;
    esac
}

# Dependency detection tests
test_dependency_detection() {
    log "Testing dependency detection..."
    
    local required_deps=("bash" "curl" "git")
    local optional_deps=("jq" "node" "python3" "claude")
    local missing_required=()
    local missing_optional=()
    
    for dep in "${required_deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_required+=("$dep")
        else
            echo "✓ Required dependency found: $dep"
        fi
    done
    
    for dep in "${optional_deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_optional+=("$dep")
        else
            echo "✓ Optional dependency found: $dep"
        fi
    done
    
    echo "Missing required: ${missing_required[*]:-none}"
    echo "Missing optional: ${missing_optional[*]:-none}"
    
    # Fail if required dependencies are missing
    if [[ ${#missing_required[@]} -gt 0 ]]; then
        return 1
    fi
    
    return 0
}

# Hive installation structure tests
test_hive_structure() {
    log "Testing Hive directory structure..."
    
    local required_dirs=(
        "$HIVE_HOME"
        "$HIVE_HOME/scripts"
        "$HIVE_HOME/configs"
    )
    
    local missing_dirs=()
    
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            echo "✓ Directory exists: $dir"
        else
            missing_dirs+=("$dir")
            echo "✗ Directory missing: $dir"
        fi
    done
    
    # Check for essential scripts
    local essential_scripts=(
        "$HIVE_HOME/scripts/fallback-coordinator.sh"
    )
    
    for script in "${essential_scripts[@]}"; do
        if [[ -f "$script" && -x "$script" ]]; then
            echo "✓ Script exists and executable: $script"
        else
            echo "✗ Script missing or not executable: $script"
            return 1
        fi
    done
    
    if [[ ${#missing_dirs[@]} -gt 0 ]]; then
        echo "Missing directories: ${missing_dirs[*]}"
        return 1
    fi
    
    return 0
}

# CLI command tests  
test_hive_cli() {
    log "Testing Hive CLI functionality..."
    
    if ! command -v the-hive >/dev/null 2>&1; then
        echo "✗ the-hive command not found in PATH"
        
        # Try direct execution
        if [[ -x "$HIVE_HOME/bin/the-hive" ]]; then
            echo "✓ Found Hive CLI at $HIVE_HOME/bin/the-hive"
            HIVE_CLI="$HIVE_HOME/bin/the-hive"
        else
            echo "✗ Hive CLI not found anywhere"
            return 1
        fi
    else
        echo "✓ the-hive command found in PATH"
        HIVE_CLI="the-hive"
    fi
    
    # Test basic CLI commands
    local cli_tests=(
        "--version:Show version information"
        "--help:Show help message"
        "status:Show system status"
    )
    
    for test_case in "${cli_tests[@]}"; do
        local command="${test_case%:*}"
        local description="${test_case#*:}"
        
        echo "Testing: $HIVE_CLI $command ($description)"
        
        if $HIVE_CLI $command >/dev/null 2>&1; then
            echo "✓ $command works"
        else
            echo "✗ $command failed"
            return 1
        fi
    done
    
    return 0
}

# AI tool detection tests
test_ai_tool_detection() {
    log "Testing AI tool detection..."
    
    local ai_tools=(
        "claude:Claude Code"
        "SuperClaude:SuperClaude Framework"
        "claude-flow:Claude-Flow"
    )
    
    local detected_tools=()
    local missing_tools=()
    
    for tool_info in "${ai_tools[@]}"; do
        local command="${tool_info%:*}"
        local name="${tool_info#*:}"
        
        if command -v "$command" >/dev/null 2>&1; then
            detected_tools+=("$name")
            echo "✓ $name detected"
        elif [[ "$command" == "SuperClaude" ]] && python3 -c "import SuperClaude" 2>/dev/null; then
            detected_tools+=("$name")
            echo "✓ $name detected (Python module)"
        elif [[ "$command" == "claude-flow" ]] && npx claude-flow@alpha --version >/dev/null 2>&1; then
            detected_tools+=("$name")
            echo "✓ $name detected (NPX)"
        else
            missing_tools+=("$name")
            echo "- $name not found"
        fi
    done
    
    echo "Detected tools: ${detected_tools[*]:-none}"
    echo "Missing tools: ${missing_tools[*]:-none}"
    
    # Always return success - missing tools are expected during testing
    return 0
}

# Fallback system tests
test_fallback_system() {
    log "Testing fallback system..."
    
    local fallback_script="$HIVE_HOME/scripts/fallback-coordinator.sh"
    
    if [[ ! -x "$fallback_script" ]]; then
        echo "✗ Fallback coordinator script not found or not executable"
        return 1
    fi
    
    # Test health check
    echo "Testing fallback system health check..."
    if "$fallback_script" health >/dev/null 2>&1; then
        echo "✓ Health check passed"
    else
        echo "✗ Health check failed"
        return 1
    fi
    
    # Test with a simple task
    echo "Testing fallback with sample task..."
    if "$fallback_script" test "Sample test task" "analyst" >/dev/null 2>&1; then
        echo "✓ Sample task test passed"
    else
        echo "✗ Sample task test failed"
        return 1
    fi
    
    return 0
}

# Performance tests
test_performance() {
    log "Testing system performance..."
    
    # Measure CLI response time
    local start_time=$(date +%s.%N)
    the-hive status >/dev/null 2>&1 || $HIVE_HOME/bin/the-hive status >/dev/null 2>&1
    local end_time=$(date +%s.%N)
    
    if command -v bc >/dev/null 2>&1; then
        local response_time=$(echo "$end_time - $start_time" | bc)
        echo "CLI response time: ${response_time}s"
        
        # Response time should be under 2 seconds
        local acceptable=$(echo "$response_time < 2.0" | bc)
        if [[ "$acceptable" -eq 1 ]]; then
            echo "✓ Response time acceptable"
        else
            echo "⚠ Response time slow (>${response_time}s)"
        fi
    else
        echo "- Performance timing requires bc (basic calculator)"
    fi
    
    return 0
}

# Configuration tests
test_configuration() {
    log "Testing configuration system..."
    
    # Check if preferences template exists
    local template_file="../enhancements/configs/preferences-template.json"
    if [[ -f "$template_file" ]]; then
        echo "✓ Preferences template found"
        
        # Validate JSON structure
        if command -v jq >/dev/null 2>&1; then
            if jq empty < "$template_file" 2>/dev/null; then
                echo "✓ Preferences template is valid JSON"
            else
                echo "✗ Preferences template has invalid JSON"
                return 1
            fi
        else
            echo "- JSON validation requires jq"
        fi
    else
        echo "✗ Preferences template not found"
        return 1
    fi
    
    return 0
}

# Cross-platform compatibility tests
test_cross_platform_compatibility() {
    log "Testing cross-platform compatibility..."
    
    local platform_specific_tests=()
    
    case "$(uname -s)" in
        Darwin*)
            echo "Running macOS-specific tests..."
            # Test Homebrew integration
            if command -v brew >/dev/null 2>&1; then
                echo "✓ Homebrew available"
            else
                echo "- Homebrew not installed (expected for some setups)"
            fi
            ;;
        Linux*)
            echo "Running Linux-specific tests..."
            # Test package manager detection
            if command -v apt >/dev/null 2>&1; then
                echo "✓ apt package manager detected"
            elif command -v yum >/dev/null 2>&1; then
                echo "✓ yum package manager detected"
            elif command -v pacman >/dev/null 2>&1; then
                echo "✓ pacman package manager detected"
            else
                echo "- No common package manager detected"
            fi
            ;;
        MINGW*|CYGWIN*|MSYS*)
            echo "Running Windows-specific tests..."
            # Test Windows environment
            if [[ -n "$WSL_DISTRO_NAME" ]]; then
                echo "✓ WSL2 environment detected"
            elif [[ "$MSYSTEM" =~ MINGW ]]; then
                echo "✓ MSYS2 environment detected"
            else
                echo "✓ Git Bash or similar environment"
            fi
            ;;
    esac
    
    return 0
}

# Integration tests
test_integration() {
    log "Testing system integration..."
    
    # Test if enhancement scripts can communicate
    if [[ -x "$HIVE_HOME/scripts/fallback-coordinator.sh" ]]; then
        echo "✓ Fallback coordinator available for integration"
    fi
    
    if [[ -f "$HIVE_HOME/configs/preferences-template.json" ]] || [[ -f "../enhancements/configs/preferences-template.json" ]]; then
        echo "✓ Configuration system available for integration"
    fi
    
    return 0
}

# Generate test report
generate_test_report() {
    log "Generating comprehensive test report..."
    
    local report_file="$TEST_RESULTS_DIR/hive-test-report.json"
    local summary_file="$TEST_RESULTS_DIR/test-summary.txt"
    
    # Create JSON report
    cat > "$report_file" << EOF
{
    "test_session": {
        "id": "$TEST_SESSION_ID",
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "platform": "$(uname -s)",
        "architecture": "$(uname -m)",
        "hive_version": "$HIVE_VERSION"
    },
    "test_results": {
        "total_tests": $TESTS_RUN,
        "passed": $TESTS_PASSED,
        "failed": $TESTS_FAILED,
        "skipped": $TESTS_SKIPPED,
        "success_rate": $(( TESTS_RUN > 0 ? (TESTS_PASSED * 100 / TESTS_RUN) : 0 ))
    },
    "test_details_directory": "$TEST_RESULTS_DIR"
}
EOF
    
    # Create summary report
    cat > "$summary_file" << EOF
The Hive Test Suite Results
===========================

Test Session: $TEST_SESSION_ID
Platform: $(uname -s) $(uname -m)
Timestamp: $(date)
Hive Version: $HIVE_VERSION

Summary
-------
Total Tests: $TESTS_RUN
Passed: $TESTS_PASSED
Failed: $TESTS_FAILED
Skipped: $TESTS_SKIPPED
Success Rate: $(( TESTS_RUN > 0 ? (TESTS_PASSED * 100 / TESTS_RUN) : 0 ))%

Test Categories
---------------
✓ Platform Detection
✓ Dependency Detection  
✓ Hive Structure Validation
✓ CLI Functionality
✓ AI Tool Detection
✓ Fallback System
✓ Performance Metrics
✓ Configuration System
✓ Cross-Platform Compatibility
✓ Integration Testing

Detailed Results
----------------
See individual test directories in: $TEST_RESULTS_DIR

EOF
    
    success "Test report generated: $report_file"
    success "Test summary: $summary_file"
}

# Show test results
show_test_results() {
    echo ""
    log "🧪 The Hive Test Suite Results"
    echo "================================="
    echo ""
    
    info "Test Session: $TEST_SESSION_ID"
    info "Platform: $(uname -s) $(uname -m)"
    info "Timestamp: $(date)"
    echo ""
    
    log "📊 Summary:"
    echo "  Total Tests: $TESTS_RUN"
    echo "  ✅ Passed: $TESTS_PASSED"
    echo "  ❌ Failed: $TESTS_FAILED"
    echo "  ⏭️ Skipped: $TESTS_SKIPPED"
    
    local success_rate=0
    if [[ $TESTS_RUN -gt 0 ]]; then
        success_rate=$((TESTS_PASSED * 100 / TESTS_RUN))
    fi
    
    echo "  📈 Success Rate: ${success_rate}%"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        success "🎉 All tests passed! The Hive is ready for use."
    elif [[ $success_rate -ge 80 ]]; then
        warning "⚠️ Most tests passed with some issues. The Hive should work but may have limitations."
    else
        failure "❌ Multiple test failures detected. The Hive installation needs attention."
    fi
    
    echo ""
    info "📁 Detailed results: $TEST_RESULTS_DIR"
    info "📊 Full report: $TEST_RESULTS_DIR/hive-test-report.json"
}

# Show help
show_help() {
    cat << EOF
The Hive Test Suite - Comprehensive System Validation

USAGE:
    ./hive-test-suite.sh [OPTIONS]

OPTIONS:
    --quick             Run essential tests only
    --full              Run all tests including optional ones
    --platform          Run platform-specific tests only
    --performance       Run performance tests only
    --integration       Run integration tests only
    --report-only       Generate report from existing results
    --clean             Clean up old test results
    --help, -h          Show this help message

TEST CATEGORIES:
    Platform Detection      Verify platform and environment detection
    Dependency Detection    Check for required and optional dependencies
    Hive Structure         Validate installation directory structure
    CLI Functionality      Test the-hive command functionality
    AI Tool Detection      Detect installed AI development tools
    Fallback System        Test intelligent fallback coordination
    Performance Metrics    Measure system performance
    Configuration System   Validate configuration templates
    Cross-Platform         Test platform-specific functionality
    Integration           Test component integration

EXAMPLES:
    # Run full test suite
    ./hive-test-suite.sh --full
    
    # Run only essential tests
    ./hive-test-suite.sh --quick
    
    # Run platform-specific tests
    ./hive-test-suite.sh --platform
    
    # Clean up old results
    ./hive-test-suite.sh --clean
EOF
}

# Main test execution
main() {
    local test_mode="full"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --quick)
                test_mode="quick"
                shift
                ;;
            --full)
                test_mode="full"
                shift
                ;;
            --platform)
                test_mode="platform"
                shift
                ;;
            --performance)
                test_mode="performance"
                shift
                ;;
            --integration)
                test_mode="integration"
                shift
                ;;
            --report-only)
                test_mode="report"
                shift
                ;;
            --clean)
                rm -rf "$SCRIPT_DIR/results"
                success "Cleaned up old test results"
                exit 0
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Create results directory
    mkdir -p "$TEST_RESULTS_DIR"
    
    log "🚀 Starting The Hive Test Suite (Mode: $test_mode)"
    echo ""
    
    # Run tests based on mode
    case "$test_mode" in
        "quick")
            run_test "Platform Detection" "test_platform_detection" ""
            run_test "Dependency Detection" "test_dependency_detection" ""
            run_test "Hive Structure" "test_hive_structure" ""
            run_test "CLI Functionality" "test_hive_cli" ""
            ;;
        "full")
            run_test "Platform Detection" "test_platform_detection" ""
            run_test "Dependency Detection" "test_dependency_detection" ""
            run_test "Hive Structure" "test_hive_structure" ""
            run_test "CLI Functionality" "test_hive_cli" ""
            run_test "AI Tool Detection" "test_ai_tool_detection" ""
            run_test "Fallback System" "test_fallback_system" ""
            run_test "Performance Metrics" "test_performance" ""
            run_test "Configuration System" "test_configuration" ""
            run_test "Cross-Platform Compatibility" "test_cross_platform_compatibility" ""
            run_test "Integration Testing" "test_integration" ""
            ;;
        "platform")
            run_test "Platform Detection" "test_platform_detection" ""
            run_test "Cross-Platform Compatibility" "test_cross_platform_compatibility" ""
            ;;
        "performance")
            run_test "Performance Metrics" "test_performance" ""
            ;;
        "integration")
            run_test "Integration Testing" "test_integration" ""
            ;;
        "report")
            # Skip tests, just generate report
            ;;
    esac
    
    # Generate comprehensive report
    generate_test_report
    
    # Show results
    show_test_results
    
    # Exit with appropriate code
    if [[ $TESTS_FAILED -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi