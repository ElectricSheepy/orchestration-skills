# Orchestrator Suite

Multi-agent orchestration skills for Claude Code.

## Skills Included

### `/orchestrator`
Coordinates multiple projects and spawns worker instances for parallel development.

### `/worker`
Feature worker that implements a single feature in an isolated worktree environment.

## Usage

The orchestrator spawns workers using `Task()`:

```javascript
Task("
  cd instances/instance-project-feature-001
  Run /worker for feature: auth
")
```

Workers update their progress via YAML files which the orchestrator monitors.
