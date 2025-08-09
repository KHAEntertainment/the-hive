#!/bin/bash
# Persona Validation System for SuperClaude
# Prevents persona name mismatches and provides auto-correction

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFERENCES_FILE="/Users/bbrenner/Documents/Scripting Projects/thehive/.superclaude/preferences.json"

# Valid persona list
VALID_PERSONAS=("designer" "researcher" "coder" "analyst" "writer" "reviewer")

# Load user preferences
load_preferences() {
    if [[ -f "$PREFERENCES_FILE" ]]; then
        echo "$PREFERENCES_FILE"
    else
        echo ""
    fi
}

# Get persona aliases from preferences
get_persona_aliases() {
    local prefs_file="$1"
    
    if [[ -f "$prefs_file" ]]; then
        # Extract aliases using jq if available
        if command -v jq >/dev/null 2>&1; then
            jq -r '.user_preferences.persona_validation.common_aliases | to_entries[] | "\(.key):\(.value)"' "$prefs_file" 2>/dev/null || echo ""
        else
            # Fallback: hardcoded aliases if jq not available
            cat << EOF
code-assistant:coder
code assistant:coder
coding:coder
development:coder
design:designer
ui:designer
ux:designer
research:researcher
analysis:analyst
writing:writer
documentation:writer
review:reviewer
quality:reviewer
EOF
        fi
    else
        # Default aliases
        cat << EOF
code-assistant:coder
code assistant:coder
coding:coder
development:coder
design:designer
ui:designer
ux:designer
research:researcher
analysis:analyst
writing:writer
documentation:writer
review:reviewer
quality:reviewer
EOF
    fi
}

# Validate and potentially correct persona name
validate_persona() {
    local requested_persona="$1"
    local prefs_file=$(load_preferences)
    local auto_correct=true
    local suggest_alternatives=true
    
    # Load settings from preferences if available
    if [[ -f "$prefs_file" ]] && command -v jq >/dev/null 2>&1; then
        auto_correct=$(jq -r '.user_preferences.persona_validation.auto_correct // true' "$prefs_file" 2>/dev/null)
        suggest_alternatives=$(jq -r '.user_preferences.persona_validation.suggest_alternatives // true' "$prefs_file" 2>/dev/null)
    fi
    
    # Convert to lowercase for comparison
    local requested_lower=$(echo "$requested_persona" | tr '[:upper:]' '[:lower:]')
    
    # Check if it's already a valid persona
    for valid_persona in "${VALID_PERSONAS[@]}"; do
        if [[ "$requested_lower" == "$valid_persona" ]]; then
            echo "$valid_persona"
            return 0
        fi
    done
    
    # Check aliases for auto-correction
    if [[ "$auto_correct" == "true" ]]; then
        local aliases=$(get_persona_aliases "$prefs_file")
        
        while IFS=':' read -r alias target; do
            if [[ "$requested_lower" == "$alias" ]]; then
                echo "🔄 Auto-correcting persona: '$requested_persona' → '$target'" >&2
                echo "$target"
                return 0
            fi
        done <<< "$aliases"
    fi
    
    # Persona not found - provide suggestions
    echo "❌ Error: Persona '$requested_persona' not recognized" >&2
    
    if [[ "$suggest_alternatives" == "true" ]]; then
        echo "" >&2
        echo "📝 Available personas:" >&2
        for persona in "${VALID_PERSONAS[@]}"; do
            echo "   • $persona" >&2
        done
        
        echo "" >&2
        echo "💡 Common alternatives:" >&2
        local aliases=$(get_persona_aliases "$prefs_file")
        while IFS=':' read -r alias target; do
            echo "   • '$alias' → '$target'" >&2
        done <<< "$aliases"
        
        echo "" >&2
        echo "🔍 Did you mean one of these?" >&2
        
        # Simple fuzzy matching - find personas that start with same letter
        local first_char="${requested_lower:0:1}"
        for persona in "${VALID_PERSONAS[@]}"; do
            if [[ "${persona:0:1}" == "$first_char" ]]; then
                echo "   → $persona" >&2
            fi
        done
    fi
    
    return 1
}

# Check if persona validation is enabled
is_validation_enabled() {
    local prefs_file=$(load_preferences)
    
    if [[ -f "$prefs_file" ]] && command -v jq >/dev/null 2>&1; then
        local enabled=$(jq -r '.user_preferences.persona_validation.enabled // true' "$prefs_file" 2>/dev/null)
        [[ "$enabled" == "true" ]]
    else
        # Default to enabled
        return 0
    fi
}

# Get corrected persona or exit with error
get_validated_persona() {
    local requested="$1"
    
    if ! is_validation_enabled; then
        echo "$requested"
        return 0
    fi
    
    local validated=$(validate_persona "$requested")
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        echo "$validated"
        return 0
    else
        echo "" >&2
        echo "💡 Use '--persona <valid_persona>' with one of the recognized personas above." >&2
        return 1
    fi
}

# Interactive persona selection
interactive_persona_selection() {
    echo "🤖 Persona Selection" >&2
    echo "===================" >&2
    echo "" >&2
    
    local i=1
    for persona in "${VALID_PERSONAS[@]}"; do
        echo "$i) $persona" >&2
        ((i++))
    done
    
    echo "" >&2
    read -p "Select persona (1-${#VALID_PERSONAS[@]}): " -r selection
    
    if [[ "$selection" =~ ^[1-6]$ ]]; then
        local index=$((selection - 1))
        echo "${VALID_PERSONAS[$index]}"
        return 0
    else
        echo "❌ Invalid selection" >&2
        return 1
    fi
}

# List all valid personas
list_personas() {
    echo "📋 Valid SuperClaude Personas:"
    echo "============================="
    for persona in "${VALID_PERSONAS[@]}"; do
        echo "• $persona"
    done
    
    local prefs_file=$(load_preferences)
    if [[ -f "$prefs_file" ]]; then
        echo ""
        echo "🔄 Auto-correction aliases:"
        echo "=========================="
        local aliases=$(get_persona_aliases "$prefs_file")
        while IFS=':' read -r alias target; do
            printf "• %-20s → %s\n" "$alias" "$target"
        done <<< "$aliases"
    fi
}

# Update persona preferences
update_persona_preferences() {
    local prefs_file=$(load_preferences)
    
    if [[ ! -f "$prefs_file" ]]; then
        echo "❌ Preferences file not found: $prefs_file" >&2
        return 1
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        echo "❌ jq is required for updating preferences" >&2
        return 1
    fi
    
    echo "🔧 Persona preference configuration coming soon..." >&2
    echo "📝 Edit $prefs_file manually for now" >&2
}

# Main command dispatcher
main() {
    case "${1:-validate}" in
        "validate")
            if [[ -z "$2" ]]; then
                echo "Usage: $0 validate <persona_name>" >&2
                return 1
            fi
            get_validated_persona "$2"
            ;;
        "list")
            list_personas
            ;;
        "interactive"|"select")
            interactive_persona_selection
            ;;
        "test")
            # Test mode - validate all provided personas
            shift
            local all_valid=true
            for persona in "$@"; do
                echo -n "Testing '$persona': "
                if result=$(get_validated_persona "$persona" 2>/dev/null); then
                    echo "✅ $result"
                else
                    echo "❌ Invalid"
                    all_valid=false
                fi
            done
            if [[ "$all_valid" == "true" ]]; then
                return 0
            else
                return 1
            fi
            ;;
        "config")
            update_persona_preferences
            ;;
        "help"|"-h"|"--help")
            echo "SuperClaude Persona Validator"
            echo "============================="
            echo ""
            echo "Usage:"
            echo "  $0 validate <persona_name>    # Validate and correct persona name"
            echo "  $0 list                       # List all valid personas and aliases"  
            echo "  $0 interactive                # Interactive persona selection"
            echo "  $0 test <persona1> [persona2] # Test multiple personas"
            echo "  $0 config                     # Update persona preferences"
            echo "  $0 help                       # Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 validate \"code assistant\"  # Returns: coder"
            echo "  $0 validate designer          # Returns: designer"
            echo "  $0 test coder analyst invalid # Test multiple personas"
            ;;
        *)
            echo "❌ Unknown command: $1" >&2
            echo "Use '$0 help' for usage information" >&2
            return 1
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi