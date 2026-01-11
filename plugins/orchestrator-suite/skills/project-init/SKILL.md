---
name: project-init
description: Initialize a new project with the orchestrator worktree structure. Creates docs/ and code/ worktrees, status files, and required directories.
allowed-tools: Read, Write, Edit, Bash, Glob
---

# Project Init

> Initialize a new project with the orchestrator's git worktree structure.

## Usage

```bash
/project-init <project-name> [--repo <git-url>]
```

## What This Skill Does

1. Creates the project directory structure
2. Initializes git repository (or clones existing)
3. Sets up `docs` and `main` branches
4. Creates git worktrees for `docs/` and `code/`
5. Generates initial YAML status files
6. Validates the setup

## Directory Structure Created

```
projects/{project-name}/
├── .worktree-migrated          # Migration marker
├── docs/                       # Git worktree → "docs" branch
│   ├── .project/
│   │   ├── status.yaml         # Project status
│   │   ├── plan.yaml           # Task planning
│   │   ├── blockers.yaml       # Blockers tracking
│   │   └── architecture.md     # System documentation
│   └── features/               # Feature directories
└── code/                       # Git worktree → "main" branch
    ├── CLAUDE.md               # Worker instructions
    ├── src/
    └── package.json
```

## Workflow

### Step 1: Create Project Directory

```bash
project_name="$1"
project_path="projects/$project_name"

mkdir -p "$project_path"
cd "$project_path"
```

### Step 2: Initialize Git Repository

For a new project:
```bash
git init
git checkout -b main
echo "# $project_name" > README.md
git add README.md
git commit -m "Initial commit"
```

For an existing repo:
```bash
git clone "$repo_url" .
```

### Step 3: Create Branches

```bash
# Create docs branch from main
git checkout -b docs
git checkout main
```

### Step 4: Set Up Worktrees

```bash
# Create worktrees
git worktree add docs docs
git worktree add code main
```

### Step 5: Create Status Files

Create `docs/.project/status.yaml`:
```yaml
id: {project-name}
name: "{Project Name}"
version: "1.0.0"
phase: 1
phase_type: SERIAL
health: good
active: true
progress: 0
updated_at: "{timestamp}"
```

Create `docs/.project/plan.yaml`:
```yaml
phases:
  - number: 1
    name: "Setup"
    type: SERIAL
    status: pending
    tasks: []
```

Create `docs/.project/blockers.yaml`:
```yaml
active: []
resolved: []
```

### Step 6: Create Worker Template

Create `code/CLAUDE.md` with worker instructions pointing to the docs/ worktree.

### Step 7: Validate Setup

```bash
./scripts/validate-setup.sh project "$project_path"
```

## Options

| Option | Description |
|--------|-------------|
| `--repo <url>` | Clone from existing repository |
| `--template <name>` | Use a project template |
| `--no-validate` | Skip validation after setup |

## Example

```bash
# Initialize new project
/project-init my-api

# Initialize from existing repo
/project-init my-api --repo https://github.com/user/my-api.git
```

## Post-Init Steps

After initialization:
1. Edit `docs/.project/plan.yaml` to add phases and tasks
2. Create feature directories in `docs/features/`
3. Update `docs/.project/status.yaml` as needed
4. Start the orchestrator to begin work
