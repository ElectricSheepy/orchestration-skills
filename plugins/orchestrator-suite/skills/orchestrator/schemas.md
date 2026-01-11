# YAML Schemas

All orchestration files follow these YAML schemas.

## Project Status (.project/status.yaml)

```yaml
id: project-alpha
name: Project Alpha
version: "2.0.0"
phase: 2
phase_type: PARALLEL        # SERIAL | PARALLEL
health: good                # good | warning | blocked | paused
active: true                # false = orchestrator ignores this project
progress: 33
updated_at: "2026-01-08T19:00:00Z"
```

## Plan (.project/plan.yaml)

```yaml
phases:
  - number: 1
    name: "Foundation"
    type: SERIAL            # SERIAL | PARALLEL
    status: complete        # pending | active | complete
    tasks:
      - id: task-1
        name: "Setup project structure"
        status: complete    # pending | active | complete | blocked | skipped
        enabled: true
        branch: "feature/setup"
        model: sonnet       # opus | sonnet
        assignee: null      # Instance ID if assigned
        progress: 100
        depends_on: []

  - number: 2
    name: "Core Features"
    type: PARALLEL
    status: active
    tasks:
      - id: auth
        name: "Authentication layer"
        status: active
        enabled: true
        model: opus
        assignee: "instance-alpha-auth-001"
        progress: 45
        depends_on: ["task-1"]
```

## Feature Status (features/{name}/status.yaml)

```yaml
name: auth
status: active              # not_started | active | blocked | complete | paused
enabled: true               # false = skip this feature
model: opus                 # opus | sonnet
model_reason: "Complex security implementation"
progress: 75
branch: "feature/auth"
instance_id: instance-alpha-auth-001
started_at: "2026-01-08T18:00:00Z"
completed_at: null
test_coverage: 0

todos:
  - id: todo-1
    text: "Implement password hashing"
    done: true
    priority: high          # low | medium | high
  - id: todo-2
    text: "Add JWT validation"
    done: false
    priority: high

assumptions:
  - id: assume-1
    text: "Token expiry default is 24 hours"
    status: assumed         # assumed | confirmed | rejected
    response: null
```

## Blockers (.project/blockers.yaml)

```yaml
active:
  # Question-type blocker (needs human answer)
  - id: b-001
    feature: auth
    type: question          # question | technical | decision | clarification
    title: "Token expiry duration?"
    description: "Need to decide on JWT token expiration time"
    options: ["1h", "24h", "7d"]
    default: "24h"
    priority: blocking      # blocking | soon | curious
    since: "2026-01-08T18:30:00Z"
    instance_id: instance-alpha-auth-001

  # Technical blocker (code/environment issue)
  - id: b-002
    feature: auth
    type: technical
    title: "Database schema conflict"
    description: "Migration fails due to constraint conflicts"
    attempted:
      - "Tried migration rollback"
      - "Checked constraint definitions"
    needs: "Decision on schema versioning approach"
    impact: "Cannot deploy authentication changes"
    priority: blocking
    since: "2026-01-08T19:00:00Z"
    instance_id: instance-alpha-auth-001

resolved:
  - id: b-000
    feature: auth
    type: decision
    title: "Password hashing algorithm"
    description: "Which algorithm to use for password hashing?"
    resolution: "Use argon2id with default parameters"
    resolved_at: "2026-01-08T17:00:00Z"
    resolved_by: human
```

### Blocker Types

| Type | Description | Key Fields |
|------|-------------|------------|
| `question` | Need human to answer a question | `options`, `default` |
| `technical` | Code, environment, or tool issue | `attempted`, `needs`, `impact` |
| `decision` | Need human to make a choice | `options`, `default` |
| `clarification` | Need more information | `description` |

## Instance Status (orchestrator/instances/{id}.yaml)

```yaml
id: instance-alpha-auth-001
project: project-alpha
feature: auth
model: opus                 # opus | sonnet
status: running             # starting | running | paused | blocked | completing | complete | error
started_at: "2026-01-08T18:00:00Z"
last_activity: "2026-01-08T19:30:00Z"
progress: 75
current_task: "Implementing JWT validation"

claude_session:
  session_id: "a15b646-demo-session"
  agent_id: "a15b646"
  log_file: "agent-a15b646.jsonl"
  slug: "mellow-dazzling-manatee"

todos:
  - text: "Set up auth middleware"
    done: true
  - text: "Implement JWT validation"
    done: false

messages:
  - from: agent
    text: "Started working on authentication layer"
    timestamp: "2026-01-08T18:05:00Z"
  - from: human
    text: "Use argon2id for password hashing"
    timestamp: "2026-01-08T18:10:00Z"
```

## Orchestrator Status (orchestrator/orchestrator.yaml)

```yaml
status: running             # running | paused | stopped
started_at: "2026-01-08T17:00:00Z"
last_cycle: "2026-01-08T19:45:00Z"
next_cycle: "2026-01-08T20:00:00Z"
cycle_interval_seconds: 900
max_instances: 6
active_instances: 2

usage:
  session_percent: 73
  weekly_percent: 21
  sonnet_percent: 7
  warn_threshold: 70
  pause_threshold: 85
```

## Events (orchestrator/events.jsonl)

Append-only JSONL log:

```json
{"type":"spawn","project":"alpha","feature":"auth","instance_id":"instance-alpha-auth-001","timestamp":"2026-01-08T18:00:00Z"}
{"type":"progress","project":"alpha","feature":"auth","progress":25,"timestamp":"2026-01-08T18:30:00Z"}
{"type":"blocked","project":"alpha","feature":"auth","data":{"id":"b-001","title":"..."},"timestamp":"2026-01-08T19:00:00Z"}
{"type":"complete","instance_id":"instance-alpha-auth-001","timestamp":"2026-01-08T21:00:00Z"}
```

Event types: `progress`, `complete`, `blocked`, `question`, `answer`, `spawn`, `stop`, `error`, `message`, `cycle`, `migration`
