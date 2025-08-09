#!/bin/bash
# SuperClaude Cost Management and Usage Tracking System
# Real-time cost monitoring, budget enforcement, and intelligent spending optimization

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_PATH="/Users/bbrenner/Documents/Scripting Projects/thehive"
SUPERCLAUDE_DIR="$WORKSPACE_PATH/.superclaude"
PREFERENCES_FILE="$SUPERCLAUDE_DIR/preferences.json"
USAGE_DB="$SUPERCLAUDE_DIR/usage/cost_tracking.db"
FALLBACK_COORDINATOR="$SCRIPT_DIR/fallback-coordinator.sh"

# Initialize cost tracking database
init_usage_database() {
    mkdir -p "$SUPERCLAUDE_DIR/usage"
    
    if ! command -v sqlite3 >/dev/null 2>&1; then
        echo "⚠️ Warning: sqlite3 not available, using JSON fallback for cost tracking"
        return 1
    fi
    
    # Create database schema if it doesn't exist
    sqlite3 "$USAGE_DB" << 'EOF'
CREATE TABLE IF NOT EXISTS usage_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    service TEXT NOT NULL,
    model TEXT,
    operation TEXT NOT NULL,
    input_tokens INTEGER DEFAULT 0,
    output_tokens INTEGER DEFAULT 0,
    total_tokens INTEGER DEFAULT 0,
    estimated_cost_usd REAL DEFAULT 0.0,
    actual_cost_usd REAL DEFAULT 0.0,
    timestamp TEXT NOT NULL,
    success BOOLEAN DEFAULT 1,
    metadata TEXT
);

CREATE TABLE IF NOT EXISTS budget_tracking (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    month TEXT NOT NULL,
    service TEXT NOT NULL,
    budgeted_amount_usd REAL NOT NULL,
    spent_amount_usd REAL DEFAULT 0.0,
    remaining_amount_usd REAL DEFAULT 0.0,
    alert_threshold_percent INTEGER DEFAULT 80,
    alerts_sent INTEGER DEFAULT 0,
    last_updated TEXT NOT NULL,
    UNIQUE(month, service)
);

CREATE TABLE IF NOT EXISTS cost_alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    alert_type TEXT NOT NULL,
    service TEXT NOT NULL,
    threshold_percent INTEGER,
    current_usage_usd REAL,
    budget_limit_usd REAL,
    message TEXT,
    timestamp TEXT NOT NULL,
    acknowledged BOOLEAN DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_usage_timestamp ON usage_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_usage_service ON usage_log(service);
CREATE INDEX IF NOT EXISTS idx_budget_month ON budget_tracking(month);
CREATE INDEX IF NOT EXISTS idx_alerts_timestamp ON cost_alerts(timestamp);
EOF
    
    echo "✅ Usage tracking database initialized: $USAGE_DB"
    return 0
}

# Load cost management preferences
load_cost_preferences() {
    local prefs_file="$1"
    
    if [[ -f "$prefs_file" ]] && command -v jq >/dev/null 2>&1; then
        # Budget settings
        MONTHLY_CEILING=$(jq -r '.user_preferences.cost_management.monthly_ceiling_usd // 50.0' "$prefs_file" 2>/dev/null)
        ALERT_THRESHOLD=$(jq -r '.user_preferences.cost_management.alert_threshold_percentage // 80' "$prefs_file" 2>/dev/null)
        DAILY_LIMIT=$(jq -r '.user_preferences.cost_management.daily_limit_usd // 5.0' "$prefs_file" 2>/dev/null)
        EMERGENCY_STOP_THRESHOLD=$(jq -r '.user_preferences.cost_management.emergency_stop_threshold_percentage // 95' "$prefs_file" 2>/dev/null)
        
        # Service-specific budgets
        OPENROUTER_BUDGET=$(jq -r '.user_preferences.cost_management.service_budgets.openrouter_usd // 30.0' "$prefs_file" 2>/dev/null)
        GEMINI_BUDGET=$(jq -r '.user_preferences.cost_management.service_budgets.gemini_usd // 10.0' "$prefs_file" 2>/dev/null)
        
        # Cost optimization settings
        AUTO_FALLBACK_ON_BUDGET=$(jq -r '.user_preferences.cost_management.auto_fallback_on_budget // true' "$prefs_file" 2>/dev/null)
        PREFER_FREE_MODELS=$(jq -r '.user_preferences.model_selection.openrouter.prefer_free_models // true' "$prefs_file" 2>/dev/null)
        COST_TRACKING_ENABLED=$(jq -r '.user_preferences.cost_management.tracking_enabled // true' "$prefs_file" 2>/dev/null)
    else
        # Default values
        MONTHLY_CEILING="50.0"
        ALERT_THRESHOLD="80"
        DAILY_LIMIT="5.0"
        EMERGENCY_STOP_THRESHOLD="95"
        OPENROUTER_BUDGET="30.0"
        GEMINI_BUDGET="10.0"
        AUTO_FALLBACK_ON_BUDGET="true"
        PREFER_FREE_MODELS="true"
        COST_TRACKING_ENABLED="true"
    fi
}

