---
name: retrospective
description: Run a retrospective on completed features or projects. Analyzes what went well, what could improve, and generates actionable insights.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Retrospective

> Analyze completed work to generate insights and improvements.

## Usage

```bash
/retrospective [scope] [--output <file>]
```

Scopes:
- `feature <project> <feature>` - Single feature retrospective
- `project <project>` - Full project retrospective
- `program` - Program-wide retrospective (all projects)

## What This Skill Does

1. Collects data from completed work
2. Analyzes blockers, timing, and patterns
3. Identifies what went well
4. Highlights areas for improvement
5. Generates actionable recommendations
6. Outputs a structured retrospective document

## Data Sources

| Source | Information Gathered |
|--------|---------------------|
| `status.yaml` | Timeline, progress patterns |
| `blockers.yaml` | Resolved blockers, resolution time |
| `events.jsonl` | Activity timeline, spawn/complete events |
| `instances/*.yaml` | Messages, todos, assumptions |
| Git history | Commit patterns, code changes |

## Retrospective Template

```markdown
# Retrospective: {scope}

**Date:** {date}
**Duration:** {start} → {end} ({days} days)
**Progress:** {start_progress}% → {end_progress}%

## Summary

{brief_summary}

## What Went Well

- {positive_1}
- {positive_2}
- {positive_3}

## What Could Improve

- {improvement_1}
- {improvement_2}
- {improvement_3}

## Blockers Analysis

| Blocker | Type | Duration | Resolution |
|---------|------|----------|------------|
| {title} | {type} | {hours}h | {resolution} |

**Average blocker resolution time:** {avg_hours}h
**Most common blocker type:** {common_type}

## Assumptions Review

| Assumption | Status | Impact |
|------------|--------|--------|
| {text} | {confirmed/rejected} | {impact} |

## Timeline

{timeline_visualization}

## Recommendations

1. **{category_1}:** {recommendation_1}
2. **{category_2}:** {recommendation_2}
3. **{category_3}:** {recommendation_3}

## Metrics

- **Commits:** {commit_count}
- **Files changed:** {files_changed}
- **Lines added/removed:** +{added}/-{removed}
- **Test coverage:** {coverage}%
- **Blockers encountered:** {blocker_count}
- **Blocker resolution rate:** {resolution_rate}%
```

## Analysis Categories

### Timing Analysis

- How long did each phase take?
- Were there unexpected delays?
- Which tasks took longer than estimated?

### Blocker Patterns

- What types of blockers were most common?
- How long did blockers typically last?
- Could any blockers have been prevented?

### Communication Patterns

- How many questions were asked?
- Were assumptions validated in time?
- Was feedback loop efficient?

### Code Quality

- Commit frequency and size
- Test coverage changes
- Technical debt introduced/resolved

## Workflow

### Step 1: Gather Data

```bash
# Read feature status
cat "projects/$project/docs/features/$feature/status.yaml"

# Read resolved blockers
yq '.resolved[]' "projects/$project/docs/.project/blockers.yaml"

# Get events for this feature
grep "\"feature\":\"$feature\"" orchestrator/events.jsonl
```

### Step 2: Analyze Patterns

```bash
# Calculate blocker duration
# For each resolved blocker, compute: resolved_at - since

# Analyze commit patterns
cd "projects/$project/code"
git log --oneline --since="$start_date" --until="$end_date"
```

### Step 3: Generate Report

Write retrospective to:
- `projects/$project/docs/features/$feature/retrospective.md` (feature)
- `projects/$project/docs/.project/retrospective.md` (project)
- `orchestrator/retrospectives/{date}-program.md` (program)

### Step 4: Log Event

```bash
echo '{"type":"retrospective","scope":"feature","project":"alpha","feature":"auth","timestamp":"..."}' >> orchestrator/events.jsonl
```

## Options

| Option | Description |
|--------|-------------|
| `--output <file>` | Write to specific file |
| `--json` | Output as JSON instead of markdown |
| `--brief` | Short summary only |
| `--recommendations` | Focus on actionable items |

## Example Output

```markdown
# Retrospective: auth (project-alpha)

**Date:** 2026-01-08
**Duration:** 2026-01-06 → 2026-01-08 (2 days)
**Progress:** 0% → 100%

## Summary

Authentication feature completed in 2 days with 3 blockers resolved.
JWT implementation went smoothly; OAuth integration took longer than expected
due to unclear requirements.

## What Went Well

- Clear initial requirements for basic auth
- Fast resolution of password hashing decision (argon2id)
- Good test coverage from the start

## What Could Improve

- OAuth requirements should be clarified upfront
- Token expiry decision delayed by 4 hours
- More context needed for refresh token implementation

## Blockers Analysis

| Blocker | Type | Duration | Resolution |
|---------|------|----------|------------|
| Password hashing algorithm | decision | 2h | argon2id |
| Token expiry duration | question | 4h | 24h default |
| OAuth scope unclear | clarification | 6h | Basic OAuth only |

**Average blocker resolution time:** 4h
**Most common blocker type:** decision

## Recommendations

1. **Requirements:** Add OAuth checklist to feature templates
2. **Defaults:** Document standard defaults for common decisions
3. **Communication:** Earlier escalation of blocking questions
```

## Triggering Retrospectives

Retrospectives can be triggered:

1. **Automatically** - When a feature is marked complete
2. **Via dashboard** - Using the retrospective command
3. **Via skill** - Running `/retrospective` directly
4. **Scheduled** - At phase or project completion
