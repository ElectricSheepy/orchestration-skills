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
| `instances/*.yaml` | Messages, todos, assumptions, session info |
| **Instance logs** | Tool calls, errors, reasoning, actual work done |
| Git history | Commit patterns, code changes |

### Instance Log Analysis

The instance YAML files contain a `claude_session` field pointing to the actual agent logs:

```yaml
# orchestrator/instances/{id}.yaml
claude_session:
  session_id: "a15b646-demo-session"
  agent_id: "a15b646"
  log_file: "agent-a15b646.jsonl"    # <-- The actual logs
  slug: "mellow-dazzling-manatee"
```

These JSONL log files contain the complete conversation history:
- **Tool calls**: What tools were used and how often
- **Errors**: Failed operations, retries, error messages
- **Reasoning**: Agent's thought process and decisions
- **Time spent**: Duration between messages/actions
- **Files touched**: Which files were read/edited

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

### Code Metrics
- **Commits:** {commit_count}
- **Files changed:** {files_changed}
- **Lines added/removed:** +{added}/-{removed}
- **Test coverage:** {coverage}%
- **Blockers encountered:** {blocker_count}
- **Blocker resolution rate:** {resolution_rate}%

### Agent Behavior (from logs)
- **Total tool calls:** {tool_call_count}
- **Tool breakdown:** Read: {read_count}, Edit: {edit_count}, Bash: {bash_count}
- **Errors encountered:** {error_count}
- **Files touched:** {files_touched}
- **Read/Write ratio:** {read_write_ratio}
- **Repeated operations:** {repeated_ops} (potential inefficiency)
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

### Agent Behavior (from instance logs)

- **Tool usage patterns**: Which tools were used most? Any unusual patterns?
- **Error frequency**: How many tool calls failed? What types of errors?
- **Retries and recovery**: Did the agent recover gracefully from errors?
- **Exploration vs execution**: How much time spent reading vs writing?
- **Context efficiency**: Did the agent re-read files unnecessarily?
- **Decision quality**: Were tool choices appropriate for the task?

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

### Step 2: Analyze Instance Logs

```bash
# Get the log file path from instance YAML
instance_id="instance-$project-$feature-001"
log_file=$(yq '.claude_session.log_file' "orchestrator/instances/$instance_id.yaml")

# Count tool usage by type
grep '"tool_use"' "$log_file" | jq -r '.name' | sort | uniq -c | sort -rn

# Find errors and failures
grep -E '"error"|"failed"|"Error"' "$log_file"

# Extract files that were read/edited
grep '"tool_use"' "$log_file" | grep -E '"Read"|"Edit"|"Write"' | \
  jq -r '.input.file_path' | sort | uniq -c

# Identify repeated operations (potential inefficiency)
grep '"tool_use"' "$log_file" | \
  jq -r '[.name, .input.file_path // .input.command // ""] | join(":")' | \
  sort | uniq -c | sort -rn | head -20

# Calculate exploration vs execution ratio
reads=$(grep -c '"Read"' "$log_file" || echo 0)
writes=$(grep -c '"Write"\|"Edit"' "$log_file" || echo 0)
echo "Read/Write ratio: $reads:$writes"
```

### Step 3: Analyze Patterns

```bash
# Calculate blocker duration
# For each resolved blocker, compute: resolved_at - since

# Analyze commit patterns
cd "projects/$project/code"
git log --oneline --since="$start_date" --until="$end_date"
```

### Step 4: Generate Report

Write retrospective to:
- `projects/$project/docs/features/$feature/retrospective.md` (feature)
- `projects/$project/docs/.project/retrospective.md` (project)
- `orchestrator/retrospectives/{date}-program.md` (program)

### Step 5: Log Event

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

## Agent Behavior Analysis

**Log file:** agent-a15b646.jsonl

| Metric | Value |
|--------|-------|
| Total tool calls | 147 |
| Read operations | 52 |
| Edit operations | 31 |
| Bash commands | 64 |
| Errors encountered | 3 |
| Read/Write ratio | 1.7:1 |

**Notable patterns:**
- Re-read `auth.ts` 4 times (could benefit from better context retention)
- 2 failed test runs before success (normal iteration)
- Efficient use of Grep for code search

## Recommendations

1. **Requirements:** Add OAuth checklist to feature templates
2. **Defaults:** Document standard defaults for common decisions
3. **Communication:** Earlier escalation of blocking questions
4. **Agent efficiency:** Consider providing more upfront context to reduce re-reads
```

## Triggering Retrospectives

Retrospectives can be triggered:

1. **Automatically** - When a feature is marked complete
2. **Via dashboard** - Using the retrospective command
3. **Via skill** - Running `/retrospective` directly
4. **Scheduled** - At phase or project completion
