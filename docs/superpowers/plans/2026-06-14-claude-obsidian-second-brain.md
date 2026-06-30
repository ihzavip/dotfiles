# Claude → Obsidian Second Brain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Automatically write a session summary note to `~/Documents/obsidian/Claude/` when a Claude Code session ends, capturing key decisions and changes made.

**Architecture:** A `StopSession` hook in `~/.claude/settings.json` triggers a zsh script that reads the session transcript, calls the Claude API to extract key changes/decisions, and writes a Markdown note to the Obsidian vault.

**Tech Stack:** zsh, Claude API (curl), Claude Code hooks (`StopSession`)

---

### Task 1: Create the Obsidian Claude folder

**Files:**
- Create: `~/Documents/obsidian/Claude/` (directory)

- [ ] **Step 1: Create the folder**

```bash
mkdir -p ~/Documents/obsidian/Claude
```

- [ ] **Step 2: Commit placeholder to dotfiles**

```bash
touch ~/dotfiles/docs/obsidian-claude-folder.md
git -C ~/dotfiles add docs/obsidian-claude-folder.md
git -C ~/dotfiles commit -m "feat: add obsidian claude folder reference"
```

---

### Task 2: Create the `claude-to-obsidian` script

**Files:**
- Create: `~/dotfiles/local/.local/bin/claude-to-obsidian`

- [ ] **Step 1: Write the script**

```bash
cat > ~/dotfiles/local/.local/bin/claude-to-obsidian << 'EOF'
#!/usr/bin/env zsh

VAULT_DIR="$HOME/Documents/obsidian/Claude"
mkdir -p "$VAULT_DIR"

SESSION_NAME="${CLAUDE_SESSION_NAME:-unnamed}"
DATE=$(date +%Y-%m-%d)
OUTFILE="$VAULT_DIR/$DATE-$SESSION_NAME.md"

# Read transcript from env var path
TRANSCRIPT="${CLAUDE_TRANSCRIPT:-}"
if [[ -z "$TRANSCRIPT" || ! -f "$TRANSCRIPT" ]]; then
  echo "# $SESSION_NAME\n\n*No transcript available.*" > "$OUTFILE"
  exit 0
fi

CONTENT=$(cat "$TRANSCRIPT")

# Call Claude API to summarize
API_KEY="${ANTHROPIC_API_KEY:-}"
if [[ -z "$API_KEY" ]]; then
  echo "# $SESSION_NAME\n\n*ANTHROPIC_API_KEY not set.*" > "$OUTFILE"
  exit 0
fi

SUMMARY=$(curl -s https://api.anthropic.com/v1/messages \
  -H "x-api-key: $API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d "{
    \"model\": \"claude-haiku-4-5-20251001\",
    \"max_tokens\": 512,
    \"messages\": [{
      \"role\": \"user\",
      \"content\": \"Extract the key decisions, changes made, and config updates from this Claude Code session transcript. Be concise — bullet points only, no preamble. Transcript:\n\n$CONTENT\"
    }]
  }" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['content'][0]['text'])" 2>/dev/null)

if [[ -z "$SUMMARY" ]]; then
  SUMMARY="*Summary unavailable — API call failed.*"
fi

cat > "$OUTFILE" << MDEOF
# $SESSION_NAME
*$DATE*

$SUMMARY
MDEOF

EOF
chmod +x ~/dotfiles/local/.local/bin/claude-to-obsidian
```

- [ ] **Step 2: Verify the script is executable**

```bash
ls -la ~/dotfiles/local/.local/bin/claude-to-obsidian
```

Expected: `-rwxr-xr-x`

- [ ] **Step 3: Verify stow symlink is active**

```bash
ls -la ~/.local/bin/claude-to-obsidian
```

Expected: symlink pointing to `~/dotfiles/local/.local/bin/claude-to-obsidian`. If not, run:

```bash
cd ~/dotfiles && stow local
```

- [ ] **Step 4: Commit**

```bash
git -C ~/dotfiles add local/.local/bin/claude-to-obsidian
git -C ~/dotfiles commit -m "feat: add claude-to-obsidian summary script"
```

---

### Task 3: Register the StopSession hook in settings.json

**Files:**
- Modify: `~/.claude/settings.json`

- [ ] **Step 1: Add StopSession hook**

Open `~/.claude/settings.json` and add a `StopSession` key to the `hooks` object alongside the existing `SessionStart`:

```json
"StopSession": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "claude-to-obsidian",
        "statusMessage": "Saving session summary to Obsidian..."
      }
    ]
  }
]
```

The full `hooks` section should look like:

```json
"hooks": {
  "SessionStart": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "for p in $(pgrep -x mcp-language-server 2>/dev/null); do pp=$(ps -o ppid= -p $p 2>/dev/null | tr -d ' '); pgrep -x claude | grep -qx \"$pp\" || kill -9 $p 2>/dev/null; done; true",
          "statusMessage": "Cleaning up orphaned clangd processes..."
        }
      ]
    }
  ],
  "StopSession": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "claude-to-obsidian",
          "statusMessage": "Saving session summary to Obsidian..."
        }
      ]
    }
  ]
}
```

- [ ] **Step 2: Verify JSON is valid**

```bash
python3 -m json.tool ~/.claude/settings.json > /dev/null && echo "valid" || echo "invalid"
```

Expected: `valid`

- [ ] **Step 3: Test the script manually**

```bash
CLAUDE_SESSION_NAME="test" CLAUDE_TRANSCRIPT="/dev/null" claude-to-obsidian
cat ~/Documents/obsidian/Claude/$(date +%Y-%m-%d)-test.md
```

Expected: a note with the session name and date, with a fallback message since transcript is empty.

- [ ] **Step 4: Commit settings**

`settings.json` is symlinked via `~/dotfiles/claude` — commit from there:

```bash
git -C ~/dotfiles add claude/settings.json
git -C ~/dotfiles commit -m "feat: add StopSession hook to write Obsidian summary"
```

---

### Task 4: Set ANTHROPIC_API_KEY in zsh environment

**Files:**
- Modify: `~/dotfiles/zsh/.zshrc` or a separate `~/dotfiles/zsh/.zshenv`

- [ ] **Step 1: Check if ANTHROPIC_API_KEY is already set**

```bash
echo $ANTHROPIC_API_KEY | head -c 10
```

If empty, proceed. If already set, skip to Task 5.

- [ ] **Step 2: Add API key export to .zshenv**

`.zshenv` is sourced for all zsh instances including non-interactive ones (like hooks). Add to `~/dotfiles/zsh/.zshenv` (create if it doesn't exist):

```bash
echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/dotfiles/zsh/.zshenv
```

Replace `sk-ant-...` with your actual key from https://console.anthropic.com.

Then stow:

```bash
cd ~/dotfiles && stow zsh
```

- [ ] **Step 3: Verify**

Open a new terminal and run:

```bash
echo $ANTHROPIC_API_KEY | head -c 10
```

Expected: `sk-ant-api`

---
