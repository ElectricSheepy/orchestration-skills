---
name: status
description: Quick status overview of all projects and instances. Shows health, progress, blockers, and active work across the orchestration system.
allowed-tools: Read, Glob, Grep, Bash
---

# Status

> Get a quick overview of all projects, instances, and blockers.

## Usage

```bash
/status [project-name] [--verbose]
```

## What This Skill Does

1. Scans all projects in `projects/`
2. Reads status.yaml files for health and progress
3. Checks for active blockers
4. Shows running instance status
5. Summarizes overall system health

## Output Format

### Summary View (default)

```
=== ORCHESTRATOR STATUS ===
Status: running | Instances: 3/6 | Usage: 45%

PROJECTS:
┌─────────────────┬────────┬──────────┬──────────┐
│ Project         │ Health │ Progress │ Blockers │
├─────────────────┼────────┼──────────┼──────────┤
│ project-alpha   │ good   │ 67%      │ 0        │
│ project-beta    │ warning│ 23%      │ 2        │
│ project-gamma   │ paused │ 100%     │ 0        │
└─────────────────┴────────┴──────────┴──────────┘

ACTIVE INSTANCES:
┌─────────────────────────────┬─────────┬──────────┬─────────────────────┐
│ Instance                    │ Status  │ Progress │ Current Task        │
├─────────────────────────────┼─────────┼──────────┼─────────────────────┤
│ instance-alpha-auth-001     │ running │ 75%      │ JWT validation      │
│ instance-alpha-api-001      │ running │ 45%      │ Endpoint tests      │
│ instance-beta-ui-001        │ blocked │ 30%      │ Waiting for design  │
└─────────────────────────────┴─────────┴──────────┴─────────────────────┘

BLOCKERS (2 active):
• [beta/ui] Decision: Color scheme selection (priority: blocking)
• [beta/api] Question: Rate limiting strategy? (priority: soon)
```

### Project Detail View

```bash
/status project-alpha --verbose
```

```
=== PROJECT: project-alpha ===
Health: good | Phase: 2 (Core Features) | Progress: 67%

FEATURES:
┌──────────┬──────────┬──────────┬─────────────────────────────┐
│ Feature  │ Status   │ Progress │ Instance                    │
├──────────┼──────────┼──────────┼─────────────────────────────┤
│ auth     │ active   │ 75%      │ instance-alpha-auth-001     │
│ api      │ active   │ 45%      │ instance-alpha-api-001      │
│ database │ complete │ 100%     │ -                           │
│ frontend │ pending  │ 0%       │ -                           │
└──────────┴──────────┴──────────┴─────────────────────────────┘

RECENT ACTIVITY:
• 10m ago: auth progress 70% → 75%
• 25m ago: api started JWT endpoint implementation
• 1h ago: database marked complete

TODOS (auth):
☑ Set up auth middleware
☐ Implement JWT validation (in progress)
☐ Add refresh token support
☐ Write integration tests
```

## Data Sources

The status skill reads from:

| File | Information |
|------|-------------|
| `orchestrator/orchestrator.yaml` | System status, usage |
| `projects/*/docs/.project/status.yaml` | Project health, progress |
| `projects/*/docs/.project/blockers.yaml` | Active blockers |
| `projects/*/docs/features/*/status.yaml` | Feature status |
| `orchestrator/instances/*.yaml` | Instance status |
| `orchestrator/events.jsonl` | Recent activity |

## Workflow

### 1. Read Orchestrator Status

```bash
cat orchestrator/orchestrator.yaml
```

### 2. Scan Projects

```bash
for project in projects/*/; do
    status_file="$project/docs/.project/status.yaml"
    if [ -f "$status_file" ]; then
        yq '.id, .health, .progress' "$status_file"
    fi
done
```

### 3. Check Blockers

```bash
for project in projects/*/; do
    blockers_file="$project/docs/.project/blockers.yaml"
    if [ -f "$blockers_file" ]; then
        yq '.active[] | .feature + ": " + .title' "$blockers_file"
    fi
done
```

### 4. Read Instance Status

```bash
for instance in orchestrator/instances/*.yaml; do
    yq '.id, .status, .progress, .current_task' "$instance"
done
```

## Options

| Option | Description |
|--------|-------------|
| `--verbose` | Show detailed information |
| `--json` | Output as JSON |
| `--blockers` | Only show blockers |
| `--instances` | Only show instances |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All systems healthy |
| 1 | Warnings present (blockers or warnings) |
| 2 | Critical issues (blocked projects, errors) |
