---
name: orchestrator-dashboard
description: Setup and start the orchestrator dashboard. Handles npm install, checks port availability, and launches the real-time monitoring web UI.
allowed-tools: Read, Bash, Glob
---

# Orchestrator Dashboard

> Setup and launch the real-time orchestrator dashboard.

## Usage

```bash
/orchestrator-dashboard [command]
```

Commands:
- `start` (default) - Setup if needed and start the dashboard
- `stop` - Stop the running dashboard
- `status` - Check if dashboard is running
- `open` - Open dashboard in browser

## What This Skill Does

1. **Checks prerequisites** - Node.js installed, dashboard directory exists
2. **Installs dependencies** - Runs `npm install` if `node_modules` missing
3. **Checks port availability** - Ensures port 3001 is free
4. **Starts dashboard server** - Launches in background
5. **Provides URL** - Shows dashboard URL for browser access

## Dashboard Features

The dashboard provides real-time monitoring of:
- **Project status** - Health, progress, phases
- **Active instances** - Running workers and their progress
- **Blockers** - Questions awaiting answers, technical issues
- **Events** - Live feed from `events.jsonl`
- **Commands** - Send commands to orchestrator/instances

## Workflow

### Start Command (default)

```bash
/orchestrator-dashboard
# or
/orchestrator-dashboard start
```

**Step 1: Check prerequisites**
```bash
# Verify Node.js is installed
if ! command -v node &> /dev/null; then
    echo "ERROR: Node.js is required but not installed"
    echo "Install from: https://nodejs.org/"
    exit 1
fi

# Verify dashboard directory exists
if [ ! -d "dashboard" ]; then
    echo "ERROR: dashboard/ directory not found"
    echo "Make sure you're in the orchestrator workspace root"
    exit 1
fi
```

**Step 2: Install dependencies**
```bash
cd dashboard

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "Installing dashboard dependencies..."
    npm install
    if [ $? -ne 0 ]; then
        echo "ERROR: npm install failed"
        exit 1
    fi
    echo "Dependencies installed successfully"
else
    echo "Dependencies already installed"
fi
```

**Step 3: Check port availability**
```bash
# Check if port 3001 is already in use
if lsof -i :3001 &> /dev/null || netstat -an | grep -q ":3001.*LISTEN"; then
    echo "Dashboard already running on port 3001"
    echo "URL: http://localhost:3001"
    exit 0
fi
```

**Step 4: Start dashboard**
```bash
# Start in background
echo "Starting dashboard server..."
nohup npm start > dashboard.log 2>&1 &
DASHBOARD_PID=$!

# Wait a moment for server to start
sleep 2

# Verify it started
if curl -s http://localhost:3001 > /dev/null; then
    echo "Dashboard started successfully!"
    echo ""
    echo "  URL: http://localhost:3001"
    echo "  PID: $DASHBOARD_PID"
    echo "  Log: dashboard/dashboard.log"
    echo ""
    echo "Stop with: /orchestrator-dashboard stop"
else
    echo "ERROR: Dashboard failed to start"
    echo "Check dashboard/dashboard.log for errors"
    exit 1
fi
```

### Stop Command

```bash
/orchestrator-dashboard stop
```

```bash
# Find and kill dashboard process
# Look for node process running server.js
PIDS=$(pgrep -f "node.*server.js" || true)

if [ -z "$PIDS" ]; then
    echo "Dashboard is not running"
else
    echo "Stopping dashboard (PID: $PIDS)..."
    kill $PIDS
    sleep 1
    echo "Dashboard stopped"
fi
```

### Status Command

```bash
/orchestrator-dashboard status
```

```bash
# Check if dashboard is running
if curl -s http://localhost:3001 > /dev/null 2>&1; then
    echo "Dashboard is RUNNING"
    echo "  URL: http://localhost:3001"

    # Get PID if possible
    PID=$(pgrep -f "node.*server.js" || echo "unknown")
    echo "  PID: $PID"
else
    echo "Dashboard is NOT RUNNING"
    echo ""
    echo "Start with: /orchestrator-dashboard start"
fi
```

### Open Command

```bash
/orchestrator-dashboard open
```

Opens the dashboard in the default browser:

```bash
# Check if running first
if ! curl -s http://localhost:3001 > /dev/null 2>&1; then
    echo "Dashboard is not running. Starting it first..."
    # Start dashboard (same as start command)
fi

# Open in browser based on OS
URL="http://localhost:3001"

case "$(uname -s)" in
    Linux*)   xdg-open "$URL" ;;
    Darwin*)  open "$URL" ;;
    MINGW*|CYGWIN*|MSYS*)  start "$URL" ;;
    *)        echo "Open $URL in your browser" ;;
esac
```

## Configuration

The dashboard reads from the orchestrator workspace:

| Path | Purpose |
|------|---------|
| `orchestrator/orchestrator.yaml` | Orchestrator status |
| `orchestrator/events.jsonl` | Event stream (watched live) |
| `orchestrator/instances/*.yaml` | Instance status files |
| `projects/*/docs/.project/status.yaml` | Project status |
| `projects/*/docs/.project/blockers.yaml` | Blockers |
| `projects/*/docs/features/*/status.yaml` | Feature status |

## Port Configuration

Default port is **3001**. To use a different port:

```bash
# Set PORT environment variable
PORT=3002 npm start

# Or in dashboard/server.js, modify:
const PORT = process.env.PORT || 3001;
```

## Troubleshooting

### Port already in use

```bash
# Find what's using port 3001
lsof -i :3001
# or on Windows
netstat -ano | findstr :3001

# Kill the process if needed
kill <PID>
```

### Dashboard won't start

```bash
# Check the log
cat dashboard/dashboard.log

# Common issues:
# - Missing node_modules: run npm install
# - Port conflict: change port or stop other process
# - Missing workspace files: ensure orchestrator/ and projects/ exist
```

### WebSocket connection failed

The dashboard uses WebSocket for real-time updates. If events aren't updating:

1. Check browser console for errors
2. Ensure `orchestrator/events.jsonl` exists
3. Try refreshing the browser

## Integration with Orchestrator

For best experience, start the dashboard before the orchestrator:

```bash
# Terminal 1: Start dashboard
/orchestrator-dashboard

# Terminal 2: Start orchestrator
/orchestrator
```

Or run both in sequence:
```bash
/orchestrator-dashboard start && /orchestrator
```

## Platform Notes

### Windows (Git Bash / MINGW)

```bash
# Check port (Windows)
netstat -ano | findstr :3001

# Kill process (Windows)
taskkill /PID <pid> /F

# Open browser (Windows)
start http://localhost:3001
```

### macOS

```bash
# Check port
lsof -i :3001

# Open browser
open http://localhost:3001
```

### Linux

```bash
# Check port
ss -tlnp | grep 3001

# Open browser
xdg-open http://localhost:3001
```
