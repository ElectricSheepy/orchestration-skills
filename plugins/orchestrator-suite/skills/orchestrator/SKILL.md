---
name: orchestrator
description: Multi-agent orchestrator that coordinates projects and spawns worker instances. Use when managing multiple parallel features, monitoring project progress, or coordinating distributed development work.
model: claude-sonnet-4-20250514
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task
---

# Orchestrator

> You coordinate multiple projects and sub-agents with YAML-based state management.

## Prime Directives

1. **NEVER read Task() output** - Infer state from YAML files only
2. **ALL status files use YAML format** - See [schemas.md](schemas.md) for details
3. **RUN CONTINUOUSLY** with 15-minute monitoring cycles
4. **MONITOR USAGE** - Warn at 70%, pause at 85%
5. **BROADCAST state changes** to `orchestrator/events.jsonl`
6. **CHECK dashboard commands** via `orchestrator/orchestrator-command.yaml`

## Quick Start

```bash
# Start the orchestrator monitoring loop
/orchestrator
```

The orchestrator will:
1. **Auto-initialize** workspace if not set up
2. Scan for active projects in `projects/`
3. Check for pending work in each project's `plan.yaml`
4. Spawn worker instances for available tasks
5. Monitor instance progress via YAML status files
6. Handle blockers and dashboard commands

## Auto-Initialization

On first run, if the workspace structure doesn't exist, the orchestrator will set it up:

### Step 1: Detect Missing Structure

```bash
# Check if orchestrator workspace exists
if [ ! -d "orchestrator" ] || [ ! -d "projects" ]; then
    echo "Orchestrator workspace not found. Initializing..."
    run_initialization
fi
```

### Step 2: Create Directory Structure

```bash
# Create orchestrator directories
mkdir -p orchestrator/{instances,schemas}
mkdir -p projects
mkdir -p instances

# Initialize orchestrator.yaml
cat > orchestrator/orchestrator.yaml << EOF
status: initialized
started_at: "$(date -Iseconds)"
last_cycle: null
next_cycle: null
cycle_interval_seconds: 900
max_instances: 6
active_instances: 0

usage:
  session_percent: 0
  weekly_percent: 0
  warn_threshold: 70
  pause_threshold: 85
EOF

# Initialize empty events log
touch orchestrator/events.jsonl

# Log initialization event
echo '{"type":"initialized","timestamp":"'$(date -Iseconds)'"}' >> orchestrator/events.jsonl
```

### Step 3: Ask User About Projects

After creating the structure, prompt the user:

```
Orchestrator workspace initialized!

How would you like to add projects?

1. Clone from GitHub URL(s)
   - I'll clone the repo and set up worktree structure

2. Add existing local repository
   - Point me to a local git repo to import

3. I'll add projects myself later
   - Projects go in: ./projects/
   - Use /project-init to set up each project

Which option? (1/2/3)
```

### Option 1: Clone from GitHub

```bash
# User provides GitHub URL(s)
read -p "Enter GitHub URL (or multiple separated by spaces): " urls

for url in $urls; do
    # Extract repo name from URL
    repo_name=$(basename "$url" .git)
    project_name="project-$repo_name"

    echo "Cloning $repo_name..."

    # Clone to temporary location
    git clone "$url" "/tmp/$repo_name"

    # Set up project with worktree structure
    mkdir -p "projects/$project_name"
    cd "projects/$project_name"

    # Initialize as bare repo for worktrees
    git clone --bare "$url" .git
    git config core.bare false

    # Create worktrees
    git worktree add docs docs 2>/dev/null || git worktree add docs -b docs
    git worktree add code main 2>/dev/null || git worktree add code -b main

    # Initialize orchestration files
    mkdir -p docs/.project docs/features
    # ... create status.yaml, plan.yaml, blockers.yaml

    echo "Project $project_name set up!"
done
```

### Option 2: Add Local Repository

```bash
# User provides local path
read -p "Enter path to local git repository: " repo_path

if [ ! -d "$repo_path/.git" ]; then
    echo "ERROR: Not a git repository"
    exit 1
fi

repo_name=$(basename "$repo_path")
project_name="project-$repo_name"

echo "Importing $repo_name..."

# Set up project directory
mkdir -p "projects/$project_name"

# Clone locally
git clone "$repo_path" "projects/$project_name/.repo"

# Set up worktree structure
cd "projects/$project_name"
# ... similar to GitHub clone
```

### Option 3: Manual Setup Later

```bash
echo ""
echo "No problem! Here's how to add projects later:"
echo ""
echo "  Option A: Use the project-init skill"
echo "    /project-init my-project"
echo ""
echo "  Option B: Clone and setup manually"
echo "    cd projects/"
echo "    git clone <repo-url> project-myproject"
echo "    cd project-myproject"
echo "    # Set up docs/ and code/ worktrees"
echo ""
echo "Projects directory: $(pwd)/projects/"
echo ""
```

### Step 4: Continue to Monitoring

After initialization (with or without projects), proceed to the monitoring loop:

```bash
echo ""
echo "Workspace ready! Starting orchestrator monitoring..."
echo ""
echo "Dashboard: Run /orchestrator-dashboard in another terminal"
echo ""

# Begin monitoring cycle
run_monitoring_loop
```

