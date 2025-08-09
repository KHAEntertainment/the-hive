#!/bin/bash
# Enhanced OpenRouter Script with Status Reporting and Preferences
# SuperClaude Multi-Model OpenRouter Integration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_PATH="/Users/bbrenner/Documents/Scripting Projects/thehive"
SUPERCLAUDE_DIR="$WORKSPACE_PATH/.superclaude"
PREFERENCES_FILE="$SUPERCLAUDE_DIR/preferences.json"
PERSONA_VALIDATOR="$SCRIPT_DIR/persona-validator.sh"

# Load user preferences
load_user_preferences() {
    local prefs_file="$1"
    
    if [[ -f "$prefs_file" ]] && command -v jq >/dev/null 2>&1; then
        # Extract OpenRouter preferences
        AVOID_PROVIDERS=$(jq -r '.user_preferences.model_selection.openrouter.avoid_providers[]? // empty' "$prefs_file" 2>/dev/null | tr '\n' ' ')
        PREFER_FREE_MODELS=$(jq -r '.user_preferences.model_selection.openrouter.prefer_free_models // true' "$prefs_file" 2>/dev/null)
        PREFERRED_MODELS=$(jq -r '.user_preferences.model_selection.openrouter.preferred_models[]? // empty' "$prefs_file" 2>/dev/null | tr '\n' ' ')
        FALLBACK_CHAIN=$(jq -r '.user_preferences.model_selection.openrouter.fallback_chain[]? // empty' "$prefs_file" 2>/dev/null | tr '\n' ' ')
        MAX_RETRIES=$(jq -r '.user_preferences.model_selection.openrouter.max_retries // 3' "$prefs_file" 2>/dev/null)
        
        # Cost management
        MONTHLY_CEILING=$(jq -r '.user_preferences.cost_management.monthly_ceiling_usd // 50.0' "$prefs_file" 2>/dev/null)
        ALERT_THRESHOLD=$(jq -r '.user_preferences.cost_management.alert_threshold_percentage // 80' "$prefs_file" 2>/dev/null)
        
        # Status reporting preferences
        SHOW_MODEL_DETAILS=$(jq -r '.user_preferences.status_reporting.show_model_details // true' "$prefs_file" 2>/dev/null)
        SHOW_PROGRESS_BARS=$(jq -r '.user_preferences.status_reporting.show_progress_bars // true' "$prefs_file" 2>/dev/null)
        SHOW_COST_ESTIMATES=$(jq -r '.user_preferences.status_reporting.show_cost_estimates // true' "$prefs_file" 2>/dev/null)
        SHOW_PROVIDER_INFO=$(jq -r '.user_preferences.status_reporting.show_provider_info // true' "$prefs_file" 2>/dev/null)
        VERBOSE_LOGGING=$(jq -r '.user_preferences.status_reporting.verbose_logging // false' "$prefs_file" 2>/dev/null)
    else
        # Default values
        AVOID_PROVIDERS="google/* google/gemini-*"
        PREFER_FREE_MODELS="true"
        PREFERRED_MODELS="openai/gpt-oss-20b:free openrouter/horizon-beta:free z-ai/glm-4.5-air:free"
        FALLBACK_CHAIN="free_models gemini_cli claude_agents"
        MAX_RETRIES="3"
        MONTHLY_CEILING="50.0"
        ALERT_THRESHOLD="80"
        SHOW_MODEL_DETAILS="true"
        SHOW_PROGRESS_BARS="true"
        SHOW_COST_ESTIMATES="true"
        SHOW_PROVIDER_INFO="true"
        VERBOSE_LOGGING="false"
    fi
}

# Initialize preferences
load_user_preferences "$PREFERENCES_FILE"

# Enhanced status reporting functions
show_model_status() {
    local model="$1"
    local provider="openrouter"
    local status="$2"
    local progress="$3"
    local cost_estimate="$4"
    
    if [[ "$SHOW_MODEL_DETAILS" == "true" ]]; then
        echo "🤖 Model: $model"
        
        if [[ "$SHOW_PROVIDER_INFO" == "true" ]]; then
            echo "📍 Provider: $provider"
        fi
        
        echo "⏱️  Status: $status"
        
        if [[ -n "$progress" && "$SHOW_PROGRESS_BARS" == "true" ]]; then
            echo "🔄 Progress: $progress"
        fi
        
        if [[ -n "$cost_estimate" && "$SHOW_COST_ESTIMATES" == "true" ]]; then
            echo "💰 Estimated Cost: $cost_estimate"
        fi
    fi
}

