# Orchestration Skills

A Claude Code skills marketplace for multi-agent orchestration and parallel feature development.

## Installation

Add this marketplace to Claude Code:

```bash
/plugin marketplace add jasperdj/orchestration-skills
```

Then install the orchestrator suite:

```bash
/plugin install orchestrator-suite@orchestration-skills
```

## Available Skills

### `/orchestrator`

The main orchestrator that coordinates multiple projects and spawns worker instances.

**Features:**
- Monitor multiple projects simultaneously
- Spawn worker agents for parallel feature development
- Track progress via YAML status files
- Handle blockers and questions
- Dashboard integration via events.jsonl

**Usage:**
```bash
/orchestrator
```

### `/worker`

Feature worker agent that implements a single feature in an isolated worktree.

**Features:**
- Work in isolated `docs/` and `code/` worktrees
- Update progress and status via YAML files
- Report blockers when stuck
- Track assumptions and todos

**Usage:**
```bash
# Usually spawned by the orchestrator, but can be run manually:
/worker
```

## Architecture

```
orchestrator/
├── spawns workers via Task()
├── monitors YAML status files
└── broadcasts events to dashboard

    ↓ spawns

worker/
├── works in isolated worktree
├── updates docs/features/{name}/status.yaml
├── reports blockers to docs/.project/blockers.yaml
└── commits code to code/, status to docs/
```

## File Structure

Projects using these skills should have:

```
project/
├── orchestrator/
│   ├── orchestrator.yaml
│   ├── events.jsonl
│   └── instances/
├── projects/
│   └── {project}/
│       ├── docs/              # Orchestration (docs branch)
│       │   ├── .project/
│       │   │   ├── status.yaml
│       │   │   ├── plan.yaml
│       │   │   └── blockers.yaml
│       │   └── features/
│       └── code/              # Source (main branch)
└── instances/                 # Worker clones
```

## License

MIT
