---
name: orchestration-tester
description: End-to-end testing framework for the orchestrator system. Creates dummy projects, runs the orchestrator, simulates human interactions, and produces reflection reports with improvement suggestions.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task
---

# Orchestration Tester

> Test the orchestrator system end-to-end with simulated projects and human interactions.

## Usage

```bash
/orchestration-tester [options]
```

Options:
- `--projects <n>` - Number of dummy projects to create (default: 2)
- `--features <n>` - Features per project (default: 3)
- `--complexity <level>` - simple | medium | complex (default: simple)
- `--duration <minutes>` - How long to run the test (default: 30)
- `--goal <description>` - What aspect to test (e.g., "blocker handling", "parallel spawning")

## What This Skill Does

1. **Creates test environment** with isolated dummy projects
2. **Generates simplistic features** that workers can actually implement
3. **Starts the orchestrator** in test mode
4. **Simulates human interactions** (answering questions, resolving blockers)
5. **Monitors the system** for issues, timing, and behavior
6. **Produces reflection report** with insights and improvement suggestions

## Test Environment Structure

```
test-environment-{timestamp}/
├── orchestrator/                    # Test orchestrator runtime
│   ├── orchestrator.yaml
│   ├── events.jsonl
│   └── instances/
├── projects/                        # Dummy projects
│   ├── test-project-001/
│   │   ├── docs/
│   │   │   ├── .project/
│   │   │   │   ├── status.yaml
│   │   │   │   ├── plan.yaml
│   │   │   │   └── blockers.yaml
│   │   │   └── features/
│   │   │       ├── feature-a/
│   │   │       ├── feature-b/
│   │   │       └── feature-c/
│   │   └── code/
│   └── test-project-002/
├── instances/                       # Worker instances
├── test-config.yaml                 # Test configuration
├── human-simulation.yaml            # Rules for simulating human
└── test-report.md                   # Final reflection report
```

## Test Configuration

```yaml
# test-config.yaml
test_id: "test-{timestamp}"
goal: "Test blocker handling and resolution flow"
created_at: "{timestamp}"

environment:
  projects: 2
  features_per_project: 3
  complexity: simple
  duration_minutes: 30

human_simulation:
  response_delay_seconds: 5          # Simulate human response time
  auto_answer_questions: true        # Automatically answer blockers
  inject_blockers: true              # Randomly inject blockers
  approval_rate: 0.9                 # 90% of assumptions approved

monitoring:
  check_interval_seconds: 30
  capture_logs: true
  track_metrics: true

success_criteria:
  - "All features reach 100% progress"
  - "No unresolved blockers at end"
  - "Orchestrator completes without errors"
```

## Dummy Project Templates

### Simple Complexity

Features that can be completed with minimal code:
- **hello-world**: Create a hello world function
- **add-numbers**: Create a function that adds two numbers
- **string-reverse**: Create a function that reverses a string
- **config-file**: Create a configuration file with key-value pairs
- **readme-update**: Update the README with project info

### Medium Complexity

Features requiring more structure:
- **user-model**: Create a user data model with validation
- **api-endpoint**: Create a REST endpoint with basic CRUD
- **file-parser**: Parse a specific file format (JSON, CSV)
- **logger-setup**: Set up a logging system
- **test-suite**: Create unit tests for existing code

### Complex Complexity

Features with dependencies and decisions:
- **auth-system**: Authentication with multiple decision points
- **database-layer**: Database abstraction with schema design
- **api-client**: External API integration with error handling
- **cache-layer**: Caching system with invalidation strategy
- **event-system**: Event bus with pub/sub pattern

## Human Simulation

The tester simulates human interactions to keep the system running:

### Question Handling

```yaml
# human-simulation.yaml
question_responses:
  # Pattern matching for automatic responses
  - pattern: ".*token.*expir.*"
    response: "24 hours"
    delay: 5

  - pattern: ".*password.*hash.*"
    response: "Use argon2id"
    delay: 3

  - pattern: ".*database.*"
    response: "Use SQLite for simplicity"
    delay: 10

  # Default response for unmatched questions
  default:
    action: "choose_default"      # Use the default option
    delay: 15

assumption_handling:
  approval_rate: 0.9              # Approve 90% of assumptions
  rejection_reasons:
    - "Use a different approach"
    - "Check the requirements again"
```

### Blocker Injection

To test blocker handling, the tester can inject artificial blockers:

```yaml
blocker_injection:
  enabled: true
  frequency: "1 per 10 minutes"
  types:
    - type: question
      title: "Injected: Design decision needed"
      description: "Should we use approach A or B?"
      options: ["Approach A", "Approach B"]

    - type: technical
      title: "Injected: Simulated build failure"
      description: "Build failed due to missing dependency"
```

## Monitoring & Metrics

During the test, the tester monitors:

### System Health
- Orchestrator status (running/paused/error)
- Instance count and states
- Blocker queue length
- Event log activity

### Performance Metrics
- Time to spawn instances
- Blocker resolution time
- Feature completion rate
- Error frequency

### Behavior Patterns
- Worker progress curves
- Communication patterns
- Resource utilization

## Workflow

### Step 1: Setup Test Environment

```bash
# Create isolated test directory
test_dir="test-environment-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$test_dir"/{orchestrator,projects,instances}

# Initialize test configuration
cat > "$test_dir/test-config.yaml" << EOF
test_id: "test-$(date +%s)"
goal: "$goal"
...
EOF
```

### Step 2: Generate Dummy Projects

```bash
# For each project
for i in $(seq 1 $num_projects); do
  project_dir="$test_dir/projects/test-project-$(printf '%03d' $i)"

  # Run project-init
  /project-init "test-project-$(printf '%03d' $i)" --template simple

  # Generate features based on complexity
  for feature in $(select_features $complexity $num_features); do
    create_feature "$project_dir" "$feature"
  done
done
```

### Step 3: Start Orchestrator

```bash
# Start orchestrator in test mode
cd "$test_dir"
Task("
  Run /orchestrator

  Context:
  - This is a TEST environment
  - Projects in projects/ are dummy test projects
  - Monitor for $duration_minutes minutes
  - Log everything to orchestrator/events.jsonl
")
```

### Step 4: Run Human Simulation Loop

```bash
while [ $elapsed -lt $duration_minutes ]; do
  # Check for pending questions
  for blocker_file in projects/*/docs/.project/blockers.yaml; do
    pending=$(yq '.active[] | select(.type == "question")' "$blocker_file")
    if [ -n "$pending" ]; then
      simulate_human_response "$blocker_file" "$pending"
    fi
  done

  # Check for pending assumptions
  for status_file in projects/*/docs/features/*/status.yaml; do
    assumptions=$(yq '.assumptions[] | select(.status == "assumed")' "$status_file")
    if [ -n "$assumptions" ]; then
      simulate_assumption_review "$status_file" "$assumptions"
    fi
  done

  # Optionally inject blockers
  if should_inject_blocker; then
    inject_random_blocker
  fi

  # Collect metrics
  collect_metrics >> "$test_dir/metrics.jsonl"

  sleep $check_interval
done
```

### Step 5: Generate Reflection Report

After the test completes, analyze results and generate report:

```bash
# Analyze all data sources
analyze_events "$test_dir/orchestrator/events.jsonl"
analyze_instance_logs "$test_dir/orchestrator/instances/"
analyze_project_status "$test_dir/projects/"
analyze_metrics "$test_dir/metrics.jsonl"

# Generate comprehensive report
generate_reflection_report > "$test_dir/test-report.md"
```

## Reflection Report Template

```markdown
# Orchestration Test Report

**Test ID:** {test_id}
**Goal:** {goal}
**Duration:** {duration}
**Date:** {date}

## Executive Summary

{brief_summary_of_test_results}

## Test Configuration

- Projects: {num_projects}
- Features per project: {features_per_project}
- Complexity: {complexity}
- Human simulation: {enabled/disabled}

## Results

### Success Criteria

| Criteria | Result | Notes |
|----------|--------|-------|
| All features complete | {pass/fail} | {details} |
| No unresolved blockers | {pass/fail} | {details} |
| No orchestrator errors | {pass/fail} | {details} |

### Metrics Summary

| Metric | Value | Benchmark |
|--------|-------|-----------|
| Total features | {n} | - |
| Completed features | {n} | - |
| Average completion time | {minutes} | - |
| Blockers encountered | {n} | - |
| Blocker resolution time (avg) | {minutes} | - |
| Worker spawns | {n} | - |
| Errors encountered | {n} | - |

## What Went Well

- {positive_1}
- {positive_2}
- {positive_3}

## Issues Discovered

### Issue 1: {title}

**Severity:** {low/medium/high}
**Description:** {description}
**Evidence:** {log entries, metrics}
**Suggested Fix:** {recommendation}

## Skill Improvement Suggestions

### Orchestrator Skill

1. **{suggestion_1}**
   - Current behavior: {what_happens_now}
   - Suggested change: {what_should_happen}
   - Rationale: {why}

### Worker Skill

1. **{suggestion_1}**
   - Current behavior: {what_happens_now}
   - Suggested change: {what_should_happen}
   - Rationale: {why}

## Test Coverage Analysis

### What Was Tested

- [x] Project initialization
- [x] Worker spawning
- [x] Progress tracking
- [x] Blocker creation
- [x] Question handling
- [ ] Error recovery (not triggered)
- [ ] Usage threshold handling (not triggered)

### Recommended Additional Tests

1. **{test_scenario_1}**: {why_important}
2. **{test_scenario_2}**: {why_important}

## Logs & Artifacts

- Events log: `orchestrator/events.jsonl`
- Instance logs: `orchestrator/instances/*.yaml`
- Metrics: `metrics.jsonl`
- Full test config: `test-config.yaml`

## Conclusion

{overall_assessment_and_next_steps}
```

## Example Usage

### Basic Test

```bash
# Run a simple test with defaults
/orchestration-tester
```

### Targeted Test

```bash
# Test blocker handling specifically
/orchestration-tester --projects 1 --features 5 --goal "blocker handling"
```

### Stress Test

```bash
# Test with more projects and complexity
/orchestration-tester --projects 5 --features 4 --complexity medium --duration 60
```

### Parallel Spawning Test

```bash
# Test parallel worker spawning
/orchestration-tester --projects 3 --features 6 --goal "parallel spawning limits"
```

## Best Practices

1. **Start simple** - Begin with 1-2 projects, simple complexity
2. **Define clear goals** - Know what you're testing before starting
3. **Review logs** - The real insights are in the detailed logs
4. **Iterate** - Use findings to improve skills, then retest
5. **Compare runs** - Keep test reports to track improvements over time

## See Also

- [orchestrator](../orchestrator/SKILL.md) - The orchestrator being tested
- [worker](../worker/SKILL.md) - Worker agents being spawned
- [retrospective](../retrospective/SKILL.md) - For analyzing completed work
- [validate-setup](../../scripts/validate-setup.sh) - Validates test environment
