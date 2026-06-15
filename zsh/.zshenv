# ~/.zshenv — sourced by ALL zsh shells (interactive, login, non-interactive).
# Put env that background/non-interactive processes need here, e.g. MCP servers
# launched by Claude Code that read ${GITHUB_PERSONAL_ACCESS_TOKEN}.

# Only resolve the token once; child shells inherit it, so skip the gh call.
if [ -z "$GITHUB_PERSONAL_ACCESS_TOKEN" ]; then
  export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token 2>/dev/null)"
fi
