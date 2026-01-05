#!/bin/bash
#
# ralph-opencode.sh - Autonomous OpenCode development loop
#
# Ralph technique adapted for OpenCode (sst/opencode).
# Runs autonomous AI development iterations with timing stats.
#
# Usage: ./ralph-opencode.sh [max_iterations] [project_dir]
# Default: 50 iterations, current directory
#
# Example:
#   ./ralph-opencode.sh 25 /path/to/project
#

MAX_ITERATIONS=${1:-50}
PROJECT_DIR=${2:-.}
ITERATION=0
PROMPT_FILE="$PROJECT_DIR/.claude/RALPH_PROMPT.md"
CLAUDE_MD="$PROJECT_DIR/CLAUDE.md"
OPENCODE_MD="$PROJECT_DIR/.opencode/instructions.md"
START_TIME=$(date +%s)

# Function to format seconds as HH:MM:SS
format_time() {
    local total_seconds=$1
    local hours=$((total_seconds / 3600))
    local minutes=$(( (total_seconds % 3600) / 60 ))
    local seconds=$((total_seconds % 60))
    printf "%02d:%02d:%02d" $hours $minutes $seconds
}

# Function to display stats
show_stats() {
    local current_time=$(date +%s)
    local elapsed=$((current_time - START_TIME))
    local elapsed_formatted=$(format_time $elapsed)

    if [ $ITERATION -gt 0 ]; then
        local avg_per_iteration=$((elapsed / ITERATION))
        local remaining_iterations=$((MAX_ITERATIONS - ITERATION))
        local estimated_remaining=$((avg_per_iteration * remaining_iterations))
        local estimated_formatted=$(format_time $estimated_remaining)
        local total_estimated=$((elapsed + estimated_remaining))
        local total_formatted=$(format_time $total_estimated)

        echo "├─ Elapsed: $elapsed_formatted"
        echo "├─ Avg per iteration: $(format_time $avg_per_iteration)"
        echo "├─ Est. remaining: $estimated_formatted"
        echo "└─ Est. total: $total_formatted"
    else
        echo "└─ Elapsed: $elapsed_formatted"
    fi
}

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║        RALPH LOOP - OpenCode Autonomous Development       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Max iterations: $MAX_ITERATIONS"
echo "Project directory: $PROJECT_DIR"
echo "Prompt file: $PROMPT_FILE"
echo "CLAUDE.md: $([ -f "$CLAUDE_MD" ] && echo "Found ✓" || echo "Not found")"
echo "OpenCode instructions: $([ -f "$OPENCODE_MD" ] && echo "Found ✓" || echo "Not found")"
echo "Started at: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Press Ctrl+C to stop"
echo ""

# Check prompt file exists
if [ ! -f "$PROMPT_FILE" ]; then
    echo "ERROR: $PROMPT_FILE not found!"
    echo ""
    echo "Create your prompt file at $PROMPT_FILE"
    echo ""
    echo "Quick setup:"
    echo "  mkdir -p .claude"
    echo "  cat > .claude/RALPH_PROMPT.md << 'EOF'"
    echo "  # Your Task Title"
    echo "  "
    echo "  Description of what to build..."
    echo "  "
    echo "  ## Completion Criteria"
    echo "  When done, output: <promise>COMPLETE</promise>"
    echo "  EOF"
    exit 1
fi

# Check if opencode is available
if ! command -v opencode &> /dev/null; then
    echo "ERROR: 'opencode' command not found!"
    echo ""
    echo "Install OpenCode: https://opencode.ai"
    echo "Or check your PATH: echo \$PATH"
    exit 1
fi

