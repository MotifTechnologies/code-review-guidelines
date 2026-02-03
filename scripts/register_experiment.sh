#!/usr/bin/env bash
#
# Experiment Registration Script
#
# Interactive script to register a new ML experiment.
# Creates a YAML file from the template with user-provided details.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REGISTRY_DIR="$PROJECT_ROOT/experiments/registry"
TEMPLATE_FILE="$REGISTRY_DIR/TEMPLATE.yaml"

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to prompt for input with default
prompt() {
    local var_name=$1
    local prompt_text=$2
    local default_value=$3

    if [ -n "$default_value" ]; then
        read -p "$(echo -e "${BLUE}?${NC} $prompt_text [$default_value]: ")" value
        value=${value:-$default_value}
    else
        read -p "$(echo -e "${BLUE}?${NC} $prompt_text: ")" value
    fi

    eval "$var_name='$value'"
}

# Function to generate experiment ID
generate_exp_id() {
    local date=$(date +%Y-%m-%d)
    local counter=1
    local exp_id

    # Find next available counter for today
    while true; do
        exp_id=$(printf "exp-%s-%03d" "$date" "$counter")
        if [ ! -f "$REGISTRY_DIR/$date-*.yaml" ] || ! grep -q "id: \"$exp_id\"" "$REGISTRY_DIR/$date-"*.yaml 2>/dev/null; then
            break
        fi
        counter=$((counter + 1))
    done

    echo "$exp_id"
}

# Main script
main() {
    echo ""
    echo "=========================================="
    echo "  Experiment Registration"
    echo "=========================================="
    echo ""

    # Check if template exists
    if [ ! -f "$TEMPLATE_FILE" ]; then
        print_error "Template file not found: $TEMPLATE_FILE"
        exit 1
    fi

    # Create registry directory if it doesn't exist
    mkdir -p "$REGISTRY_DIR"

    # Generate experiment ID
    EXP_ID=$(generate_exp_id)
    print_info "Generated experiment ID: $EXP_ID"
    echo ""

    # Gather experiment details
    prompt EXP_NAME "Experiment name" ""
    prompt OWNER "Your GitHub username" "$(git config user.name 2>/dev/null || echo '')"
    prompt HYPOTHESIS "Hypothesis (brief)" ""
    prompt DURATION "Expected duration" "2 weeks"
    prompt GPUS "Number of GPUs needed" "0"

    if [ "$GPUS" != "0" ]; then
        prompt GPU_TYPE "GPU type (e.g., V100, A100)" "V100"
    else
        GPU_TYPE="null"
    fi

    prompt CPU_CORES "CPU cores needed" "4"
    prompt MEMORY_GB "Memory (GB)" "16"
    prompt ESTIMATED_COST "Estimated cost" "\$0"

    # Create branch name suggestion
    BRANCH_SUGGESTION="experiment/$(echo "$EXP_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')"
    prompt BRANCH "Git branch name" "$BRANCH_SUGGESTION"

    # Success criteria
    echo ""
    print_info "Enter success criteria (one per line, empty line to finish):"
    CRITERIA=()
    while true; do
        read -p "  - " criterion
        if [ -z "$criterion" ]; then
            break
        fi
        CRITERIA+=("$criterion")
    done

    # Tags
    echo ""
    print_info "Enter tags (comma-separated, e.g., nlp,transformers,optimization):"
    read -p "  " TAGS_INPUT

    # Generate filename
    DATE=$(date +%Y-%m-%d)
    FILENAME="$DATE-$(echo "$EXP_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g').yaml"
    OUTPUT_FILE="$REGISTRY_DIR/$FILENAME"

    # Check if file already exists
    if [ -f "$OUTPUT_FILE" ]; then
        print_warning "File already exists: $OUTPUT_FILE"
        prompt OVERWRITE "Overwrite? (yes/no)" "no"
        if [ "$OVERWRITE" != "yes" ]; then
            print_info "Registration cancelled"
            exit 0
        fi
    fi

    # Generate YAML content
    echo ""
    print_info "Generating experiment registration file..."

    cat > "$OUTPUT_FILE" << EOF
# Experiment Registration
# Auto-generated on $(date +%Y-%m-%d)

experiment:
  id: "$EXP_ID"
  name: "$EXP_NAME"
  owner: "@$OWNER"
  branch: "$BRANCH"
  pr: null

hypothesis: |
  $HYPOTHESIS

timeline:
  start_date: "$(date +%Y-%m-%d)"
  expected_duration: "$DURATION"
  end_date: null

resources:
  gpus: $GPUS
  gpu_type: $GPU_TYPE
  cpu_cores: $CPU_CORES
  memory_gb: $MEMORY_GB
  estimated_cost: "$ESTIMATED_COST"
  actual_cost: null
  special_requirements: []

success_criteria:
EOF

    # Add success criteria
    if [ ${#CRITERIA[@]} -eq 0 ]; then
        echo '  - "Define success criteria"' >> "$OUTPUT_FILE"
    else
        for criterion in "${CRITERIA[@]}"; do
            echo "  - \"$criterion\"" >> "$OUTPUT_FILE"
        done
    fi

    # Add remaining template content
    cat >> "$OUTPUT_FILE" << EOF

status: "planned"

dependencies:
  experiments: []
  data_sources: []
  external_services: []

baseline:
  model: null
  metrics: {}

results:
  outcome: null
  summary: null
  metrics: {}
  artifacts:
    models: []
    datasets: []
    notebooks: []
    reports: []
  lessons_learned: []
  next_steps: []

tags:
EOF

    # Add tags
    if [ -z "$TAGS_INPUT" ]; then
        echo '  []' >> "$OUTPUT_FILE"
    else
        echo "$TAGS_INPUT" | tr ',' '\n' | while read -r tag; do
            tag=$(echo "$tag" | xargs)  # trim whitespace
            if [ -n "$tag" ]; then
                echo "  - \"$tag\"" >> "$OUTPUT_FILE"
            fi
        done
    fi

    # Add notes section
    cat >> "$OUTPUT_FILE" << EOF

notes: |
  Registered on $(date +%Y-%m-%d)
EOF

    print_success "Experiment registered successfully!"
    echo ""
    echo "=========================================="
    echo "  Next Steps"
    echo "=========================================="
    echo ""
    echo "1. Review and edit the experiment file:"
    echo "   $OUTPUT_FILE"
    echo ""
    echo "2. Create the experiment branch:"
    echo "   git checkout -b $BRANCH"
    echo ""
    echo "3. Commit the registration:"
    echo "   git add $OUTPUT_FILE"
    echo "   git commit -m \"Register experiment: $EXP_NAME\""
    echo ""
    echo "4. Start your experiment and update the YAML file with results"
    echo ""
    echo "5. When complete, update the 'results' section and set status to 'completed'"
    echo ""
}

# Run main function
main