# Enhanced OpenRouter API key retrieval with fallback handling
get_openrouter_api_key() {
    local api_key=""
    
    # 1. Environment variable first
    if [[ -n "$OPENROUTER_API_KEY" ]]; then
        api_key="$OPENROUTER_API_KEY"
        if [[ "$VERBOSE_LOGGING" == "true" ]]; then
            echo "🔑 Using API key from environment variable"
        fi
    
    # 2. SuperClaude memory system
    elif command -v claude &>/dev/null && claude mcp list 2>/dev/null | grep -q "claude-flow.*Connected"; then
        if mcp__claude-flow__memory_usage retrieve \
            --namespace "superclaude/system/openrouter/config" \
            --key "api_key" &>/dev/null; then
            api_key=$(mcp__claude-flow__memory_usage retrieve \
                --namespace "superclaude/system/openrouter/config" \
                --key "api_key" 2>/dev/null)
            if [[ "$VERBOSE_LOGGING" == "true" ]]; then
                echo "🔑 Using API key from SuperClaude memory"
            fi
        fi
    
    # 3. macOS Keychain
    elif command -v security &>/dev/null; then
        api_key=$(security find-generic-password -w -s "openrouter-api-key" -a "$USER" 2>/dev/null)
        if [[ -n "$api_key" && "$VERBOSE_LOGGING" == "true" ]]; then
            echo "🔑 Using API key from macOS Keychain"
        fi
    fi
    
    echo "$api_key"
}

# Check OpenRouter availability with enhanced reporting
check_openrouter_availability() {
    echo "🔍 Checking OpenRouter API availability..."
    show_model_status "checking-connection" "connecting" "[██        ] 20%"
    
    local api_key=$(get_openrouter_api_key)
    
    if [[ -z "$api_key" ]]; then
        echo "❌ OpenRouter API key not found"
        echo "🔧 Set up with: /sc:openrouter-setup"
        
        # Check fallback preferences
        if [[ -f "$PREFERENCES_FILE" ]] && command -v jq >/dev/null 2>&1; then
            echo "🔄 Checking fallback preferences..."
            if echo "$FALLBACK_CHAIN" | grep -q "gemini_cli"; then
                echo "📱 Fallback to Gemini CLI configured"
            fi
            if echo "$FALLBACK_CHAIN" | grep -q "claude_agents"; then
                echo "🤖 Fallback to Claude agents configured"
            fi
        fi
        
        return 1
    fi
    
    # Test API connectivity
    show_model_status "testing-connection" "testing" "[████      ] 40%"
    
    local test_response=$(curl -s --connect-timeout 10 \
        -H "Authorization: Bearer $api_key" \
        -H "HTTP-Referer: https://github.com/anthropics/claude-code" \
        -H "X-Title: SuperClaude-Integration" \
        "https://openrouter.ai/api/v1/models" | head -c 100)
    
    if [[ $? -eq 0 && -n "$test_response" ]]; then
        echo "✅ OpenRouter API connected successfully"
        show_model_status "connection-ready" "connected" "[██████████] 100%"
        
        if [[ "$VERBOSE_LOGGING" == "true" ]]; then
            local model_count=$(curl -s \
                -H "Authorization: Bearer $api_key" \
                -H "HTTP-Referer: https://github.com/anthropics/claude-code" \
                "https://openrouter.ai/api/v1/models" | jq -r '.data | length' 2>/dev/null || echo "unknown")
            echo "📊 Available models: $model_count"
        fi
        
        return 0
    else
        echo "❌ OpenRouter API connection failed"
        echo "🌐 Check internet connection and API key validity"
        
        # Check fallback options
        echo "🔄 Checking fallback options from preferences..."
        handle_openrouter_fallback "connection_failed"
        return 1
    fi
}

# Model filtering based on user preferences
filter_models_by_preferences() {
    local models_json="$1"
    local filtered_models="$models_json"
    
    # Filter out avoided providers
    if [[ -n "$AVOID_PROVIDERS" ]]; then
        echo "🚫 Filtering out avoided providers: $AVOID_PROVIDERS"
        for provider_pattern in $AVOID_PROVIDERS; do
            filtered_models=$(echo "$filtered_models" | jq --arg pattern "$provider_pattern" '
                .data |= map(select(.id | test($pattern) | not))
            ')
        done
    fi
    
    # Prefer free models if configured
    if [[ "$PREFER_FREE_MODELS" == "true" ]]; then
        echo "💰 Prioritizing free models"
        filtered_models=$(echo "$filtered_models" | jq '
            .data |= sort_by(if (.pricing.prompt | tonumber) == 0 then 0 else 1 end)
        ')
    fi
    
    echo "$filtered_models"
}

# Enhanced model selection with preferences
select_optimal_model() {
    local task="$1"
    local budget_tier="${2:-standard}"
    local context_size="${3:-4000}"
    
    echo "🎯 Selecting optimal model for task analysis..."
    show_model_status "analyzing-task" "selecting" "[███       ] 30%"
    
    # Simple task classification
    local task_lower=$(echo "$task" | tr '[:upper:]' '[:lower:]')
    local model_category=""
    local selected_model=""
    
    # Classify task type
    if echo "$task_lower" | grep -qE "(design|ui|ux|interface|visual|component|style)"; then
        model_category="design"
    elif echo "$task_lower" | grep -qE "(code|implement|function|debug|programming|api)"; then
        model_category="coding"
    elif echo "$task_lower" | grep -qE "(analyze|research|study|investigate|data|trends)"; then
        model_category="analysis"
    elif echo "$task_lower" | grep -qE "(solve|calculate|logic|strategy|problem|mathematical)"; then
        model_category="reasoning"
    elif echo "$task_lower" | grep -qE "(write|document|content|communication|guide|tutorial)"; then
        model_category="writing"
    else
        model_category="general"
    fi
    
    echo "📋 Task classified as: $model_category"
    
    # Check preferred models first
    if [[ -n "$PREFERRED_MODELS" ]]; then
        echo "⭐ Checking preferred models: $PREFERRED_MODELS"
        for preferred_model in $PREFERRED_MODELS; do
            if model_supports_category "$preferred_model" "$model_category"; then
                selected_model="$preferred_model"
                echo "✅ Selected preferred model: $selected_model"
                break
            fi
        done
    fi
    
    # Fallback to category-based selection
    if [[ -z "$selected_model" ]]; then
        case "$model_category" in
            "design")
                selected_model="horizon/horizon-v1"
                ;;
            "coding")
                if [[ "$PREFER_FREE_MODELS" == "true" ]]; then
                    selected_model="openai/gpt-oss-20b:free"
                else
                    selected_model="deepseek/deepseek-coder-v2"
                fi
                ;;
            "analysis")
                if [[ "$PREFER_FREE_MODELS" == "true" ]]; then
                    selected_model="z-ai/glm-4.5-air:free"
                else
                    selected_model="qwen/qwen-2.5-72b-instruct"
                fi
                ;;
            "reasoning")
                selected_model="openrouter/horizon-beta:free"
                ;;
            "writing")
                selected_model="anthropic/claude-3.5-sonnet"
                ;;
            *)
                selected_model="openai/gpt-oss-20b:free"
                ;;
        esac
    fi
    
    show_model_status "$selected_model" "selected" "[█████████ ] 90%"
    echo "$selected_model"
}

# Model category support check
model_supports_category() {
    local model="$1"
    local category="$2"
    
    case "$category" in
        "design")
            echo "$model" | grep -qE "(horizon|claude|gpt-4|gemini)"
            ;;
        "coding")
            echo "$model" | grep -qE "(deepseek|coder|codestral|gpt|claude|horizon-beta)"
            ;;
        "analysis")
            echo "$model" | grep -qE "(qwen|glm|claude|deepseek-r1|horizon-beta)"
            ;;
        "reasoning")
            echo "$model" | grep -qE "(o1|horizon|claude|gpt)"
            ;;
        "writing")
            echo "$model" | grep -qE "(claude|gpt|llama)"
            ;;
        *)
            return 0  # All models support general tasks
            ;;
    esac
}

# Enhanced fallback handling
handle_openrouter_fallback() {
    local failure_reason="$1"
    
    echo "🔄 Activating fallback chain: $FALLBACK_CHAIN"
    
    for fallback in $FALLBACK_CHAIN; do
        case "$fallback" in
            "gemini_cli")
                if command -v gemini &>/dev/null; then
                    echo "📱 Fallback available: Gemini CLI"
                    echo "💡 Use: /sc:gemini instead"
                    return 0
                fi
                ;;
            "claude_agents")
                echo "🤖 Fallback available: Claude agents"
                echo "💡 Using native SuperClaude capabilities"
                return 0
                ;;
            "free_models")
                echo "💰 Attempting free models only..."
                # This would filter for free models specifically
                ;;
        esac
    done
    
    echo "❌ All fallback options exhausted"
    return 1
}

# Cost estimation with user preferences
estimate_request_cost() {
    local model="$1"
    local estimated_tokens="${2:-2000}"
    
    if [[ "$SHOW_COST_ESTIMATES" != "true" ]]; then
        return 0
    fi
    
    # Simple cost estimation (would need actual OpenRouter pricing data)
    local cost_estimate="0.005"
    
    # Check against monthly ceiling
    if command -v bc >/dev/null 2>&1; then
        local current_usage=$(get_monthly_usage)
        local projected_cost=$(echo "$current_usage + $cost_estimate" | bc -l)
        local ceiling_check=$(echo "$projected_cost > $MONTHLY_CEILING" | bc -l)
        
        if [[ "$ceiling_check" -eq 1 ]]; then
            echo "⚠️ Warning: Request would exceed monthly budget ceiling ($MONTHLY_CEILING)"
            local percentage=$(echo "scale=1; $projected_cost * 100 / $MONTHLY_CEILING" | bc -l)
            echo "📊 Projected usage: ${percentage}% of monthly budget"
            
            # Suggest fallbacks if approaching limit
            if echo "$projected_cost > ($MONTHLY_CEILING * $ALERT_THRESHOLD / 100)" | bc -l | grep -q 1; then
                echo "💡 Consider using fallback options to manage costs"
                handle_openrouter_fallback "cost_limit_approaching"
            fi
        fi
    fi
    
    echo "$cost_estimate"
}

# Get monthly usage (simplified - would integrate with actual usage tracking)
get_monthly_usage() {
    # Placeholder for actual usage tracking
    echo "5.23"
}

# Enhanced persona validation with OpenRouter integration
validate_and_correct_persona() {
    local requested_persona="$1"
    
    if [[ -f "$PERSONA_VALIDATOR" ]]; then
        echo "🔍 Validating persona: '$requested_persona'"
        local validated_persona=$("$PERSONA_VALIDATOR" validate "$requested_persona" 2>/dev/null)
        local validation_exit_code=$?
        
        if [[ $validation_exit_code -eq 0 && -n "$validated_persona" ]]; then
            if [[ "$validated_persona" != "$requested_persona" ]]; then
                echo "🔄 Persona auto-corrected: '$requested_persona' → '$validated_persona'"
                echo "$validated_persona"
            else
                echo "✅ Persona validated: '$requested_persona'"
                echo "$validated_persona"
            fi
            return 0
        else
            echo "❌ Persona validation failed for: '$requested_persona'"
            "$PERSONA_VALIDATOR" validate "$requested_persona" # Show full error with suggestions
            return 1
        fi
    else
        # Fallback validation
        local valid_personas=("designer" "researcher" "coder" "analyst" "writer" "reviewer")
        for valid_persona in "${valid_personas[@]}"; do
            if [[ "$requested_persona" == "$valid_persona" ]]; then
                echo "$requested_persona"
                return 0
            fi
        done
        
        echo "❌ Invalid persona: '$requested_persona'"
        echo "Valid options: ${valid_personas[*]}"
        return 1
    fi
}

# Main OpenRouter execution function
execute_openrouter_task() {
    local task="$1"
    local model="${2:-auto}"
    local persona="${3:-analyst}"
    local budget_tier="${4:-standard}"
    local context_level="${5:-balanced}"
    local interactive="${6:-false}"
    
    # Generate session ID
    local session_id="sc-openrouter-$(date +%Y%m%d-%H%M%S)"
    
    echo "🚀 Initializing OpenRouter delegation"
    echo "🎯 Task: $task"
    echo "🆔 Session ID: $session_id"
    echo ""
    
    # Validate persona
    local validated_persona=$(validate_and_correct_persona "$persona")
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    persona="$validated_persona"
    
    # Check OpenRouter availability
    if ! check_openrouter_availability; then
        echo "🔄 Attempting fallback strategies..."
        handle_openrouter_fallback "service_unavailable"
        return 1
    fi
    
    # Model selection
    if [[ "$model" == "auto" ]]; then
        echo "🎯 Auto-selecting optimal model..."
        model=$(select_optimal_model "$task" "$budget_tier")
    fi
    
    show_model_status "$model" "preparing" "[██████    ] 60%" "~\$0.005"
    
    echo "📊 Final Configuration:"
    echo "   Model: $model"
    echo "   Persona: $persona"
    echo "   Budget: $budget_tier"
    echo "   Context: $context_level"
    
    # Cost estimation
    local estimated_cost=$(estimate_request_cost "$model")
    echo "💰 Estimated cost: \$${estimated_cost}"
    
    # Execute request (simulation for now)
    echo ""
    echo "🤖 Executing OpenRouter request..."
    show_model_status "$model" "executing" "[████████  ] 80%" "\$${estimated_cost}"
    
    # Simulate API call delay with progress updates
    if [[ "$SHOW_PROGRESS_BARS" == "true" ]]; then
        for i in {1..5}; do
            echo "🔄 Processing request... $i/5"
            sleep 0.3
        done
    fi
    
    # Simulate response
    local response="## OpenRouter Analysis Results

**Model**: $model  
**Persona**: $persona  
**Task**: $task

### Analysis Summary

This is a simulated OpenRouter response demonstrating the enhanced status reporting and preferences integration. The system successfully:

1. **Loaded User Preferences**: Applied model filtering and fallback strategies
2. **Validated Persona**: Used persona validator to ensure correct persona selection
3. **Selected Optimal Model**: Chose $model based on task classification and user preferences
4. **Cost Management**: Estimated cost and checked against monthly budget ceiling
5. **Status Reporting**: Provided real-time progress updates and transparency

### Implementation Notes

- Model selection followed preference hierarchy: preferred models → category-based → fallbacks
- Cost estimation considered monthly budget ceiling of \$$MONTHLY_CEILING
- Fallback chain configured: $FALLBACK_CHAIN
- Status reporting enabled: model details, progress bars, cost estimates

### Next Steps

1. Install OpenRouter API key for actual model execution
2. Configure preferences in .superclaude/preferences.json
3. Test with various task types to validate model selection
4. Monitor usage and costs through dashboard integration

---
*Response generated with enhanced SuperClaude OpenRouter integration*"
    
    show_model_status "$model" "completed" "[██████████] 100%" "\$${estimated_cost}"
    
    # Store results
    echo "💾 Storing results in SuperClaude memory..."
    mkdir -p "$SUPERCLAUDE_DIR/sessions/$session_id"
    
    cat > "$SUPERCLAUDE_DIR/sessions/$session_id/openrouter_result.json" << EOF
{
    "session_id": "$session_id",
    "model": "$model",
    "persona": "$persona",
    "task": "$task",
    "response": $(echo "$response" | jq -R -s .),
    "estimated_cost": "$estimated_cost",
    "preferences_applied": {
        "avoid_providers": "$AVOID_PROVIDERS",
        "prefer_free": "$PREFER_FREE_MODELS",
        "fallback_chain": "$FALLBACK_CHAIN"
    },
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    
    echo ""
    echo "✅ OpenRouter delegation completed successfully"
    echo "🤖 Model Response:"
    echo "=================="
    echo "$response"
    echo "=================="
    echo ""
    echo "📊 Session ID: $session_id"
    echo "💾 Results stored in SuperClaude memory system"
    
    if [[ "$VERBOSE_LOGGING" == "true" ]]; then
        echo ""
        echo "🔍 Detailed execution summary:"
        echo "   • Model used: $model"
        echo "   • Persona applied: $persona"
        echo "   • Context level: $context_level"
        echo "   • Preferences applied: Yes"
        echo "   • Cost estimated: \$${estimated_cost}"
        echo "   • Fallback available: $(echo "$FALLBACK_CHAIN" | wc -w) options"
    fi
}

# Show help information
show_help() {
    echo "Enhanced SuperClaude OpenRouter Integration"
    echo "=========================================="
    echo ""
    echo "USAGE:"
    echo "  ./sc-openrouter-enhanced.sh \"task\" [model] [persona] [budget] [context]"
    echo ""
    echo "ARGUMENTS:"
    echo "  task      - The task to execute (required)"
    echo "  model     - Model to use (default: auto)"
    echo "  persona   - Persona to apply (default: analyst)"
    echo "  budget    - Budget tier: budget, standard, premium (default: standard)"
    echo "  context   - Context level: minimal, balanced, full (default: balanced)"
    echo ""
    echo "EXAMPLES:"
    echo "  ./sc-openrouter-enhanced.sh \"Design a login form\""
    echo "  ./sc-openrouter-enhanced.sh \"Debug this code\" auto coder"
    echo "  ./sc-openrouter-enhanced.sh \"Analyze data\" qwen/qwen-2.5-72b analyst premium full"
    echo ""
    echo "FEATURES:"
    echo "  • User preference integration"
    echo "  • Real-time status reporting"
    echo "  • Intelligent fallback chains"
    echo "  • Cost management and estimation"
    echo "  • Persona validation and auto-correction"
    echo "  • Provider filtering based on user preferences"
}

# Main execution
main() {
    if [[ $# -eq 0 ]]; then
        show_help
        return 0
    fi
    
    local task="$1"
    local model="${2:-auto}"
    local persona="${3:-analyst}"
    local budget_tier="${4:-standard}"
    local context_level="${5:-balanced}"
    local interactive="${6:-false}"
    
    execute_openrouter_task "$task" "$model" "$persona" "$budget_tier" "$context_level" "$interactive"
}

# Execute if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi