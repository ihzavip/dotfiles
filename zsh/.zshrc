# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=3000
SAVEHIST=3000

eval "$(dircolors -b)"

# Aliases
alias ls='ls --color=auto'
alias ll='ls -lh'
alias la='ls -A'
alias l='ls -CF'

# Keybindings (vi mode)
bindkey -v
# bindkey -e
bindkey '^E' autosuggest-accept


autoload -Uz colors && colors  # enable colors

# Custom PS1 prompt
PROMPT='%F{green}%n%f %F{blue}%~%f %F{yellow}%*%f
$ '

# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/lucy/.zshrc'

autoload -Uz compinit
compinit
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
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


# Load Angular CLI autocompletion.
source <(ng completion script)

# DMENU
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

# ================================
# Zsh Plugins
# ================================
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

# Change suggestion color (optional, default is gray)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
