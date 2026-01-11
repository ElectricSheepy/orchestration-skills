#!/bin/bash
# validate-setup.sh - Validates project/instance setup for orchestrator system
# Usage: ./validate-setup.sh [project|instance] <path>
#
# Examples:
#   ./validate-setup.sh project projects/project-alpha
#   ./validate-setup.sh instance instances/instance-alpha-auth-001

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

error() {
    echo -e "${RED}ERROR:${NC} $1"
    ((ERRORS++))
}

warn() {
    echo -e "${YELLOW}WARN:${NC} $1"
    ((WARNINGS++))
}

ok() {
    echo -e "${GREEN}OK:${NC} $1"
}

check_file() {
    local file="$1"
    local description="$2"
    if [ -f "$file" ]; then
        ok "$description exists"
        return 0
    else
        error "$description missing: $file"
        return 1
    fi
}

check_dir() {
    local dir="$1"
    local description="$2"
    if [ -d "$dir" ]; then
        ok "$description exists"
        return 0
    else
        error "$description missing: $dir"
        return 1
    fi
}

check_worktree() {
    local dir="$1"
    local expected_branch="$2"
    local description="$3"

    if [ ! -d "$dir" ]; then
        error "$description directory missing: $dir"
        return 1
    fi

    if [ ! -d "$dir/.git" ] && [ ! -f "$dir/.git" ]; then
        error "$description is not a git repository/worktree: $dir"
        return 1
    fi

    local current_branch
    current_branch=$(cd "$dir" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

    if [ "$expected_branch" = "*" ]; then
        ok "$description is a git worktree (branch: $current_branch)"
    elif [ "$current_branch" = "$expected_branch" ]; then
        ok "$description on correct branch: $current_branch"
    elif [[ "$current_branch" == $expected_branch* ]]; then
        ok "$description on matching branch: $current_branch (expected pattern: $expected_branch*)"
    else
        error "$description on wrong branch: $current_branch (expected: $expected_branch)"
        return 1
    fi
    return 0
}

check_yaml_field() {
    local file="$1"
    local field="$2"
    local description="$3"

    if [ ! -f "$file" ]; then
        return 1
    fi

    if command -v yq &> /dev/null; then
        local value
        value=$(yq ".$field" "$file" 2>/dev/null || echo "null")
        if [ "$value" != "null" ] && [ -n "$value" ]; then
            ok "$description has $field: $value"
            return 0
        else
            warn "$description missing field: $field"
            return 1
        fi
    else
        # Fallback to grep if yq not available
        if grep -q "^$field:" "$file" 2>/dev/null; then
            ok "$description has $field"
            return 0
        else
            warn "$description missing field: $field (install yq for better validation)"
            return 1
        fi
    fi
}

validate_project() {
    local project_path="$1"
    echo "=== Validating PROJECT: $project_path ==="
    echo ""

    # Check migration marker
    if [ -f "$project_path/.worktree-migrated" ]; then
        ok "Project is migrated to worktree structure"
    else
        warn "Project not migrated (missing .worktree-migrated marker)"
    fi

    # Check docs worktree
    echo ""
    echo "--- Checking docs/ worktree ---"
    check_worktree "$project_path/docs" "docs" "Docs worktree"

    # Check required docs files
    check_dir "$project_path/docs/.project" "Project config directory"
    check_file "$project_path/docs/.project/status.yaml" "Project status"
    check_file "$project_path/docs/.project/plan.yaml" "Project plan"
    check_file "$project_path/docs/.project/blockers.yaml" "Blockers file"

    # Validate status.yaml fields
    if [ -f "$project_path/docs/.project/status.yaml" ]; then
        echo ""
        echo "--- Validating status.yaml ---"
        check_yaml_field "$project_path/docs/.project/status.yaml" "id" "status.yaml"
        check_yaml_field "$project_path/docs/.project/status.yaml" "name" "status.yaml"
        check_yaml_field "$project_path/docs/.project/status.yaml" "active" "status.yaml"
        check_yaml_field "$project_path/docs/.project/status.yaml" "health" "status.yaml"
    fi

    # Check features directory
    check_dir "$project_path/docs/features" "Features directory"

    # Check code worktree
    echo ""
    echo "--- Checking code/ worktree ---"
    check_worktree "$project_path/code" "main" "Code worktree"

    # Check for CLAUDE.md in code
    if [ -f "$project_path/code/CLAUDE.md" ]; then
        ok "Worker instructions (CLAUDE.md) present in code/"
    else
        warn "No CLAUDE.md in code/ - workers may lack context"
    fi
}

validate_instance() {
    local instance_path="$1"
    local instance_name
    instance_name=$(basename "$instance_path")

    echo "=== Validating INSTANCE: $instance_name ==="
    echo ""

    # Extract feature name from instance ID (instance-{project}-{feature}-{num})
    local feature
    feature=$(echo "$instance_name" | sed 's/instance-[^-]*-\(.*\)-[0-9]*/\1/')

    # Check docs worktree
    echo "--- Checking docs/ worktree ---"
    check_worktree "$instance_path/docs" "docs" "Docs worktree"

    # Check required docs structure
    check_dir "$instance_path/docs/.project" "Project config directory"
    check_file "$instance_path/docs/.project/status.yaml" "Project status"
    check_file "$instance_path/docs/.project/blockers.yaml" "Blockers file"

    # Check feature directory
    if [ -n "$feature" ] && [ "$feature" != "$instance_name" ]; then
        echo ""
        echo "--- Checking feature: $feature ---"
        check_dir "$instance_path/docs/features/$feature" "Feature directory"
        check_file "$instance_path/docs/features/$feature/status.yaml" "Feature status"

        if [ -f "$instance_path/docs/features/$feature/status.yaml" ]; then
            check_yaml_field "$instance_path/docs/features/$feature/status.yaml" "name" "feature status"
            check_yaml_field "$instance_path/docs/features/$feature/status.yaml" "status" "feature status"
            check_yaml_field "$instance_path/docs/features/$feature/status.yaml" "progress" "feature status"
        fi
    fi

    # Check code worktree
    echo ""
    echo "--- Checking code/ worktree ---"
    check_worktree "$instance_path/code" "feature/" "Code worktree"

    # Check for CLAUDE.md
    if [ -f "$instance_path/code/CLAUDE.md" ]; then
        ok "Worker instructions (CLAUDE.md) present"
    else
        warn "No CLAUDE.md in code/ - worker may lack context"
    fi
}

# Main
if [ $# -lt 2 ]; then
    echo "Usage: $0 [project|instance] <path>"
    echo ""
    echo "Examples:"
    echo "  $0 project projects/project-alpha"
    echo "  $0 instance instances/instance-alpha-auth-001"
    exit 1
fi

TYPE="$1"
PATH_ARG="$2"

if [ ! -d "$PATH_ARG" ]; then
    echo -e "${RED}Path does not exist:${NC} $PATH_ARG"
    exit 1
fi

case "$TYPE" in
    project)
        validate_project "$PATH_ARG"
        ;;
    instance)
        validate_instance "$PATH_ARG"
        ;;
    *)
        echo -e "${RED}Unknown type:${NC} $TYPE (use 'project' or 'instance')"
        exit 1
        ;;
esac

# Summary
echo ""
echo "=========================================="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}PASSED:${NC} All checks passed!"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}PASSED WITH WARNINGS:${NC} $WARNINGS warning(s)"
    exit 0
else
    echo -e "${RED}FAILED:${NC} $ERRORS error(s), $WARNINGS warning(s)"
    exit 1
fi