# Initialize cost management system
load_cost_preferences "$PREFERENCES_FILE"
init_usage_database

# Calculate current month string
CURRENT_MONTH=$(date +%Y-%m)

# Model pricing function (compatible with macOS bash 3.2)
get_model_price() {
    local model="$1"
    case "$model" in
        "openrouter/horizon-beta:free"|"openai/gpt-oss-20b:free"|"z-ai/glm-4.5-air:free")
            echo "0.0000" ;;
        "anthropic/claude-3.5-sonnet")
            echo "0.0030" ;;
        "deepseek/deepseek-coder-v2")
            echo "0.0014" ;;
        "qwen/qwen-2.5-72b-instruct")
            echo "0.0009" ;;
        "horizon/horizon-v1")
            echo "0.0025" ;;
        "gemini-2.5-pro")
            echo "0.0020" ;;
        "gemini-2.5-flash")
            echo "0.0005" ;;
        *)
            echo "0.0020" ;;  # Default fallback rate
    esac
}

# Estimate cost for a given model and token count
estimate_operation_cost() {
    local model="$1"
    local estimated_tokens="${2:-2000}"
    local service="${3:-openrouter}"
    
    local cost_per_1k_tokens=$(get_model_price "$model")
    local estimated_cost=0.0
    
    if command -v bc >/dev/null 2>&1; then
        # Calculate cost: (tokens / 1000) * cost_per_1k
        estimated_cost=$(echo "scale=4; ($estimated_tokens / 1000) * $cost_per_1k_tokens" | bc -l)
    else
        # Simple bash calculation (less precise)
        estimated_cost=$(( (estimated_tokens * ${cost_per_1k_tokens%.*}) / 1000 ))
    fi
    
    echo "$estimated_cost"
}

# Check if operation would exceed budget limits
check_budget_constraints() {
    local service="$1"
    local estimated_cost="$2"
    local operation_type="$3"
    
    if [[ "$COST_TRACKING_ENABLED" != "true" ]]; then
        echo "cost_tracking_disabled"
        return 0
    fi
    
    echo "💰 Checking budget constraints for $service..."
    echo "   Estimated cost: \$${estimated_cost}"
    
    # Get current monthly spending
    local current_monthly_spending=$(get_monthly_spending "$service")
    local daily_spending=$(get_daily_spending "$service")
    
    echo "   Current monthly spending: \$${current_monthly_spending}"
    echo "   Daily spending: \$${daily_spending}"
    
    if command -v bc >/dev/null 2>&1; then
        # Check service-specific budget
        local service_budget="$OPENROUTER_BUDGET"
        if [[ "$service" == "gemini_cli" ]]; then
            service_budget="$GEMINI_BUDGET"
        fi
        
        local projected_monthly=$(echo "$current_monthly_spending + $estimated_cost" | bc -l)
        local projected_daily=$(echo "$daily_spending + $estimated_cost" | bc -l)
        
        # Monthly budget check
        local monthly_percentage=$(echo "scale=1; $projected_monthly * 100 / $service_budget" | bc -l)
        local monthly_threshold_check=$(echo "$monthly_percentage > $ALERT_THRESHOLD" | bc -l)
        local monthly_emergency_check=$(echo "$monthly_percentage > $EMERGENCY_STOP_THRESHOLD" | bc -l)
        
        # Daily limit check
        local daily_limit_check=$(echo "$projected_daily > $DAILY_LIMIT" | bc -l)
        
        echo "   Service budget: \$${service_budget}"
        echo "   Monthly usage: ${monthly_percentage}%"
        
        # Emergency stop check
        if [[ "$monthly_emergency_check" -eq 1 ]]; then
            echo "🚨 EMERGENCY STOP: Monthly budget emergency threshold (${EMERGENCY_STOP_THRESHOLD}%) exceeded!"
            echo "   Projected monthly: \$${projected_monthly} (${monthly_percentage}% of \$${service_budget})"
            
            # Log emergency stop alert
            log_cost_alert "emergency_stop" "$service" "$EMERGENCY_STOP_THRESHOLD" "$projected_monthly" "$service_budget" \
                "Emergency budget threshold exceeded - operation blocked"
            
            if [[ "$AUTO_FALLBACK_ON_BUDGET" == "true" ]]; then
                echo "🔄 Auto-triggering fallback due to budget constraints..."
                echo "emergency_fallback_required"
                return 1
            else
                echo "budget_emergency_stop"
                return 2
            fi
        fi
        
        # Alert threshold check
        if [[ "$monthly_threshold_check" -eq 1 ]]; then
            echo "⚠️ Budget Alert: Monthly spending approaching limit (${monthly_percentage}% of budget)"
            
            # Log budget warning alert
            log_cost_alert "budget_warning" "$service" "$ALERT_THRESHOLD" "$projected_monthly" "$service_budget" \
                "Monthly budget threshold (${ALERT_THRESHOLD}%) exceeded"
            
            if [[ "$AUTO_FALLBACK_ON_BUDGET" == "true" ]]; then
                echo "🔄 Auto-triggering fallback due to budget alert..."
                echo "budget_fallback_recommended"
                return 0
            else
                echo "⚠️ Consider using fallback services or free models"
                echo "budget_warning"
                return 0
            fi
        fi
        
        # Daily limit check
        if [[ "$daily_limit_check" -eq 1 ]]; then
            echo "⚠️ Daily Limit Warning: Approaching daily spending limit"
            echo "   Daily limit: \$${DAILY_LIMIT}"
            echo "   Projected daily: \$${projected_daily}"
            
            log_cost_alert "daily_limit" "$service" "100" "$projected_daily" "$DAILY_LIMIT" \
                "Daily spending limit approaching"
            
            echo "daily_limit_warning"
            return 0
        fi
    fi
    
    echo "✅ Budget check passed - operation within limits"
    echo "budget_ok"
    return 0
}

