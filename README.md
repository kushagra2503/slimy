# Slimy

macOS notch status viewer for delegated tasks. Lives in the MacBook notch, expands on hover to show time/weather/date and real-time subagent task progress.

## Requirements

- macOS 14+ (with notch for best experience, floating mode on other Macs)
- Swift 6+ (Command Line Tools or Xcode)
- Node.js 18+ (for test script only)

## Quick Start

```bash
cd slimy

# Build and run
swift run Slimy
```

The app hides in the notch with compact info (time + task count). Hover over the notch area to expand it.

## Build Release

```bash
./build.sh
```

Creates a release binary and `Slimy.app` bundle. Run with:

```bash
open Slimy.app
# or
.build/release/Slimy
```

## Test with Mock Events

The app launches with 3 hardcoded sample tasks for immediate UI testing. To simulate live events from the backend:

```bash
# In a second terminal
cd slimy
npm install ws
node test.js
```

This sends a sequence of 3 parallel tasks (Gmail search, Notion page creation, Linear ticket update) that spawn, progress through tool calls, and complete over ~12 seconds.

## How It Works

### Notch Interaction

- **Compact mode**: Time (left of notch) and task count (right of notch) shown as wings
- **Hover**: Black pill expands down from notch revealing full panel with two columns:
  - Left: current time, date, weather
  - Right: active/completed task counts, "View all" button
- **Click "View all"**: Animated transition to task list with status, tools, duration
- **Click a task**: Detailed view with result/error/streaming text
- **Mouse leaves**: 350ms grace period, then collapses back to compact

### WebSocket Server

Runs on `ws://localhost:7778/ws`. Accepts JSON messages matching the backend's `subagent_event` format:

```json
{
  "type": "subagent_event",
  "session_id": "abc-123",
  "event_type": "status|progress|done",
  "data": { ... }
}
```

| event_type | Purpose | data fields |
|-----------|---------|-------------|
| `status` | Add/update task | `task`, `description`, `status`, `tool_calls_count` |
| `progress` | Tool calls, tokens | `type` (tool_start/tool_result/token/thinking_complete), `tool_name`, `text` |
| `done` | Task finished | `status`, `result`, `error` |

Also supports `task_summary` type for bulk sync.

## Architecture

```
Sources/
├── SlimyApp.swift             # App entry, AppDelegate
├── NotchWindow.swift           # NSPanel window controller, screen extensions
├── NotchViewModel.swift       # State management, event processing, mock data
├── Models.swift               # SubagentTask, TaskStatus, WeatherInfo
├── WebSocketServer.swift      # Swifter WS server on :7778
└── Views/
    ├── NotchShellView.swift   # Root view: notch shape, hover, expand/collapse
    ├── NotchContentView.swift # Content state machine + compact views
    └── AgentChatView.swift    # Agent chat + draft cards
```

## Wiring to Desktop App (future)

Forward subagent events from the Electron app to the notch's WebSocket server. In `useChatServiceHandlers.ts`, when processing `subagent_event` messages, also send them to `ws://localhost:7778/ws`.
