# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=3000
SAVEHIST=3000
# bindkey -e

# Aliases
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'

# Keybindings (vi mode)
bindkey -v

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

eval "$(starship init zsh)"
