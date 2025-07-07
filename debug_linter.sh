#!/bin/bash
# Flutter Linter Debug Script for Linux/macOS
# This script helps debug and fix linter errors in Flutter applications.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Default values
PROJECT_PATH="."
SPECIFIC_FILE=""
VERBOSE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--path)
            PROJECT_PATH="$2"
            shift 2
            ;;
        -f|--file)
            SPECIFIC_FILE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -p, --path PATH     Project path (default: current directory)"
            echo "  -f, --file FILE     Specific file to analyze"
            echo "  -v, --verbose       Verbose output"
            echo "  -h, --help          Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Helper functions
print_header() {
    echo -e "\n${CYAN}============================================================${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${CYAN}============================================================${NC}"
}

print_success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

print_info() {
    echo -e "${BLUE}INFO: $1${NC}"
}

# Check Flutter installation
check_flutter() {
    print_header "FLUTTER INSTALLATION CHECK"
    
    if command -v flutter &> /dev/null; then
        local version=$(flutter --version | head -n 1)
        print_success "$version"
        return 0
    else
        print_error "Flutter not found. Please install Flutter first."
        return 1
    fi
}

# Check project structure
check_project_structure() {
    print_header "PROJECT STRUCTURE CHECK"
    
    local project_path=$(realpath "$PROJECT_PATH")
    print_info "Project path: $project_path"
    
    # Check pubspec.yaml
    if [[ -f "$project_path/pubspec.yaml" ]]; then
        print_success "pubspec.yaml found"
    else
        print_error "pubspec.yaml not found"
    fi
    
    # Check lib directory
    if [[ -d "$project_path/lib" ]]; then
        local dart_files=$(find "$project_path/lib" -name "*.dart" | wc -l)
        print_success "Found $dart_files Dart files in lib/"
    else
        print_error "lib/ directory not found"
    fi
    
    # Check analysis_options.yaml
    if [[ -f "$project_path/analysis_options.yaml" ]]; then
        print_success "analysis_options.yaml found"
    else
        print_warning "analysis_options.yaml not found"
    fi
}

# Check analysis options
check_analysis_options() {
    print_header "ANALYSIS OPTIONS CHECK"
    
    local analysis_file="$PROJECT_PATH/analysis_options.yaml"
    if [[ -f "$analysis_file" ]]; then
        local issues=()
        
        if ! grep -q "include: package:flutter_lints/flutter.yaml" "$analysis_file"; then
            issues+=("Missing Flutter lints include")
        fi
        
        if ! grep -q "analyzer:" "$analysis_file"; then
            issues+=("Missing analyzer configuration")
        fi
        
        if [[ ${#issues[@]} -eq 0 ]]; then
            print_success "analysis_options.yaml looks good"
        else
            print_warning "Potential issues in analysis_options.yaml:"
            for issue in "${issues[@]}"; do
                echo -e "   - ${YELLOW}$issue${NC}"
            done
        fi
    else
        print_warning "analysis_options.yaml not found"
    fi
}

# Run flutter analyze
run_flutter_analyze() {
    print_header "RUNNING FLUTTER ANALYZE"
    
    print_info "Running flutter analyze..."
    
    cd "$PROJECT_PATH"
    
    if flutter analyze > /tmp/flutter_analyze_output.txt 2>&1; then
        print_success "No linter errors found!"
        return 0
    else
        return 1
    fi
}

# Parse analysis output
parse_analysis_output() {
    local output_file="/tmp/flutter_analyze_output.txt"
    
    if [[ ! -f "$output_file" ]]; then
        return 1
    fi
    
    # Initialize counters
    local errors=0
    local warnings=0
    local hints=0
    local info=0
    
    # Parse each line
    while IFS= read -r line; do
        if [[ $line =~ ^([^:]+):([0-9]+):([0-9]+):[[:space:]]*([^:]+):[[:space:]]*(.+)$ ]]; then
            local file="${BASH_REMATCH[1]}"
            local line_num="${BASH_REMATCH[2]}"
            local column="${BASH_REMATCH[3]}"
            local severity="${BASH_REMATCH[4]}"
            local message="${BASH_REMATCH[5]}"
            
            case $severity in
                error) ((errors++)) ;;
                warning) ((warnings++)) ;;
                hint) ((hints++)) ;;
                info) ((info++)) ;;
            esac
            
            # Store issue for detailed output
            echo "$file:$line_num:$column:$severity:$message" >> /tmp/parsed_issues.txt
        fi
    done < "$output_file"
    
    # Store counts
    echo "errors:$errors" > /tmp/issue_counts.txt
    echo "warnings:$warnings" >> /tmp/issue_counts.txt
    echo "hints:$hints" >> /tmp/issue_counts.txt
    echo "info:$info" >> /tmp/issue_counts.txt
}

# Show issue summary
show_issue_summary() {
    print_header "LINTER ERROR SUMMARY"
    
    if [[ ! -f "/tmp/issue_counts.txt" ]]; then
        print_warning "No issues found or could not parse output"
        return
    fi
    
    local total=0
    while IFS=: read -r severity count; do
        case $severity in
            errors)
                echo -e "  ${RED}ERRORS: $count${NC}"
                total=$((total + count))
                ;;
            warnings)
                echo -e "  ${YELLOW}WARNINGS: $count${NC}"
                total=$((total + count))
                ;;
            hints)
                echo -e "  ${BLUE}HINTS: $count${NC}"
                total=$((total + count))
                ;;
            info)
                echo -e "  ${CYAN}INFO: $count${NC}"
                total=$((total + count))
                ;;
        esac
    done < /tmp/issue_counts.txt
    
    echo -e "Total Issues: $total"
}

# Show file issues
show_file_issues() {
    print_header "FILE-SPECIFIC ISSUES"
    
    if [[ ! -f "/tmp/parsed_issues.txt" ]]; then
        return
    fi
    
    local current_file=""
    while IFS=: read -r file line_num column severity message; do
        if [[ "$file" != "$current_file" ]]; then
            current_file="$file"
            local file_issues=$(grep -c "^$file:" /tmp/parsed_issues.txt || echo "0")
            echo -e "\n${WHITE}FILE: $file ($file_issues issues)${NC}"
        fi
        
        local severity_icon=""
        case $severity in
            error) severity_icon="[ERROR]" ;;
            warning) severity_icon="[WARN]" ;;
            hint) severity_icon="[HINT]" ;;
            info) severity_icon="[INFO]" ;;
            *) severity_icon="[UNKNOWN]" ;;
        esac
        
        echo -e "  ${GRAY}$severity_icon Line $line_num:$column - $message${NC}"
    done < /tmp/parsed_issues.txt
}

# Show suggested fixes
show_suggested_fixes() {
    print_header "SUGGESTED FIXES"
    
    echo -e "${YELLOW}Common fixes for Flutter linter issues:${NC}"
    echo -e "\n${YELLOW}avoid_print:${NC}"
    echo -e "   Description: Replace print() with proper logging"
    echo -e "   Fix: Use debugPrint() or a logging framework like logger package"
    echo -e "   Example: debugPrint(\"Debug message\");"
    
    echo -e "\n${YELLOW}unused_import:${NC}"
    echo -e "   Description: Remove unused imports"
    echo -e "   Fix: Delete the unused import statement"
    echo -e "   Example: // Remove: import \"package:unused/package.dart\";"
    
    echo -e "\n${YELLOW}prefer_const_constructors:${NC}"
    echo -e "   Description: Use const constructors when possible"
    echo -e "   Fix: Add const keyword before constructor calls"
    echo -e "   Example: const Text(\"Hello\") instead of Text(\"Hello\")"
    
    echo -e "\n${YELLOW}use_build_context_synchronously:${NC}"
    echo -e "   Description: Avoid using BuildContext after async operations"
    echo -e "   Fix: Check if mounted before using context"
    echo -e "   Example: if (mounted) { Navigator.pop(context); }"
}

# Show quick fix commands
show_quick_fix_commands() {
    print_header "QUICK FIX COMMANDS"
    
    echo -e "${WHITE}Run automatic fixes:${NC}"
    echo -e "   ${GRAY}dart fix --apply${NC}"
    echo -e "   ${GRAY}flutter fix --apply${NC}"
    
    echo -e "\n${WHITE}Format code:${NC}"
    echo -e "   ${GRAY}dart format .${NC}"
    echo -e "   ${GRAY}flutter format .${NC}"
    
    echo -e "\n${WHITE}Re-analyze with specific options:${NC}"
    echo -e "   ${GRAY}flutter analyze --no-fatal-infos${NC}"
    echo -e "   ${GRAY}flutter analyze --no-fatal-warnings${NC}"
    
    echo -e "\n${WHITE}Clean and rebuild:${NC}"
    echo -e "   ${GRAY}flutter clean${NC}"
    echo -e "   ${GRAY}flutter pub get${NC}"
    echo -e "   ${GRAY}flutter analyze${NC}"
}

# Cleanup temporary files
cleanup() {
    rm -f /tmp/flutter_analyze_output.txt
    rm -f /tmp/parsed_issues.txt
    rm -f /tmp/issue_counts.txt
}

# Main execution
echo -e "${GREEN}Starting Flutter Linter Debug...${NC}"
echo -e "${CYAN}Project path: $PROJECT_PATH${NC}"

# Set up cleanup on exit
trap cleanup EXIT

# Check Flutter installation
if ! check_flutter; then
    exit 1
fi

# Check project structure
check_project_structure

# Check analysis options
check_analysis_options

# Run flutter analyze
if run_flutter_analyze; then
    echo -e "\n${GREEN}No linter errors found! Your code looks good.${NC}"
else
    # Parse and display results
    parse_analysis_output
    show_issue_summary
    show_file_issues
    show_suggested_fixes
    show_quick_fix_commands
fi

print_header "DEBUG COMPLETE"
echo -e "${GREEN}Debug complete! Use the suggested commands above to fix issues.${NC}" 