#!/bin/bash
# SuperClaude Cross-Tool Communication Protocol System
# Enables seamless coordination and data sharing between all SuperClaude components

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_PATH="/Users/bbrenner/Documents/Scripting Projects/thehive"
SUPERCLAUDE_DIR="$WORKSPACE_PATH/.superclaude"
PREFERENCES_FILE="$SUPERCLAUDE_DIR/preferences.json"
COMM_DIR="$SUPERCLAUDE_DIR/communications"
MESSAGE_QUEUE_DIR="$COMM_DIR/queues"
SHARED_MEMORY_DIR="$COMM_DIR/memory"
COORDINATION_DIR="$COMM_DIR/coordination"

# Communication protocol version
PROTOCOL_VERSION="2.0"

# Initialize communication system
init_communication_system() {
    echo "🔧 Initializing SuperClaude cross-tool communication system..."
    
    # Create directory structure
    mkdir -p "$COMM_DIR"/{queues,memory,coordination,logs,sessions}
    mkdir -p "$MESSAGE_QUEUE_DIR"/{openrouter,gemini_cli,hive_collective,claude_agents,orchestrator}
    mkdir -p "$SHARED_MEMORY_DIR"/{context,results,preferences,state}
    mkdir -p "$COORDINATION_DIR"/{locks,semaphores,channels}
    
    # Create communication registry
    cat > "$COMM_DIR/registry.json" << EOF
{
    "protocol_version": "$PROTOCOL_VERSION",
    "initialized_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "components": {
        "openrouter": {
            "status": "registered",
            "capabilities": ["model_execution", "cost_optimization", "fallback_coordination"],
            "message_queue": "$MESSAGE_QUEUE_DIR/openrouter",
            "last_heartbeat": null
        },
        "gemini_cli": {
            "status": "registered", 
            "capabilities": ["persona_execution", "research", "content_generation"],
            "message_queue": "$MESSAGE_QUEUE_DIR/gemini_cli",
            "last_heartbeat": null
        },
        "hive_collective": {
            "status": "registered",
            "capabilities": ["consensus_coordination", "swarm_management", "memory_synthesis"],
            "message_queue": "$MESSAGE_QUEUE_DIR/hive_collective",
            "last_heartbeat": null
        },
        "claude_agents": {
            "status": "registered",
            "capabilities": ["native_execution", "fallback_processing", "task_coordination"],
            "message_queue": "$MESSAGE_QUEUE_DIR/claude_agents", 
            "last_heartbeat": null
        },
        "orchestrator": {
            "status": "registered",
            "capabilities": ["multi_tool_coordination", "strategy_management", "session_control"],
            "message_queue": "$MESSAGE_QUEUE_DIR/orchestrator",
            "last_heartbeat": null
        }
    },
    "communication_channels": {
        "broadcast": "$COMM_DIR/broadcast.fifo",
        "coordination": "$COORDINATION_DIR/coord_channel.fifo",
        "emergency": "$COMM_DIR/emergency.fifo"
    }
}
EOF
    
    # Create named pipes for real-time communication
    [[ ! -p "$COMM_DIR/broadcast.fifo" ]] && mkfifo "$COMM_DIR/broadcast.fifo"
    [[ ! -p "$COORDINATION_DIR/coord_channel.fifo" ]] && mkfifo "$COORDINATION_DIR/coord_channel.fifo"
    [[ ! -p "$COMM_DIR/emergency.fifo" ]] && mkfifo "$COMM_DIR/emergency.fifo"
    
    # Create shared state file
    cat > "$SHARED_MEMORY_DIR/state/global_state.json" << EOF
{
    "system_state": "initialized",
    "active_sessions": {},
    "resource_usage": {
        "cpu_usage": 0,
        "memory_usage": 0,
        "api_rate_limits": {}
    },
    "coordination_state": {
        "active_coordinators": 0,
        "pending_operations": 0,
        "fallback_active": false
    },
    "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    
    echo "✅ Communication system initialized"
    echo "📁 Base directory: $COMM_DIR"
    echo "🔧 Protocol version: $PROTOCOL_VERSION"
    echo "📊 Components registered: 5"
}

# Component registration and heartbeat management
register_component() {
    local component_name="$1"
    local capabilities="$2"
    local process_id="$3"
    local session_id="$4"
    
    echo "📝 Registering component: $component_name"
    
    # Update component status in registry
    if command -v jq >/dev/null 2>&1 && [[ -f "$COMM_DIR/registry.json" ]]; then
        local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        
        jq --arg comp "$component_name" \
           --arg ts "$timestamp" \
           --arg pid "$process_id" \
           --arg sid "$session_id" \
           '.components[$comp].status = "active" | 
            .components[$comp].last_heartbeat = $ts |
            .components[$comp].process_id = $pid |
            .components[$comp].session_id = $sid' \
           "$COMM_DIR/registry.json" > "$COMM_DIR/registry.json.tmp" && \
           mv "$COMM_DIR/registry.json.tmp" "$COMM_DIR/registry.json"
    fi
    
    # Create component state file
    mkdir -p "$SHARED_MEMORY_DIR/state"
    cat > "$SHARED_MEMORY_DIR/state/${component_name}_state.json" << EOF
{
    "component": "$component_name",
    "status": "active",
    "process_id": "$process_id",
    "session_id": "$session_id",
    "capabilities": $capabilities,
    "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "last_activity": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "performance_metrics": {
        "operations_completed": 0,
        "success_rate": 1.0,
        "average_response_time": 0.0
    }
}
EOF
    
    echo "✅ Component registered: $component_name (PID: $process_id)"
}

# Send heartbeat from component
send_heartbeat() {
    local component_name="$1"
    local status="${2:-active}"
    local metrics="${3:-{}}"
    
    if [[ -f "$SHARED_MEMORY_DIR/state/${component_name}_state.json" ]] && command -v jq >/dev/null 2>&1; then
        local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        
        jq --arg ts "$timestamp" \
           --arg status "$status" \
           --argjson metrics "$metrics" \
           '.last_activity = $ts | 
            .status = $status |
            if $metrics != {} then .performance_metrics = $metrics else . end' \
           "$SHARED_MEMORY_DIR/state/${component_name}_state.json" > \
           "$SHARED_MEMORY_DIR/state/${component_name}_state.json.tmp" && \
           mv "$SHARED_MEMORY_DIR/state/${component_name}_state.json.tmp" \
              "$SHARED_MEMORY_DIR/state/${component_name}_state.json"
    fi
}

# Message queue operations
send_message() {
    local target_component="$1"
    local message_type="$2"
    local message_body="$3"
    local sender="${4:-system}"
    local priority="${5:-normal}"
    local correlation_id="${6:-$(date +%s%N)}"
    
    echo "📤 Sending message to $target_component..."
    
    # Create message envelope
    local message="{
        \"id\": \"$correlation_id\",
        \"type\": \"$message_type\",
        \"sender\": \"$sender\",
        \"target\": \"$target_component\",
        \"priority\": \"$priority\",
        \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
        \"body\": $message_body
    }"
    
    # Determine queue path
    local queue_dir="$MESSAGE_QUEUE_DIR/$target_component"
    mkdir -p "$queue_dir"
    
    # Priority-based file naming for simple queue ordering
    local priority_prefix=""
    case "$priority" in
        "critical") priority_prefix="0_" ;;
        "high") priority_prefix="1_" ;;
        "normal") priority_prefix="2_" ;;
        "low") priority_prefix="3_" ;;
    esac
    
    local message_file="${queue_dir}/${priority_prefix}${correlation_id}.json"
    echo "$message" > "$message_file"
    
    # Log message
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) SEND $sender->$target_component $message_type $correlation_id" >> \
        "$COMM_DIR/logs/message_log.txt"
    
    echo "   Message ID: $correlation_id"
    echo "   Type: $message_type"
    echo "   Priority: $priority"
    echo "✅ Message queued successfully"
}

# Receive messages from queue
receive_messages() {
    local component_name="$1"
    local max_messages="${2:-10}"
    local timeout="${3:-1}"
    
    local queue_dir="$MESSAGE_QUEUE_DIR/$component_name"
    
    if [[ ! -d "$queue_dir" ]]; then
        echo "❌ No message queue found for component: $component_name"
        return 1
    fi
    
    echo "📥 Checking messages for $component_name..."
    
    local message_count=0
    local processed_messages=()
    
    # Process messages in priority order
    for message_file in "$queue_dir"/*.json; do
        if [[ ! -f "$message_file" ]]; then
            continue
        fi
        
        if [[ $message_count -ge $max_messages ]]; then
            break
        fi
        
        echo "📨 Processing message: $(basename "$message_file")"
        
        if command -v jq >/dev/null 2>&1; then
            local message_id=$(jq -r '.id' "$message_file" 2>/dev/null)
            local message_type=$(jq -r '.type' "$message_file" 2>/dev/null)
            local sender=$(jq -r '.sender' "$message_file" 2>/dev/null)
            local timestamp=$(jq -r '.timestamp' "$message_file" 2>/dev/null)
            
            echo "   ID: $message_id"
            echo "   Type: $message_type"
            echo "   From: $sender"
            echo "   Time: $timestamp"
            
            # Process based on message type
            process_message "$component_name" "$message_file"
            
            # Move processed message to archive
            local archive_dir="$COMM_DIR/logs/processed"
            mkdir -p "$archive_dir"
            mv "$message_file" "$archive_dir/"
            
            processed_messages+=("$message_id")
            message_count=$((message_count + 1))
            
            # Log message processing
            echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) RECV $component_name<-$sender $message_type $message_id" >> \
                "$COMM_DIR/logs/message_log.txt"
        fi
    done
    
    echo "📊 Processed $message_count messages"
    if [[ ${#processed_messages[@]} -gt 0 ]]; then
        echo "   Message IDs: ${processed_messages[*]}"
    fi
    
    return $message_count
}

# Process individual message based on type
process_message() {
    local component_name="$1"
    local message_file="$2"
    
    if ! command -v jq >/dev/null 2>&1; then
        echo "⚠️ jq not available - cannot process message"
        return 1
    fi
    
    local message_type=$(jq -r '.type' "$message_file")
    local message_body=$(jq -r '.body' "$message_file")
    local sender=$(jq -r '.sender' "$message_file")
    local correlation_id=$(jq -r '.id' "$message_file")
    
    echo "🔄 Processing message type: $message_type"
    
    case "$message_type" in
        "task_request")
            handle_task_request "$component_name" "$message_body" "$sender" "$correlation_id"
            ;;
        "status_update")
            handle_status_update "$component_name" "$message_body" "$sender"
            ;;
        "coordination_request")
            handle_coordination_request "$component_name" "$message_body" "$sender" "$correlation_id"
            ;;
        "fallback_trigger")
            handle_fallback_trigger "$component_name" "$message_body" "$sender" "$correlation_id"
            ;;
        "resource_request")
            handle_resource_request "$component_name" "$message_body" "$sender" "$correlation_id"
            ;;
        "context_share")
            handle_context_share "$component_name" "$message_body" "$sender"
            ;;
        "heartbeat")
            handle_heartbeat_message "$component_name" "$message_body" "$sender"
            ;;
        "shutdown")
            handle_shutdown_message "$component_name" "$message_body" "$sender"
            ;;
        *)
            echo "⚠️ Unknown message type: $message_type"
            # Store unknown message for analysis
            mkdir -p "$COMM_DIR/logs/unknown"
            cp "$message_file" "$COMM_DIR/logs/unknown/"
            ;;
    esac
}

# Message type handlers
handle_task_request() {
    local component="$1"
    local task_body="$2"
    local requester="$3" 
    local correlation_id="$4"
    
    echo "📋 Handling task request from $requester"
    
    # Extract task details
    if command -v jq >/dev/null 2>&1; then
        local task_type=$(echo "$task_body" | jq -r '.task_type // "unknown"')
        local task_description=$(echo "$task_body" | jq -r '.description // "No description"')
        local priority=$(echo "$task_body" | jq -r '.priority // "normal"')
        local session_id=$(echo "$task_body" | jq -r '.session_id // "unknown"')
        
        echo "   Task Type: $task_type"
        echo "   Description: $task_description"
        echo "   Priority: $priority"
        echo "   Session: $session_id"
        
        # Store task for component processing
        local task_file="$SHARED_MEMORY_DIR/context/${component}_task_${correlation_id}.json"
        echo "$task_body" > "$task_file"
        
        # Send acknowledgment
        local ack_response="{
            \"status\": \"accepted\",
            \"component\": \"$component\",
            \"correlation_id\": \"$correlation_id\",
            \"estimated_completion\": \"$(date -d '+30 seconds' -u +%Y-%m-%dT%H:%M:%SZ)\"
        }"
        
        send_message "$requester" "task_acknowledgment" "$ack_response" "$component" "high" "$correlation_id"
        
        echo "✅ Task request handled and acknowledged"
    fi
}

handle_status_update() {
    local component="$1"
    local status_body="$2"
    local sender="$3"
    
    echo "📊 Handling status update from $sender"
    
    # Update sender's status in shared memory
    if command -v jq >/dev/null 2>&1; then
        local status=$(echo "$status_body" | jq -r '.status // "unknown"')
        local operation=$(echo "$status_body" | jq -r '.current_operation // "none"')
        local progress=$(echo "$status_body" | jq -r '.progress // 0')
        
        echo "   Status: $status"
        echo "   Operation: $operation"
        echo "   Progress: $progress%"
        
        # Update global status tracking
        local status_file="$SHARED_MEMORY_DIR/state/component_status.json"
        if [[ ! -f "$status_file" ]]; then
            echo '{}' > "$status_file"
        fi
        
        jq --arg sender "$sender" \
           --arg status "$status" \
           --arg operation "$operation" \
           --arg progress "$progress" \
           --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
           '.[$sender] = {
               "status": $status,
               "current_operation": $operation,
               "progress": $progress,
               "last_update": $timestamp
           }' "$status_file" > "${status_file}.tmp" && \
           mv "${status_file}.tmp" "$status_file"
    fi
}

handle_coordination_request() {
    local component="$1"
    local coord_body="$2"
    local requester="$3"
    local correlation_id="$4"
    
    echo "🤝 Handling coordination request from $requester"
    
    if command -v jq >/dev/null 2>&1; then
        local coordination_type=$(echo "$coord_body" | jq -r '.type // "unknown"')
        local participants=$(echo "$coord_body" | jq -r '.participants // []')
        local objective=$(echo "$coord_body" | jq -r '.objective // "No objective"')
        
        echo "   Type: $coordination_type"
        echo "   Objective: $objective"
        
        case "$coordination_type" in
            "multi_tool_execution")
                coordinate_multi_tool_execution "$coord_body" "$requester" "$correlation_id"
                ;;
            "resource_sharing")
                coordinate_resource_sharing "$coord_body" "$requester" "$correlation_id"
                ;;
            "fallback_coordination")
                coordinate_fallback_strategy "$coord_body" "$requester" "$correlation_id"
                ;;
            *)
                echo "⚠️ Unknown coordination type: $coordination_type"
                ;;
        esac
    fi
}

handle_fallback_trigger() {
    local component="$1"
    local fallback_body="$2"
    local trigger_source="$3"
    local correlation_id="$4"
    
    echo "🔄 Handling fallback trigger from $trigger_source"
    
    if command -v jq >/dev/null 2>&1; then
        local failed_service=$(echo "$fallback_body" | jq -r '.failed_service // "unknown"')
        local failure_reason=$(echo "$fallback_body" | jq -r '.failure_reason // "unknown"')
        local original_task=$(echo "$fallback_body" | jq -r '.original_task // ""')
        local fallback_preferences=$(echo "$fallback_body" | jq -r '.fallback_preferences // "default"')
        
        echo "   Failed Service: $failed_service"
        echo "   Failure Reason: $failure_reason"
        echo "   Original Task: $original_task"
        
        # Trigger fallback coordinator if available
        if [[ -f "$SCRIPT_DIR/fallback-coordinator.sh" ]]; then
            echo "🚀 Activating fallback coordinator..."
            
            # Extract persona and other details
            local persona=$(echo "$fallback_body" | jq -r '.persona // "analyst"')
            
            # Execute fallback in background and track
            "$SCRIPT_DIR/fallback-coordinator.sh" execute "$original_task" "$persona" "$failed_service" "$failure_reason" &
            local fallback_pid=$!
            
            # Store fallback coordination info
            local fallback_info="{
                \"correlation_id\": \"$correlation_id\",
                \"trigger_source\": \"$trigger_source\", 
                \"failed_service\": \"$failed_service\",
                \"fallback_pid\": $fallback_pid,
                \"status\": \"active\",
                \"started_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
            }"
            
            echo "$fallback_info" > "$COORDINATION_DIR/fallback_${correlation_id}.json"
            
            echo "✅ Fallback coordination initiated (PID: $fallback_pid)"
        else
            echo "❌ Fallback coordinator not available"
        fi
    fi
}

handle_resource_request() {
    local component="$1"
    local resource_body="$2"
    local requester="$3"
    local correlation_id="$4"
    
    echo "📦 Handling resource request from $requester"
    
    if command -v jq >/dev/null 2>&1; then
        local resource_type=$(echo "$resource_body" | jq -r '.resource_type // "unknown"')
        local amount_requested=$(echo "$resource_body" | jq -r '.amount // 1')
        local duration=$(echo "$resource_body" | jq -r '.duration_minutes // 5')
        
        echo "   Resource Type: $resource_type"
        echo "   Amount: $amount_requested"
        echo "   Duration: $duration minutes"
        
        # Simple resource allocation (could be enhanced with actual resource management)
        local allocation_response="{
            \"status\": \"granted\",
            \"resource_type\": \"$resource_type\",
            \"allocated_amount\": $amount_requested,
            \"allocation_id\": \"alloc_${correlation_id}\",
            \"expires_at\": \"$(date -d "+${duration} minutes" -u +%Y-%m-%dT%H:%M:%SZ)\"
        }"
        
        # Store allocation
        echo "$allocation_response" > "$SHARED_MEMORY_DIR/state/allocation_${correlation_id}.json"
        
        # Send response
        send_message "$requester" "resource_allocation" "$allocation_response" "$component" "high" "$correlation_id"
        
        echo "✅ Resource allocated and response sent"
    fi
}

handle_context_share() {
    local component="$1"
    local context_body="$2"
    local sender="$3"
    
    echo "🔄 Handling context share from $sender"
    
    if command -v jq >/dev/null 2>&1; then
        local context_type=$(echo "$context_body" | jq -r '.context_type // "general"')
        local session_id=$(echo "$context_body" | jq -r '.session_id // "unknown"')
        local context_data=$(echo "$context_body" | jq -r '.data // {}')
        
        echo "   Context Type: $context_type"
        echo "   Session: $session_id"
        
        # Store shared context
        local context_file="$SHARED_MEMORY_DIR/context/${session_id}_${context_type}_from_${sender}.json"
        echo "$context_body" > "$context_file"
        
        echo "✅ Context stored and available for sharing"
    fi
}

handle_heartbeat_message() {
    local component="$1"
    local heartbeat_body="$2"
    local sender="$3"
    
    # Update heartbeat without verbose logging
    send_heartbeat "$sender" "active" "$heartbeat_body"
}

handle_shutdown_message() {
    local component="$1"
    local shutdown_body="$2"
    local sender="$3"
    
    echo "🛑 Handling shutdown message from $sender"
    
    # Update component status to shutting down
    send_heartbeat "$sender" "shutting_down"
    
    # Clean up any resources allocated to this component
    cleanup_component_resources "$sender"
    
    echo "✅ Shutdown handling completed for $sender"
}

# Multi-tool coordination handlers
coordinate_multi_tool_execution() {
    local coord_body="$1"
    local requester="$2"
    local correlation_id="$3"
    
    echo "🎯 Coordinating multi-tool execution..."
    
    if command -v jq >/dev/null 2>&1; then
        local strategy=$(echo "$coord_body" | jq -r '.strategy // "sequential"')
        local tools=$(echo "$coord_body" | jq -r '.tools // []')
        local objective=$(echo "$coord_body" | jq -r '.objective // ""')
        
        echo "   Strategy: $strategy"
        echo "   Objective: $objective"
        
        # Create coordination session
        local coord_session="{
            \"correlation_id\": \"$correlation_id\",
            \"requester\": \"$requester\",
            \"strategy\": \"$strategy\",
            \"tools\": $tools,
            \"objective\": \"$objective\",
            \"status\": \"active\",
            \"started_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
            \"tool_status\": {}
        }"
        
        echo "$coord_session" > "$COORDINATION_DIR/session_${correlation_id}.json"
        
        # Execute coordination strategy
        case "$strategy" in
            "sequential")
                execute_sequential_coordination "$correlation_id" "$tools" "$objective"
                ;;
            "parallel")
                execute_parallel_coordination "$correlation_id" "$tools" "$objective"
                ;;
            "hierarchical")
                execute_hierarchical_coordination "$correlation_id" "$tools" "$objective"
                ;;
        esac
        
        echo "✅ Multi-tool coordination initiated"
    fi
}

coordinate_resource_sharing() {
    local coord_body="$1"
    local requester="$2"
    local correlation_id="$3"
    
    echo "📊 Coordinating resource sharing..."
    
    # Simple resource sharing coordination
    local sharing_response="{
        \"status\": \"coordinated\",
        \"sharing_plan\": \"round_robin\",
        \"participants\": [],
        \"coordinator\": \"cross_tool_comms\"
    }"
    
    send_message "$requester" "resource_coordination_response" "$sharing_response" "cross_tool_comms" "normal" "$correlation_id"
}

coordinate_fallback_strategy() {
    local coord_body="$1"
    local requester="$2"
    local correlation_id="$3"
    
    echo "🔄 Coordinating fallback strategy..."
    
    # Extract fallback details and coordinate
    if [[ -f "$SCRIPT_DIR/fallback-coordinator.sh" ]]; then
        local fallback_response="{
            \"status\": \"fallback_coordinated\",
            \"fallback_chain\": [\"openrouter_free\", \"gemini_cli\", \"claude_agents\", \"hive_collective\"],
            \"coordinator\": \"fallback_coordinator.sh\"
        }"
        
        send_message "$requester" "fallback_coordination_response" "$fallback_response" "cross_tool_comms" "high" "$correlation_id"
    fi
}

# Coordination execution strategies
execute_sequential_coordination() {
    local correlation_id="$1"
    local tools="$2"
    local objective="$3"
    
    echo "📋 Executing sequential coordination strategy..."
    
    # This would implement sequential tool coordination
    # For now, we'll simulate the coordination
    echo "   ⏭️ Sequential execution planned for tools: $tools"
    
    # Update coordination status
    if command -v jq >/dev/null 2>&1 && [[ -f "$COORDINATION_DIR/session_${correlation_id}.json" ]]; then
        jq '.status = "executing_sequential"' \
           "$COORDINATION_DIR/session_${correlation_id}.json" > \
           "$COORDINATION_DIR/session_${correlation_id}.json.tmp" && \
           mv "$COORDINATION_DIR/session_${correlation_id}.json.tmp" \
              "$COORDINATION_DIR/session_${correlation_id}.json"
    fi
}

execute_parallel_coordination() {
    local correlation_id="$1"
    local tools="$2"
    local objective="$3"
    
    echo "🔀 Executing parallel coordination strategy..."
    echo "   ⚡ Parallel execution planned for tools: $tools"
    
    # Update coordination status
    if command -v jq >/dev/null 2>&1 && [[ -f "$COORDINATION_DIR/session_${correlation_id}.json" ]]; then
        jq '.status = "executing_parallel"' \
           "$COORDINATION_DIR/session_${correlation_id}.json" > \
           "$COORDINATION_DIR/session_${correlation_id}.json.tmp" && \
           mv "$COORDINATION_DIR/session_${correlation_id}.json.tmp" \
              "$COORDINATION_DIR/session_${correlation_id}.json"
    fi
}

execute_hierarchical_coordination() {
    local correlation_id="$1"
    local tools="$2"
    local objective="$3"
    
    echo "🏗️ Executing hierarchical coordination strategy..."
    echo "   🎯 Hierarchical execution planned for tools: $tools"
    
    # Update coordination status
    if command -v jq >/dev/null 2>&1 && [[ -f "$COORDINATION_DIR/session_${correlation_id}.json" ]]; then
        jq '.status = "executing_hierarchical"' \
           "$COORDINATION_DIR/session_${correlation_id}.json" > \
           "$COORDINATION_DIR/session_${correlation_id}.json.tmp" && \
           mv "$COORDINATION_DIR/session_${correlation_id}.json.tmp" \
              "$COORDINATION_DIR/session_${correlation_id}.json"
    fi
}

# Broadcast message to all components
broadcast_message() {
    local message_type="$1"
    local message_body="$2"
    local sender="${3:-system}"
    local priority="${4:-normal}"
    
    echo "📢 Broadcasting message: $message_type"
    
    # Get all registered components
    if command -v jq >/dev/null 2>&1 && [[ -f "$COMM_DIR/registry.json" ]]; then
        local components=($(jq -r '.components | keys[]' "$COMM_DIR/registry.json"))
        
        for component in "${components[@]}"; do
            if [[ "$component" != "$sender" ]]; then
                local correlation_id="broadcast_$(date +%s%N)"
                send_message "$component" "$message_type" "$message_body" "$sender" "$priority" "$correlation_id"
            fi
        done
        
        echo "✅ Message broadcasted to ${#components[@]} components"
    fi
}

# System health and monitoring
check_system_health() {
    echo "🏥 SuperClaude Cross-Tool Communication Health Check"
    echo "================================================="
    echo ""
    
    # Check communication directory structure
    local health_score=0
    local total_checks=0
    
    echo "📁 Directory Structure:"
    for dir in "$COMM_DIR" "$MESSAGE_QUEUE_DIR" "$SHARED_MEMORY_DIR" "$COORDINATION_DIR"; do
        total_checks=$((total_checks + 1))
        if [[ -d "$dir" ]]; then
            echo "   ✅ $dir"
            health_score=$((health_score + 1))
        else
            echo "   ❌ $dir"
        fi
    done
    
    echo ""
    echo "🔧 Communication Channels:"
    for pipe in "$COMM_DIR/broadcast.fifo" "$COORDINATION_DIR/coord_channel.fifo" "$COMM_DIR/emergency.fifo"; do
        total_checks=$((total_checks + 1))
        if [[ -p "$pipe" ]]; then
            echo "   ✅ $(basename "$pipe")"
            health_score=$((health_score + 1))
        else
            echo "   ❌ $(basename "$pipe")"
        fi
    done
    
    echo ""
    echo "📊 Component Status:"
    if command -v jq >/dev/null 2>&1 && [[ -f "$COMM_DIR/registry.json" ]]; then
        local components=($(jq -r '.components | keys[]' "$COMM_DIR/registry.json"))
        
        for component in "${components[@]}"; do
            total_checks=$((total_checks + 1))
            local status="unknown"
            local last_heartbeat="never"
            
            if [[ -f "$SHARED_MEMORY_DIR/state/${component}_state.json" ]]; then
                status=$(jq -r '.status // "unknown"' "$SHARED_MEMORY_DIR/state/${component}_state.json")
                last_heartbeat=$(jq -r '.last_activity // "never"' "$SHARED_MEMORY_DIR/state/${component}_state.json")
                
                if [[ "$status" == "active" ]]; then
                    echo "   ✅ $component: $status (last: $last_heartbeat)"
                    health_score=$((health_score + 1))
                else
                    echo "   ⚠️ $component: $status (last: $last_heartbeat)"
                fi
            else
                echo "   ❌ $component: No state file"
            fi
        done
    fi
    
    echo ""
    echo "📈 Message Queue Status:"
    for queue_dir in "$MESSAGE_QUEUE_DIR"/*; do
        if [[ -d "$queue_dir" ]]; then
            local component=$(basename "$queue_dir")
            local message_count=$(find "$queue_dir" -name "*.json" 2>/dev/null | wc -l)
            echo "   📬 $component: $message_count pending messages"
        fi
    done
    
    echo ""
    echo "🏥 Overall System Health:"
    local health_percentage=$(( health_score * 100 / total_checks ))
    echo "   Health Score: $health_score/$total_checks ($health_percentage%)"
    
    if [[ $health_percentage -ge 90 ]]; then
        echo "   🟢 System Status: Excellent"
    elif [[ $health_percentage -ge 75 ]]; then
        echo "   🟡 System Status: Good"
    elif [[ $health_percentage -ge 50 ]]; then
        echo "   🟠 System Status: Degraded"
    else
        echo "   🔴 System Status: Critical"
    fi
}

# Cleanup component resources
cleanup_component_resources() {
    local component="$1"
    
    echo "🧹 Cleaning up resources for $component..."
    
    # Clean up message queue
    if [[ -d "$MESSAGE_QUEUE_DIR/$component" ]]; then
        rm -f "$MESSAGE_QUEUE_DIR/$component"/*.json
        echo "   🗑️ Message queue cleaned"
    fi
    
    # Clean up state files
    if [[ -f "$SHARED_MEMORY_DIR/state/${component}_state.json" ]]; then
        jq '.status = "stopped"' "$SHARED_MEMORY_DIR/state/${component}_state.json" > \
           "$SHARED_MEMORY_DIR/state/${component}_state.json.tmp" && \
           mv "$SHARED_MEMORY_DIR/state/${component}_state.json.tmp" \
              "$SHARED_MEMORY_DIR/state/${component}_state.json"
        echo "   🔄 Component status updated to stopped"
    fi
    
    # Clean up shared contexts
    rm -f "$SHARED_MEMORY_DIR/context"/*_from_${component}.json
    rm -f "$SHARED_MEMORY_DIR/context"/${component}_*.json
    
    echo "✅ Resource cleanup completed for $component"
}

# Show help information
show_help() {
    echo "SuperClaude Cross-Tool Communication System"
    echo "==========================================="
    echo ""
    echo "USAGE:"
    echo "  ./cross-tool-comms.sh COMMAND [OPTIONS]"
    echo ""
    echo "COMMANDS:"
    echo "  init                                    Initialize communication system"
    echo "  register COMPONENT CAPABILITIES PID    Register component with system"
    echo "  send TARGET TYPE BODY [SENDER] [PRIORITY]  Send message to component"
    echo "  receive COMPONENT [MAX] [TIMEOUT]      Receive messages for component"
    echo "  broadcast TYPE BODY [SENDER]           Broadcast message to all components"
    echo "  heartbeat COMPONENT [STATUS] [METRICS] Send component heartbeat"
    echo "  health                                  Check system health status"
    echo "  cleanup COMPONENT                       Clean up component resources"
    echo ""
    echo "EXAMPLES:"
    echo "  # Initialize the communication system"
    echo "  ./cross-tool-comms.sh init"
    echo ""
    echo "  # Register a component"
    echo "  ./cross-tool-comms.sh register openrouter '[\"model_execution\"]' 12345"
    echo ""
    echo "  # Send a message"
    echo "  ./cross-tool-comms.sh send openrouter task_request '{\"task\":\"analyze code\"}'"
    echo ""
    echo "  # Receive messages"
    echo "  ./cross-tool-comms.sh receive openrouter 5"
    echo ""
    echo "  # Broadcast system message"
    echo "  ./cross-tool-comms.sh broadcast system_alert '{\"alert\":\"maintenance\"}'"
    echo ""
    echo "  # Send heartbeat"
    echo "  ./cross-tool-comms.sh heartbeat openrouter active"
    echo ""
    echo "  # Check system health"
    echo "  ./cross-tool-comms.sh health"
    echo ""
    echo "FEATURES:"
    echo "  • Message queue system with priority handling"
    echo "  • Shared memory for context and state management"
    echo "  • Component registration and health monitoring"
    echo "  • Multi-tool coordination protocols"
    echo "  • Fallback coordination integration"
    echo "  • Broadcast messaging for system-wide alerts"
}

# Main command dispatcher
main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        "init")
            init_communication_system
            ;;
        "register")
            if [[ $# -lt 3 ]]; then
                echo "❌ Usage: $0 register COMPONENT CAPABILITIES PID [SESSION_ID]"
                return 1
            fi
            register_component "$1" "$2" "$3" "${4:-unknown}"
            ;;
        "send")
            if [[ $# -lt 3 ]]; then
                echo "❌ Usage: $0 send TARGET TYPE BODY [SENDER] [PRIORITY]"
                return 1
            fi
            send_message "$1" "$2" "$3" "${4:-system}" "${5:-normal}"
            ;;
        "receive")
            if [[ $# -lt 1 ]]; then
                echo "❌ Usage: $0 receive COMPONENT [MAX_MESSAGES] [TIMEOUT]"
                return 1
            fi
            receive_messages "$1" "${2:-10}" "${3:-1}"
            ;;
        "broadcast")
            if [[ $# -lt 2 ]]; then
                echo "❌ Usage: $0 broadcast TYPE BODY [SENDER] [PRIORITY]"
                return 1
            fi
            broadcast_message "$1" "$2" "${3:-system}" "${4:-normal}"
            ;;
        "heartbeat")
            if [[ $# -lt 1 ]]; then
                echo "❌ Usage: $0 heartbeat COMPONENT [STATUS] [METRICS]"
                return 1
            fi
            send_heartbeat "$1" "${2:-active}" "${3:-{}}"
            ;;
        "health")
            check_system_health
            ;;
        "cleanup")
            if [[ $# -lt 1 ]]; then
                echo "❌ Usage: $0 cleanup COMPONENT"
                return 1
            fi
            cleanup_component_resources "$1"
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