# Get current monthly spending for a service
get_monthly_spending() {
    local service="$1"
    local current_month=$(date +%Y-%m)
    
    if command -v sqlite3 >/dev/null 2>&1 && [[ -f "$USAGE_DB" ]]; then
        sqlite3 "$USAGE_DB" << EOF
SELECT COALESCE(SUM(estimated_cost_usd), 0.0) 
FROM usage_log 
WHERE service = '$service' 
AND strftime('%Y-%m', timestamp) = '$current_month';
EOF
    else
        # JSON fallback
        local usage_file="$SUPERCLAUDE_DIR/usage/monthly_${current_month}_${service}.json"
        if [[ -f "$usage_file" ]] && command -v jq >/dev/null 2>&1; then
            jq -r '.entries[] | .estimated_cost_usd' "$usage_file" 2>/dev/null | \
                awk '{sum += $1} END {printf "%.4f", sum}'
        else
            echo "0.0000"
        fi
    fi
}

# Get current daily spending for a service
get_daily_spending() {
    local service="$1"
    local current_date=$(date +%Y-%m-%d)
    
    if command -v sqlite3 >/dev/null 2>&1 && [[ -f "$USAGE_DB" ]]; then
        sqlite3 "$USAGE_DB" << EOF
SELECT COALESCE(SUM(estimated_cost_usd), 0.0) 
FROM usage_log 
WHERE service = '$service' 
AND date(timestamp) = '$current_date';
EOF
    else
        # JSON fallback
        local usage_file="$SUPERCLAUDE_DIR/usage/daily_${current_date}_${service}.json"
        if [[ -f "$usage_file" ]] && command -v jq >/dev/null 2>&1; then
            jq -r '.entries[] | .estimated_cost_usd' "$usage_file" 2>/dev/null | \
                awk '{sum += $1} END {printf "%.4f", sum}'
        else
            echo "0.0000"
        fi
    fi
}

# Log usage and cost data
log_usage() {
    local session_id="$1"
    local service="$2"
    local model="$3"
    local operation="$4"
    local input_tokens="${5:-0}"
    local output_tokens="${6:-0}"
    local estimated_cost="${7:-0.0}"
    local actual_cost="${8:-0.0}"
    local success="${9:-1}"
    local metadata="${10:-{}}"
    
    if [[ "$COST_TRACKING_ENABLED" != "true" ]]; then
        return 0
    fi
    
    local total_tokens=$((input_tokens + output_tokens))
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    echo "📊 Logging usage: $service/$model - \$${estimated_cost}"
    
    if command -v sqlite3 >/dev/null 2>&1 && [[ -f "$USAGE_DB" ]]; then
        # Use SQLite database
        sqlite3 "$USAGE_DB" << EOF
INSERT INTO usage_log (
    session_id, service, model, operation, 
    input_tokens, output_tokens, total_tokens,
    estimated_cost_usd, actual_cost_usd, 
    timestamp, success, metadata
) VALUES (
    '$session_id', '$service', '$model', '$operation',
    $input_tokens, $output_tokens, $total_tokens,
    $estimated_cost, $actual_cost,
    '$timestamp', $success, '$metadata'
);
EOF
    else
        # JSON fallback
        local current_date=$(date +%Y-%m-%d)
        local usage_file="$SUPERCLAUDE_DIR/usage/daily_${current_date}_${service}.json"
        
        # Initialize file if it doesn't exist
        if [[ ! -f "$usage_file" ]]; then
            echo '{"date": "'$current_date'", "service": "'$service'", "entries": []}' > "$usage_file"
        fi
        
        # Add entry
        local entry="{
            \"session_id\": \"$session_id\",
            \"model\": \"$model\",
            \"operation\": \"$operation\",
            \"input_tokens\": $input_tokens,
            \"output_tokens\": $output_tokens,
            \"total_tokens\": $total_tokens,
            \"estimated_cost_usd\": $estimated_cost,
            \"actual_cost_usd\": $actual_cost,
            \"timestamp\": \"$timestamp\",
            \"success\": $success,
            \"metadata\": $metadata
        }"
        
        if command -v jq >/dev/null 2>&1; then
            jq --argjson entry "$entry" '.entries += [$entry]' "$usage_file" > "${usage_file}.tmp" && \
                mv "${usage_file}.tmp" "$usage_file"
        fi
    fi
    
    # Update budget tracking
    update_budget_tracking "$service" "$estimated_cost"
}

# Update budget tracking records
update_budget_tracking() {
    local service="$1"
    local spent_amount="$2"
    local current_month=$(date +%Y-%m)
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    # Determine service budget
    local service_budget="$OPENROUTER_BUDGET"
    if [[ "$service" == "gemini_cli" ]]; then
        service_budget="$GEMINI_BUDGET"
    fi
    
    if command -v sqlite3 >/dev/null 2>&1 && [[ -f "$USAGE_DB" ]]; then
        # Check if record exists for this month/service
        local existing_record=$(sqlite3 "$USAGE_DB" \
            "SELECT id FROM budget_tracking WHERE month = '$current_month' AND service = '$service';" 2>/dev/null || echo "")
        
        if [[ -n "$existing_record" ]]; then
            # Update existing record
            sqlite3 "$USAGE_DB" << EOF
UPDATE budget_tracking 
SET spent_amount_usd = spent_amount_usd + $spent_amount,
    remaining_amount_usd = budgeted_amount_usd - (spent_amount_usd + $spent_amount),
    last_updated = '$timestamp'
WHERE month = '$current_month' AND service = '$service';
EOF
        else
            # Create new record
            sqlite3 "$USAGE_DB" << EOF
INSERT INTO budget_tracking (
    month, service, budgeted_amount_usd, spent_amount_usd, 
    remaining_amount_usd, alert_threshold_percent, last_updated
) VALUES (
    '$current_month', '$service', $service_budget, $spent_amount,
    $service_budget - $spent_amount, $ALERT_THRESHOLD, '$timestamp'
);
EOF
        fi
    fi
}

# Log cost-related alerts
log_cost_alert() {
    local alert_type="$1"
    local service="$2"
    local threshold_percent="$3"
    local current_usage="$4"
    local budget_limit="$5"
    local message="$6"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    echo "🚨 Cost Alert: $alert_type for $service"
    echo "   $message"
    
    if command -v sqlite3 >/dev/null 2>&1 && [[ -f "$USAGE_DB" ]]; then
        sqlite3 "$USAGE_DB" << EOF
INSERT INTO cost_alerts (
    alert_type, service, threshold_percent, current_usage_usd,
    budget_limit_usd, message, timestamp
) VALUES (
    '$alert_type', '$service', $threshold_percent, $current_usage,
    $budget_limit, '$message', '$timestamp'
);
EOF
    fi
    
    # Store alert in file system as well
    local alert_file="$SUPERCLAUDE_DIR/usage/alerts_$(date +%Y-%m).json"
    local alert_entry="{
        \"alert_type\": \"$alert_type\",
        \"service\": \"$service\",
        \"threshold_percent\": $threshold_percent,
        \"current_usage_usd\": $current_usage,
        \"budget_limit_usd\": $budget_limit,
        \"message\": \"$message\",
        \"timestamp\": \"$timestamp\"
    }"
    
    if [[ ! -f "$alert_file" ]]; then
        echo '{"alerts": []}' > "$alert_file"
    fi
    
    if command -v jq >/dev/null 2>&1; then
        jq --argjson alert "$alert_entry" '.alerts += [$alert]' "$alert_file" > "${alert_file}.tmp" && \
            mv "${alert_file}.tmp" "$alert_file"
    fi
}

# Generate cost report
generate_cost_report() {
    local report_type="${1:-monthly}"
    local service="${2:-all}"
    local format="${3:-console}"
    
    echo "📊 SuperClaude Cost Report - $(date +%Y-%m-%d)"
    echo "============================================="
    
    case "$report_type" in
        "monthly")
            generate_monthly_report "$service" "$format"
            ;;
        "daily")
            generate_daily_report "$service" "$format"
            ;;
        "budget")
            generate_budget_report "$service" "$format"
            ;;
        "alerts")
            generate_alerts_report "$service" "$format"
            ;;
        *)
            echo "Unknown report type: $report_type"
            echo "Available types: monthly, daily, budget, alerts"
            return 1
            ;;
    esac
}

# Generate monthly cost report
generate_monthly_report() {
    local service="$1"
    local format="$2"
    local current_month=$(date +%Y-%m)
    
    echo ""
    echo "📅 Monthly Report for $current_month"
    echo "==================================="
    
    if command -v sqlite3 >/dev/null 2>&1 && [[ -f "$USAGE_DB" ]]; then
        if [[ "$service" == "all" ]]; then
            echo "📊 Usage by Service:"
            sqlite3 "$USAGE_DB" << EOF
.headers ON
.mode column
SELECT 
    service,
    COUNT(*) as operations,
    SUM(total_tokens) as total_tokens,
    ROUND(SUM(estimated_cost_usd), 4) as cost_usd,
    AVG(estimated_cost_usd) as avg_cost_per_op
FROM usage_log 
WHERE strftime('%Y-%m', timestamp) = '$current_month'
GROUP BY service
ORDER BY cost_usd DESC;
EOF
            
            echo ""
            echo "📈 Top Models by Usage:"
            sqlite3 "$USAGE_DB" << EOF
.headers ON
.mode column
SELECT 
    service || '/' || model as model,
    COUNT(*) as operations,
    ROUND(SUM(estimated_cost_usd), 4) as cost_usd
FROM usage_log 
WHERE strftime('%Y-%m', timestamp) = '$current_month'
GROUP BY service, model
ORDER BY cost_usd DESC
LIMIT 10;
EOF
        else
            echo "📊 Usage for $service:"
            sqlite3 "$USAGE_DB" << EOF
.headers ON
.mode column
SELECT 
    model,
    operation,
    COUNT(*) as count,
    SUM(total_tokens) as tokens,
    ROUND(SUM(estimated_cost_usd), 4) as cost_usd
FROM usage_log 
WHERE service = '$service' 
AND strftime('%Y-%m', timestamp) = '$current_month'
GROUP BY model, operation
ORDER BY cost_usd DESC;
EOF
        fi
        
        # Total monthly spending
        local total_monthly=$(sqlite3 "$USAGE_DB" \
            "SELECT ROUND(SUM(estimated_cost_usd), 4) FROM usage_log WHERE strftime('%Y-%m', timestamp) = '$current_month';")
        
        echo ""
        echo "💰 Total Monthly Spending: \$${total_monthly}"
        
        if command -v bc >/dev/null 2>&1; then
            local budget_percentage=$(echo "scale=1; $total_monthly * 100 / $MONTHLY_CEILING" | bc -l)
            echo "📊 Budget Usage: ${budget_percentage}% of \$${MONTHLY_CEILING}"
            
            if (( $(echo "$budget_percentage > $ALERT_THRESHOLD" | bc -l) )); then
                echo "⚠️ Warning: Approaching monthly budget limit!"
            fi
        fi
    else
        echo "⚠️ Usage database not available - using JSON fallback"
        
        # JSON-based reporting (simplified)
        local usage_files=("$SUPERCLAUDE_DIR/usage/daily_"*"_${service}.json")
        if [[ "$service" == "all" ]]; then
            usage_files=("$SUPERCLAUDE_DIR/usage/daily_"*".json")
        fi
        
        local total_cost=0
        local total_operations=0
        
        for file in "${usage_files[@]}"; do
            if [[ -f "$file" ]] && command -v jq >/dev/null 2>&1; then
                local file_cost=$(jq -r '.entries[] | .estimated_cost_usd' "$file" 2>/dev/null | \
                    awk '{sum += $1} END {printf "%.4f", sum}')
                local file_ops=$(jq -r '.entries | length' "$file" 2>/dev/null)
                
                if command -v bc >/dev/null 2>&1; then
                    total_cost=$(echo "$total_cost + $file_cost" | bc -l)
                    total_operations=$(echo "$total_operations + $file_ops" | bc -l)
                fi
            fi
        done
        
        echo "💰 Estimated Total: \$${total_cost}"
        echo "🔢 Total Operations: ${total_operations}"
    fi
}

# Generate daily cost report
generate_daily_report() {
    local service="$1"
    local format="$2"
    local current_date=$(date +%Y-%m-%d)
    
    echo ""
    echo "📅 Daily Report for $current_date"
    echo "================================"
    
    if command -v sqlite3 >/dev/null 2>&1 && [[ -f "$USAGE_DB" ]]; then
        echo "📊 Today's Usage:"
        if [[ "$service" == "all" ]]; then
            sqlite3 "$USAGE_DB" << EOF
.headers ON
.mode column
SELECT 
    service,
    COUNT(*) as operations,
    SUM(total_tokens) as tokens,
    ROUND(SUM(estimated_cost_usd), 4) as cost_usd
FROM usage_log 
WHERE date(timestamp) = '$current_date'
GROUP BY service
ORDER BY cost_usd DESC;
EOF
        else
            sqlite3 "$USAGE_DB" << EOF
.headers ON
.mode column
SELECT 
    model,
    operation,
    COUNT(*) as operations,
    ROUND(SUM(estimated_cost_usd), 4) as cost_usd,
    timestamp
FROM usage_log 
WHERE service = '$service' 
AND date(timestamp) = '$current_date'
GROUP BY model, operation
ORDER BY timestamp DESC;
EOF
        fi
        
        local daily_total=$(sqlite3 "$USAGE_DB" \
            "SELECT ROUND(SUM(estimated_cost_usd), 4) FROM usage_log WHERE date(timestamp) = '$current_date';")
        
        echo ""
        echo "💰 Today's Total Spending: \$${daily_total}"
        echo "📊 Daily Limit: \$${DAILY_LIMIT}"
        
        if command -v bc >/dev/null 2>&1; then
            local daily_percentage=$(echo "scale=1; $daily_total * 100 / $DAILY_LIMIT" | bc -l)
            echo "📈 Daily Usage: ${daily_percentage}%"
        fi
    fi
}

# Generate budget status report
generate_budget_report() {
    local service="$1"
    local format="$2"
    local current_month=$(date +%Y-%m)
    
    echo ""
    echo "💰 Budget Status Report"
    echo "======================="
    
    if command -v sqlite3 >/dev/null 2>&1 && [[ -f "$USAGE_DB" ]]; then
        echo "📊 Service Budget Status:"
        sqlite3 "$USAGE_DB" << EOF
.headers ON
.mode column
SELECT 
    service,
    ROUND(budgeted_amount_usd, 2) as budget_usd,
    ROUND(spent_amount_usd, 4) as spent_usd,
    ROUND(remaining_amount_usd, 4) as remaining_usd,
    ROUND((spent_amount_usd * 100.0 / budgeted_amount_usd), 1) as usage_percent,
    alert_threshold_percent as alert_threshold
FROM budget_tracking 
WHERE month = '$current_month'
ORDER BY usage_percent DESC;
EOF
        
        # Check for budget alerts
        local alert_count=$(sqlite3 "$USAGE_DB" \
            "SELECT COUNT(*) FROM cost_alerts WHERE strftime('%Y-%m', timestamp) = '$current_month';")
        
        if [[ "$alert_count" -gt 0 ]]; then
            echo ""
            echo "🚨 Recent Budget Alerts: $alert_count this month"
        fi
    fi
    
    echo ""
    echo "💳 Global Budget Limits:"
    echo "   Monthly Ceiling: \$${MONTHLY_CEILING}"
    echo "   Daily Limit: \$${DAILY_LIMIT}"
    echo "   Alert Threshold: ${ALERT_THRESHOLD}%"
    echo "   Emergency Stop: ${EMERGENCY_STOP_THRESHOLD}%"
    echo ""
    echo "🔧 Budget Management:"
    echo "   Auto Fallback: $AUTO_FALLBACK_ON_BUDGET"
    echo "   Prefer Free Models: $PREFER_FREE_MODELS"
    echo "   Cost Tracking: $COST_TRACKING_ENABLED"
}

# Generate alerts report
generate_alerts_report() {
    local service="$1"
    local format="$2"
    local current_month=$(date +%Y-%m)
    
    echo ""
    echo "🚨 Cost Alerts Report"
    echo "====================="
    
    if command -v sqlite3 >/dev/null 2>&1 && [[ -f "$USAGE_DB" ]]; then
        echo "🚨 Recent Alerts:"
        if [[ "$service" == "all" ]]; then
            sqlite3 "$USAGE_DB" << EOF
.headers ON
.mode column
SELECT 
    alert_type,
    service,
    ROUND(current_usage_usd, 4) as usage_usd,
    ROUND(budget_limit_usd, 2) as limit_usd,
    datetime(timestamp) as alert_time,
    CASE WHEN acknowledged = 1 THEN 'Yes' ELSE 'No' END as acknowledged
FROM cost_alerts 
WHERE strftime('%Y-%m', timestamp) = '$current_month'
ORDER BY timestamp DESC
LIMIT 20;
EOF
        else
            sqlite3 "$USAGE_DB" << EOF
.headers ON
.mode column
SELECT 
    alert_type,
    ROUND(current_usage_usd, 4) as usage_usd,
    ROUND(budget_limit_usd, 2) as limit_usd,
    message,
    datetime(timestamp) as alert_time
FROM cost_alerts 
WHERE service = '$service' 
AND strftime('%Y-%m', timestamp) = '$current_month'
ORDER BY timestamp DESC;
EOF
        fi
    fi
}

# Pre-operation cost check and approval
pre_operation_cost_check() {
    local service="$1"
    local model="$2"
    local operation="$3"
    local estimated_tokens="${4:-2000}"
    
    echo "💰 Pre-operation cost check for $service/$model..."
    
    # Estimate cost
    local estimated_cost=$(estimate_operation_cost "$model" "$estimated_tokens" "$service")
    echo "   Estimated cost: \$${estimated_cost}"
    echo "   Estimated tokens: $estimated_tokens"
    
    # Check budget constraints
    local budget_status=$(check_budget_constraints "$service" "$estimated_cost" "$operation")
    local budget_exit_code=$?
    
    echo "   Budget status: $budget_status"
    
    case "$budget_status" in
        "emergency_fallback_required")
            echo "🚨 EMERGENCY: Budget limits exceeded - triggering immediate fallback"
            if [[ -f "$FALLBACK_COORDINATOR" ]]; then
                echo "🔄 Activating fallback coordinator..."
                "$FALLBACK_COORDINATOR" execute "$operation" "analyst" "$service" "budget_emergency"
                return 3
            else
                echo "❌ Fallback coordinator not available - operation blocked"
                return 2
            fi
            ;;
        "budget_emergency_stop")
            echo "🛑 OPERATION BLOCKED: Emergency budget threshold exceeded"
            echo "   Please review budget settings or wait until next billing period"
            return 2
            ;;
        "budget_fallback_recommended")
            echo "⚠️ Budget threshold exceeded - fallback recommended"
            if [[ "$AUTO_FALLBACK_ON_BUDGET" == "true" ]]; then
                echo "🔄 Auto-triggering fallback due to budget constraints..."
                if [[ -f "$FALLBACK_COORDINATOR" ]]; then
                    "$FALLBACK_COORDINATOR" execute "$operation" "analyst" "$service" "budget_threshold"
                    return 3
                else
                    echo "⚠️ Fallback coordinator not available - proceeding with caution"
                    return 1
                fi
            else
                echo "⚠️ Consider using free models or fallback services"
                return 1
            fi
            ;;
        "budget_warning")
            echo "⚠️ Budget warning - proceeding with monitoring"
            return 1
            ;;
        "daily_limit_warning")
            echo "⚠️ Daily limit warning - proceeding with monitoring"
            return 1
            ;;
        "budget_ok"|"cost_tracking_disabled")
            echo "✅ Budget check passed - proceeding with operation"
            return 0
            ;;
        *)
            echo "⚠️ Unknown budget status - proceeding with caution"
            return 1
            ;;
    esac
}

# Post-operation cost tracking
post_operation_cost_tracking() {
    local session_id="$1"
    local service="$2"
    local model="$3"
    local operation="$4"
    local success="${5:-1}"
    local actual_tokens="${6:-0}"
    local actual_cost="${7:-0.0}"
    local metadata="${8:-{}}"
    
    # If actual tokens not provided, estimate based on typical operation
    if [[ "$actual_tokens" -eq 0 ]]; then
        case "$operation" in
            "analysis"|"research")
                actual_tokens=3000
                ;;
            "generation"|"coding")
                actual_tokens=4000
                ;;
            "simple_query")
                actual_tokens=1500
                ;;
            *)
                actual_tokens=2500
                ;;
        esac
    fi
    
    # If actual cost not provided, estimate it
    if [[ "$actual_cost" == "0.0" ]]; then
        actual_cost=$(estimate_operation_cost "$model" "$actual_tokens" "$service")
    fi
    
    echo "📊 Post-operation cost tracking..."
    echo "   Session: $session_id"
    echo "   Service: $service"
    echo "   Model: $model" 
    echo "   Tokens: $actual_tokens"
    echo "   Cost: \$${actual_cost}"
    echo "   Success: $success"
    
    # Log the usage
    log_usage "$session_id" "$service" "$model" "$operation" "0" "$actual_tokens" "$actual_cost" "$actual_cost" "$success" "$metadata"
    
    # Update running totals and check for new alerts
    local current_monthly=$(get_monthly_spending "$service")
    local current_daily=$(get_daily_spending "$service")
    
    echo "✅ Cost tracking completed"
    echo "   Monthly total ($service): \$${current_monthly}"
    echo "   Daily total ($service): \$${current_daily}"
}

# Show help information
show_help() {
    echo "SuperClaude Cost Management System"
    echo "=================================="
    echo ""
    echo "USAGE:"
    echo "  ./cost-manager.sh COMMAND [OPTIONS]"
    echo ""
    echo "COMMANDS:"
    echo "  pre-check SERVICE MODEL OPERATION [TOKENS]    Check budget before operation"
    echo "  post-track SESSION SERVICE MODEL OP SUCCESS [TOKENS] [COST]  Track after operation"
    echo "  report [TYPE] [SERVICE] [FORMAT]             Generate cost reports"
    echo "  status                                        Show current budget status"
    echo "  alerts [SERVICE]                             Show recent cost alerts"
    echo "  init                                         Initialize cost tracking system"
    echo ""
    echo "REPORT TYPES:"
    echo "  monthly    Monthly cost summary (default)"
    echo "  daily      Daily cost breakdown"
    echo "  budget     Budget status and limits"
    echo "  alerts     Cost alerts history"
    echo ""
    echo "EXAMPLES:"
    echo "  # Check budget before OpenRouter operation"
    echo "  ./cost-manager.sh pre-check openrouter deepseek/coder analysis 3000"
    echo ""
    echo "  # Track usage after operation"
    echo "  ./cost-manager.sh post-track sc-123 openrouter deepseek analysis 1 3500 0.0049"
    echo ""
    echo "  # Generate monthly report"
    echo "  ./cost-manager.sh report monthly openrouter"
    echo ""
    echo "  # Check budget status"
    echo "  ./cost-manager.sh status"
    echo ""
    echo "FEATURES:"
    echo "  • Real-time budget monitoring and alerts"
    echo "  • Automatic fallback when budget limits exceeded"
    echo "  • Service-specific budget tracking"
    echo "  • Daily and monthly spending limits"
    echo "  • Cost estimation for different models"
    echo "  • Emergency stop mechanisms"
}

# Main command dispatcher
main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        "pre-check")
            if [[ $# -lt 3 ]]; then
                echo "❌ Usage: $0 pre-check SERVICE MODEL OPERATION [TOKENS]"
                return 1
            fi
            pre_operation_cost_check "$1" "$2" "$3" "${4:-2000}"
            ;;
        "post-track")
            if [[ $# -lt 5 ]]; then
                echo "❌ Usage: $0 post-track SESSION SERVICE MODEL OPERATION SUCCESS [TOKENS] [COST]"
                return 1
            fi
            post_operation_cost_tracking "$1" "$2" "$3" "$4" "$5" "${6:-0}" "${7:-0.0}"
            ;;
        "report")
            local report_type="${1:-monthly}"
            local service="${2:-all}"
            local format="${3:-console}"
            generate_cost_report "$report_type" "$service" "$format"
            ;;
        "status")
            generate_budget_report "all" "console"
            ;;
        "alerts")
            local service="${1:-all}"
            generate_alerts_report "$service" "console"
            ;;
        "init")
            echo "🔧 Initializing SuperClaude cost management system..."
            init_usage_database
            echo "✅ Cost tracking system initialized"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            echo "❌ Unknown command: $command"
            echo ""
            show_help
            return 1
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi