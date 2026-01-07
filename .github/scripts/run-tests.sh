#!/bin/bash
set -e  # Exit on error

# Script to run all test configurations
# Usage: ./run-tests.sh <config_file>

CONFIG_FILE="${1:-.github/workflows/test-matrix.json}"

# Initialize counters and tracking
total=0
passed=0
failed=0
declare -a failed_configs
declare -a failed_log_dirs

# Initialize GitHub Summary if running in GitHub Actions
if [ -n "$GITHUB_STEP_SUMMARY" ]; then
    echo "# Build and Execution Test Results" >> "$GITHUB_STEP_SUMMARY"
    echo "" >> "$GITHUB_STEP_SUMMARY"
    echo "| # | Configuration | Status | Details |" >> "$GITHUB_STEP_SUMMARY"
    echo "|---|---------------|--------|---------|" >> "$GITHUB_STEP_SUMMARY"
fi

# Function to add result to summary
add_to_summary() {
    local num=$1
    local config=$2
    local status=$3
    local details=$4

    if [ -n "$GITHUB_STEP_SUMMARY" ]; then
        echo "| $num | $config | $status | $details |" >> "$GITHUB_STEP_SUMMARY"
    fi
}

# Function to build, execute and verify a configuration
test_configuration() {
    local compiler=$1
    local ext=$2
    local target=$3
    local model=$4
    local uart=$5
    local build=$6

    local config_name="$build+$target with $compiler"
    local failure_reason=""
    local log_file="./logs/${target}_${compiler}_${build}.log"

    # Create logs directory
    mkdir -p "./logs"

    # Initialize log file with header
    echo "=========================================" > "$log_file"
    echo "Configuration: $config_name" >> "$log_file"
    echo "Date: $(date)" >> "$log_file"
    echo "=========================================" >> "$log_file"
    echo "" >> "$log_file"

    echo ""
    echo "=========================================="
    echo "[$total/60] Testing: $config_name"
    echo "=========================================="

    # Build
    echo "▶ Building..."
    echo "=========================================" >> "$log_file"
    echo "BUILD OUTPUT" >> "$log_file"
    echo "=========================================" >> "$log_file"
    if ! cbuild Hello.csolution.yml --packs \
        --context "Hello.$build+$target" \
        --toolchain "$compiler" --rebuild 2>&1 | tee -a "$log_file"; then
        failure_reason="Build failed"
        echo "✗ $failure_reason"
        echo "" >> "$log_file"
        echo "Result: FAILED - $failure_reason" >> "$log_file"
        failed=$((failed + 1))
        failed_configs+=("[$total] $config_name - $failure_reason")
        failed_log_dirs+=("$log_file")
        add_to_summary "$total" "$config_name" "❌ Failed" "$failure_reason"
        return 1
    fi
    echo "✅ Build successful"

    # Execute
    echo "▶ Executing on $model..."
    echo "" >> "$log_file"
    echo "=========================================" >> "$log_file"
    echo "EXECUTION OUTPUT" >> "$log_file"
    echo "=========================================" >> "$log_file"
    if ! "$model" \
       -a "./out/Hello/$target/$build/$compiler/Hello.$ext" \
       -f "./FVP/$model/fvp_config.txt" \
       -C "$uart.out_file=./out/Hello/$target/$build/$compiler/fvp_stdout.log" \
       --simlimit 60 --stat 2>&1 | tee -a "$log_file"; then
        failure_reason="Execution failed"
        echo "❌ $failure_reason"
        echo "" >> "$log_file"
        echo "Result: FAILED - $failure_reason" >> "$log_file"
        failed=$((failed + 1))
        failed_configs+=("[$total] $config_name - $failure_reason")
        failed_log_dirs+=("$log_file")
        add_to_summary "$total" "$config_name" "❌ Failed" "$failure_reason"
        return 1
    fi
    echo "✅ Execution successful"

    echo "Actual UART output:"
    cat "./out/Hello/$target/$build/$compiler/fvp_stdout.log" || echo "Could not read log file"

    if grep -q "Hello World 100" "./out/Hello/$target/$build/$compiler/fvp_stdout.log"; then
        echo "✅ Test PASSED"
        passed=$((passed + 1))
        add_to_summary "$total" "$config_name" "✅ Passed" ""
        # Clean up log for passed test
        rm -f "$log_file"
        return 0
    else
        failure_reason="Verification failed - 'Hello World 100' not found"
        echo "❌ $failure_reason"

        # Add UART output to log file
        echo "" >> "$log_file"
        echo "=========================================" >> "$log_file"
        echo "UART OUTPUT" >> "$log_file"
        echo "=========================================" >> "$log_file"
        cat "./out/Hello/$target/$build/$compiler/fvp_stdout.log" >> "$log_file" 2>/dev/null || echo "Could not read UART log" >> "$log_file"
        echo "" >> "$log_file"
        echo "Result: FAILED - $failure_reason" >> "$log_file"

        failed=$((failed + 1))
        failed_configs+=("[$total] $config_name - $failure_reason")
        failed_log_dirs+=("$log_file")
        add_to_summary "$total" "$config_name" "❌ Failed" "$failure_reason"
        return 1
    fi
}

# Main execution loop
echo "Reading configurations from: $CONFIG_FILE"

# Generate all combinations from compilers × targets × builds
while IFS= read -r compiler_data; do
    compiler=$(echo "$compiler_data" | jq -r '.name')
    ext=$(echo "$compiler_data" | jq -r '.ext')

    while IFS= read -r target_data; do
        target=$(echo "$target_data" | jq -r '.type')
        model=$(echo "$target_data" | jq -r '.model')
        uart=$(echo "$target_data" | jq -r '.uart')

        while IFS= read -r build; do
            total=$((total + 1))
            test_configuration "$compiler" "$ext" "$target" "$model" "$uart" "$build" || true
        done < <(jq -r '.builds[]' "$CONFIG_FILE")

    done < <(jq -c '.targets[]' "$CONFIG_FILE")

done < <(jq -c '.compilers[]' "$CONFIG_FILE")

# Add summary statistics to GitHub Summary
if [ -n "$GITHUB_STEP_SUMMARY" ]; then
    echo "" >> "$GITHUB_STEP_SUMMARY"
    echo "## Summary" >> "$GITHUB_STEP_SUMMARY"
    echo "" >> "$GITHUB_STEP_SUMMARY"
    echo "- **Total Configurations:** $total" >> "$GITHUB_STEP_SUMMARY"
    echo "- **✅ Passed:** $passed" >> "$GITHUB_STEP_SUMMARY"
    echo "- **❌ Failed:** $failed" >> "$GITHUB_STEP_SUMMARY"
fi

# Print comprehensive summary
echo ""
echo "=========================================="
echo "           FINAL SUMMARY"
echo "=========================================="
echo "Total configurations: $total"
echo "Passed: $passed"
echo "Failed: $failed"
echo ""

if [ $failed -gt 0 ]; then
    echo "❌ FAILED CONFIGURATIONS:"
    echo "=========================================="
    for fail_info in "${failed_configs[@]}"; do
        echo "$fail_info"
    done
    echo "=========================================="
    echo ""
    echo "Logs for failed configurations saved in: ./logs/"
    echo "Total failed log files: ${#failed_log_dirs[@]}"
    exit 1
else
    echo "✅ All tests passed!"
    # Clean up logs directory if all tests passed
    rm -rf ./logs
fi
