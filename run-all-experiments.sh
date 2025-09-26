#!/usr/bin/env bash
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Array of experiments to run
EXPERIMENTS=(
  "otel-cjs"
  "otel-cjs-kv4_8"
  "otel-esbuild-esm-dynamic"
  "otel-esbuild-esm-dynamic-kv4_8"
  "otel-esbuild-esm-dynamic-loader"
  "otel-esbuild-esm-static-loader-import"
  "otel-esbuild-esm-static-loader-import-azure-external-azure-function"
  "otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm"
  "otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options"
  "otel-esm"
  "otel-esm-kv4_8"
  # "otel-esm-patch"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_section() {
  echo
  echo -e "${BLUE}===========================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}===========================================${NC}"
  echo
}

print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
  echo -e "${RED}✗ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to run a single experiment
run_experiment() {
  local experiment="$1"
  local experiment_dir="$SCRIPT_DIR/functions/$experiment"
  local run_script="$experiment_dir/run.sh"

  print_section "STARTING: $experiment"

  # Check if run.sh exists
  if [[ ! -f "$run_script" ]]; then
    print_error "$experiment: run.sh not found at $run_script"
    return 1
  fi

  # Check if run.sh is executable
  if [[ ! -x "$run_script" ]]; then
    print_warning "$experiment: Making run.sh executable"
    chmod +x "$run_script"
  fi

  # Change to experiment directory and run the script
  echo "Changing to directory: $experiment_dir"
  cd "$experiment_dir"

  echo "Executing: ./run.sh"
  echo "============================================"

  # Run the script with full output visible
  if ./run.sh; then
    print_success "$experiment: Completed successfully"
    return 0
  else
    local exit_code=$?
    print_error "$experiment: Failed with exit code $exit_code"
    return $exit_code
  fi
}

main() {
  local start_time=$(date +%s)
  local failed_experiments=()
  local successful_experiments=()

  print_section "Azure Functions OTEL Experiments Runner"
  echo "Starting execution of ${#EXPERIMENTS[@]} experiments..."
  echo "Timestamp: $(date)"
  echo

  # Run each experiment sequentially
  for experiment in "${EXPERIMENTS[@]}"; do
    echo
    echo "Progress: $((${#successful_experiments[@]} + ${#failed_experiments[@]} + 1))/${#EXPERIMENTS[@]}"

    if run_experiment "$experiment"; then
      successful_experiments+=("$experiment")
    else
      failed_experiments+=("$experiment")
      # Continue with other experiments even if one fails
      print_warning "Continuing with remaining experiments..."
    fi

    # Return to script directory
    cd "$SCRIPT_DIR"

    # Add delay between experiments
    echo "Waiting 5 seconds before next experiment..."
    sleep 5
  done

  # Final summary
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))

  print_section "EXECUTION SUMMARY"
  echo "Total time: ${duration}s ($(date -u -d @${duration} +%H:%M:%S 2>/dev/null || date -r ${duration} +%H:%M:%S))"
  echo "Completed: $(date)"
  echo

  if [[ ${#successful_experiments[@]} -gt 0 ]]; then
    print_success "Successful experiments (${#successful_experiments[@]}):"
    for exp in "${successful_experiments[@]}"; do
      echo "  ✓ $exp"
    done
    echo
  fi

  if [[ ${#failed_experiments[@]} -gt 0 ]]; then
    print_error "Failed experiments (${#failed_experiments[@]}):"
    for exp in "${failed_experiments[@]}"; do
      echo "  ✗ $exp"
    done
    echo
    exit 1
  else
    print_success "All experiments completed successfully!"
    exit 0
  fi
}

# Trap to ensure we return to original directory on exit
trap 'cd "$SCRIPT_DIR"' EXIT

# Run main function
main "$@"
