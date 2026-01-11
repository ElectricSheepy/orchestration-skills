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
Run a retrospective on completed features or projects. Analyzes blockers, timing, and patterns to generate actionable insights.

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
git clone https://github.com/jasperdj/orchestration-skills.git

# Install in Claude Code (from the skills directory)
/install ./orchestration-skills
```
