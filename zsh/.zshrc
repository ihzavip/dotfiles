# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=3000
SAVEHIST=3000

export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Aliases
alias ls='ls --color=auto'
alias ll='ls -lh'
alias la='ls -A'
alias l='ls -CF'
alias nf='clear && neofetch'
alias q='exit'
alias icat="kitten icat" # image, picture

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
# Check that the function `starship_zle-keymap-select()` is defined.
# xref: https://github.com/starship/starship/issues/3418
# type starship_zle-keymap-select >/dev/null || \
#   {
#     echo "Load starship"
#     eval "$(starship init zsh)"
#   }
eval "$(starship init zsh)"

export NVM_DIR="$HOME/.nvm"
nvm() { unset -f nvm node npm npx; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; nvm "$@"; }
node() { unset -f nvm node npm npx; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; node "$@"; }
npm() { unset -f nvm node npm npx; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; npm "$@"; }
npx() { unset -f nvm node npm npx; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; npx "$@"; }

# DMENU
export EDITOR=nvim
export VISUAL=nvim

export CM_LAUNCHER="dmenu -fn 'Monospace-14' -l 15"

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
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

# Change suggestion color (optional, default is gray)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

export LESS='-R'
export MANPAGER='less -R'
export PAGER='less -R'