# Build the full prompt (context + RALPH_PROMPT.md)
build_prompt() {
    local full_prompt=""

    # Include OpenCode instructions if exists
    if [ -f "$OPENCODE_MD" ]; then
        full_prompt+="## Project Instructions

$(cat $OPENCODE_MD)

---

"
    fi

    # Include CLAUDE.md if it exists
    if [ -f "$CLAUDE_MD" ]; then
        full_prompt+="## Project Context

$(cat $CLAUDE_MD)

---

"
    fi

    # Add the main prompt
    full_prompt+="$(cat $PROMPT_FILE)"

    # Add iteration context
    full_prompt+="

---

## Ralph Loop Context

This is iteration $ITERATION of $MAX_ITERATIONS in an autonomous development loop.

IMPORTANT:
- Check the current state of the project before making changes
- Build on previous work (files may exist from prior iterations)
- Run tests after implementing changes
- Document progress in PROGRESS.md
- When ALL completion criteria are met, output exactly: <promise>COMPLETE</promise>
- If stuck after multiple attempts, output: <promise>NEEDS_HELP</promise>
"

    echo "$full_prompt"
}

# Main loop
while [ $ITERATION -lt $MAX_ITERATIONS ]; do
    ITERATION=$((ITERATION + 1))
    ITER_START=$(date +%s)

    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  ITERATION $ITERATION / $MAX_ITERATIONS  •  $(date '+%H:%M:%S')"
    echo "───────────────────────────────────────────────────────────"
    show_stats
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    # Build the combined prompt
    FULL_PROMPT=$(build_prompt)

    # Run OpenCode with the prompt using 'opencode run'
    # Run from the project directory
    OUTPUT=$(cd "$PROJECT_DIR" && opencode run "$FULL_PROMPT" 2>&1)
    echo "$OUTPUT"

    # Calculate iteration time
    ITER_END=$(date +%s)
    ITER_DURATION=$((ITER_END - ITER_START))
    echo ""
    echo "───────────────────────────────────────────────────────────"
    echo "  Iteration $ITERATION completed in $(format_time $ITER_DURATION)"
    echo "───────────────────────────────────────────────────────────"

    # Check for completion promise
    if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
        TOTAL_TIME=$(($(date +%s) - START_TIME))
        echo ""
        echo "╔═══════════════════════════════════════════════════════════╗"
        echo "║  ✓ TASK COMPLETE                                          ║"
        echo "╠═══════════════════════════════════════════════════════════╣"
        echo "  Iterations: $ITERATION"
        echo "  Total time: $(format_time $TOTAL_TIME)"
        echo "╚═══════════════════════════════════════════════════════════╝"
        exit 0
    fi

    # Check for NEEDS_HELP
    if echo "$OUTPUT" | grep -q "<promise>NEEDS_HELP</promise>"; then
        TOTAL_TIME=$(($(date +%s) - START_TIME))
        echo ""
        echo "╔═══════════════════════════════════════════════════════════╗"
        echo "║  ⚠ HELP REQUESTED - Agent is stuck                        ║"
        echo "╠═══════════════════════════════════════════════════════════╣"
        echo "  Iterations: $ITERATION"
        echo "  Total time: $(format_time $TOTAL_TIME)"
        echo "  Check PROGRESS.md for details on the blocker"
        echo "╚═══════════════════════════════════════════════════════════╝"
        exit 2
    fi

    # Safety check - prompt file deleted (manual stop)
    if [ ! -f "$PROMPT_FILE" ]; then
        echo ""
        echo "╔═══════════════════════════════════════════════════════════╗"
        echo "║  ⚠ STOPPED - Prompt file was deleted                      ║"
        echo "╚═══════════════════════════════════════════════════════════╝"
        exit 1
    fi

    # Brief pause between iterations to avoid rate limiting
    sleep 3
done

TOTAL_TIME=$(($(date +%s) - START_TIME))
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  Max iterations ($MAX_ITERATIONS) reached                           ║"
echo "╠═══════════════════════════════════════════════════════════╣"
echo "  Total time: $(format_time $TOTAL_TIME)"
echo "  Avg per iteration: $(format_time $((TOTAL_TIME / MAX_ITERATIONS)))"
echo "  Check PROGRESS.md for current state"
echo "╚═══════════════════════════════════════════════════════════╝"
exit 1
