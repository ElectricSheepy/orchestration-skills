# Orchestrator Suite

Multi-agent orchestration skills for Claude Code.

## Skills Included

### `/orchestrator`
Coordinates multiple projects and spawns worker instances for parallel development. Runs continuous monitoring cycles, tracks progress via YAML status files, and handles blockers.

### `/worker`
Feature worker agent that implements a single feature in an isolated worktree environment. Works with `docs/` and `code/` git worktrees for clean separation of orchestration and source code.

### `/project-init`
Initialize a new project with the orchestrator's git worktree structure. Creates `docs/` and `code/` worktrees, status files, and required directories.

### `/status`
Quick status overview of all projects and instances. Shows health, progress, blockers, and active work across the orchestration system.

### `/retrospective`
Run a retrospective on completed features or projects. Analyzes blockers, timing, and patterns to generate actionable insights. Includes instance log analysis for agent behavior insights.

### `/orchestration-tester`
End-to-end testing framework for the orchestrator system. Creates dummy projects, runs the orchestrator, simulates human interactions (answering questions, resolving blockers), and produces reflection reports with improvement suggestions.

```bash
# Basic test with defaults
/orchestration-tester

# Targeted test for blocker handling
/orchestration-tester --projects 1 --features 5 --goal "blocker handling"
```

### `/orchestrator-dashboard`
Setup and launch the real-time orchestrator dashboard. Handles npm install, checks port availability, and starts the monitoring web UI.

```bash
# Start dashboard (installs deps if needed)
/orchestrator-dashboard

# Other commands
/orchestrator-dashboard stop      # Stop the dashboard
/orchestrator-dashboard status    # Check if running
/orchestrator-dashboard open      # Open in browser
```

**Recommended workflow:**
```bash
# Terminal 1: Start dashboard first
/orchestrator-dashboard

# Terminal 2: Start orchestrator
/orchestrator
```

## Scripts

### `validate-setup.sh`
Validates project or instance setup to ensure git worktrees and required files are properly configured.

```bash
# Validate a project
./scripts/validate-setup.sh project projects/project-alpha

# Validate an instance
./scripts/validate-setup.sh instance instances/instance-alpha-auth-001
```

## Git Worktree Structure

Projects and instances use git worktrees to separate orchestration files from source code:

```
projects/{project}/
├── docs/                    # Git worktree → "docs" branch
│   ├── .project/
│   │   ├── status.yaml
│   │   ├── plan.yaml
│   │   └── blockers.yaml
│   └── features/{name}/
│       └── status.yaml
└── code/                    # Git worktree → "main" branch
    └── src/
```

## Usage

The orchestrator spawns workers using `Task()`:

```javascript
Task("
  cd instances/instance-project-feature-001
  Run /worker for feature: auth
")
```

Workers update their progress via YAML files which the orchestrator monitors.

## Installation

```bash
# Clone the marketplace
git clone https://github.com/ElectricSheepy/orchestration-skills.git

# Install in Claude Code (from the skills directory)
/install ./orchestration-skills
```

## Updating

```bash
cd orchestration-skills
git pull
```

Changes take effect in your next Claude Code session.