## File Structure

Projects use **git worktrees** to separate orchestration files from source code:

```
{workspace}/
├── orchestrator/                    # Orchestrator runtime files
│   ├── orchestrator.yaml            # Orchestrator state
│   ├── orchestrator-command.yaml    # Commands from dashboard
│   ├── events.jsonl                 # Event log (append-only)
│   ├── instances/                   # Agent instance status files
│   │   └── {id}.yaml
│   └── schemas/
│       └── file-schemas.yaml
├── projects/                        # Project directories
│   └── {project}/
│       ├── docs/                    # Git worktree → "docs" branch
│       │   ├── .project/
│       │   │   ├── status.yaml
│       │   │   ├── plan.yaml
│       │   │   └── blockers.yaml
│       │   └── features/{name}/
│       │       └── status.yaml
│       └── code/                    # Git worktree → "main" branch
└── instances/                       # Agent isolated clones
    └── {instance-id}/
        ├── docs/                    # Git worktree → "docs" branch
        └── code/                    # Git worktree → "feature/{name}" branch
```

**Why worktrees?**
- Orchestration files (status, blockers) stay on `docs` branch
- Source code stays on `main` or feature branches
- Workers can commit status updates without affecting code branches
- Clean separation of concerns

## Monitoring Cycle

Run every 15 minutes:

```bash
while true; do
  echo "=== CYCLE $(date) ==="

  # 1. Check for dashboard commands
  if [ -f orchestrator/orchestrator-command.yaml ]; then
    # Read and execute command, then delete file
  fi

  # 2. Check usage thresholds
  # If >85%: pause spawns, update orchestrator.yaml status=paused

  # 3. For each active project:
  for project in projects/project-*; do
    # Check if active (status.yaml active: true)
    # Check blockers.yaml for new active blockers
    # Check instance status files for progress
    # Update project health based on blockers
  done

  # 4. Spawn new work if capacity available
  # Read plan.yaml, find enabled tasks with status=pending
  # Check dependencies, spawn with correct model

  # 5. Update orchestrator/orchestrator.yaml with last_cycle timestamp

  # 6. Log cycle event to events.jsonl

  sleep 900  # 15 minutes
done
```

## Spawning Workers

When spawning a worker for a feature:

```bash
# 1. Get model preference from feature status
model=$(yq '.model // "sonnet"' "projects/$project/docs/features/$feature/status.yaml")

# 2. Create isolated instance clone
./orchestrator/scripts/spawn-instance.sh \
    "instance-$project-$feature-001" \
    "$project" \
    "$feature" \
    "$model"

# 3. Spawn worker agent using Task()
Task("
  cd instances/instance-$project-$feature-001
  Run /worker for feature: $feature

  Context:
  - docs/ = Orchestration files (docs branch)
  - code/ = Source code (feature/$feature branch)
  - Update docs/features/$feature/status.yaml as you progress
")

# 4. Log spawn event
echo '{"type":"spawn","project":"$project","feature":"$feature",...}' >> orchestrator/events.jsonl
```

## Dashboard Commands

Check `orchestrator/orchestrator-command.yaml` each cycle:

| Command | Action |
|---------|--------|
| `command: stop` | Stop orchestrator gracefully |
| `command: pause` | Pause all spawning, keep monitoring |
| `command: retrospective` | Run program-wide retrospective |

Per-instance commands in `orchestrator/instances/{id}-command.yaml`:

| Command | Action |
|---------|--------|
| `command: pause` | Pause this instance |
| `command: resume` | Resume this instance |
| `command: finish_early` | Complete current work and stop |

## Event Broadcasting

Log all state changes to `orchestrator/events.jsonl`:

```bash
# Progress update
echo '{"type":"progress","project":"alpha","feature":"auth","progress":80,"timestamp":"..."}' >> orchestrator/events.jsonl

# Spawn event
echo '{"type":"spawn","project":"alpha","feature":"auth","instance_id":"...","timestamp":"..."}' >> orchestrator/events.jsonl

# Blocker detected
echo '{"type":"blocked","project":"alpha","feature":"auth","data":{...},"timestamp":"..."}' >> orchestrator/events.jsonl
```

Event types: `progress`, `complete`, `blocked`, `question`, `answer`, `spawn`, `stop`, `error`, `message`, `cycle`

## Usage Thresholds

Monitor API usage in `orchestrator/orchestrator.yaml`:

```yaml
usage:
  session_percent: 73
  weekly_percent: 21
  warn_threshold: 70
  pause_threshold: 85
```

Actions:
- **< 70%**: Normal operation
- **70-85%**: Warn human, limit new spawns
- **> 85%**: Pause all spawns, urgent notification

## Notifications (Windows)

```bash
# Info beep
powershell.exe -Command "[console]::beep(600,200)"

# Question pending (double beep)
powershell.exe -Command "[console]::beep(800,300); sleep -m 200; [console]::beep(800,300)"

# Urgent/Blocked (rapid 5x)
powershell.exe -Command "1..5 | % { [console]::beep(1000,200); sleep -m 100 }"
```

## Additional Resources

- [schemas.md](schemas.md) - Complete YAML schema definitions
- [monitoring.md](monitoring.md) - Detailed monitoring cycle documentation
