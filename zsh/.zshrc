# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=3000
SAVEHIST=3000
# IGNOREEOF=100

export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Aliases
alias keyboard='keyboard-setup'
alias ls='ls --color=auto'
alias ll='ls -lh -A'
alias la='ls -A'
alias l='ls -CF'
alias nf='clear && neofetch'
alias q='exit'
alias icat="kitten icat" # image, picture
alias tl="tmux ls"
alias i3-save="$HOME/Utility/i3-restore/i3-save" # save i3 session layout
ta() { tmux attach -t "$1" }
td() { tmux detach-client -s "$1" }
tk() { tmux kill-session -t "$1" }

# yazi: cd into last directory on exit
y() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

export CLAUDE_CODE_NO_FLICKER=1

# Keybindings (vi mode)
bindkey -v
# bindkey -e
bindkey '^E' autosuggest-accept


autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
# End of lines added by compinstall

# (Optional) Cache to speed up startup
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

export NVM_DIR="$HOME/.nvm"
nvm() { unset -f nvm node npm npx; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; nvm "$@"; }
node() { unset -f nvm node npm npx; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; node "$@"; }
npm() { unset -f nvm node npm npx; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; npm "$@"; }
npx() { unset -f nvm node npm npx; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; npx "$@"; }

# DMENU
export EDITOR=nvim
export VISUAL=nvim


# Schemaspy
alias erd='schemaspy -t mariadb \
  -dp /usr/share/java/mariadb-jdbc/mariadb-java-client.jar \
  -host 127.0.0.1 \
  -port 3306 \
  -db project_management \
  -s project_management \
  -u root \
  -p root \
  -vizjs \
  -o ~/schemaspy-output/project_management && \
  xdg-open ~/schemaspy-output/project_management/index.html'

alias erdN='schemaspy -t mariadb \
  -dp /usr/share/java/mariadb-jdbc/mariadb-java-client.jar \
  -host 127.0.0.1 \
  -port 3306 \
  -db northwind \
  -s northwind \
  -u root \
  -p root \
  -vizjs \
  -o ~/schemaspy-output/northwind && \
  xdg-open ~/schemaspy-output/northwind/index.html'
# ================================
# Zsh Plugins
# ================================
zle-keymap-select() {}
zle -N zle-keymap-select
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

# Change suggestion color (optional, default is gray)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

export LESS='-R'
export MANPAGER='less -R'
export PAGER='less -R'

# ================================
# fzf
# ================================
# Shell integration (Ctrl+R, Ctrl+T, Alt+C)
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# Use fd as the default find backend (faster, respects .gitignore)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# Appearance: gruvbox dark + preview window (toggle with Ctrl+/)
export FZF_DEFAULT_OPTS="
  --height 40%
  --border rounded
  --layout reverse
  --prompt '❯ '
  --color=bg+:#3c3836,bg:#282828,spinner:#fb4934,hl:#928374
  --color=fg:#ebdbb2,header:#928374,info:#8ec07c,pointer:#fb4934
  --color=marker:#fb4934,fg+:#ebdbb2,prompt:#fb4934,hl+:#fb4934
  --preview 'cat {}'
  --preview-window right:50%:hidden
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down'
"

eval "$(zoxide init zsh)"

# Starship must init last so it wraps zle-keymap-select after fzf and other plugins
eval "$(starship init zsh)"
# GITHUB_PERSONAL_ACCESS_TOKEN moved to ~/.zshenv so non-interactive shells
# (e.g. the env Claude Code's GitHub MCP server inherits) also get it.
