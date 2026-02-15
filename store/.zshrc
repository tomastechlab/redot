# Session
export GDK_BACKEND=wayland
export EXPOSWAYDIR="$HOME/.local/state/exposway/"
export EXPOSWAYMON="$EXPOSWAYDIR/output"
export ELECTRON_OZONE_PLATFORM_HINT=auto
export EDITOR=nvim

# podman related env
#export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
#export DOCKER_HOST=unix://run/containerd/containerd.sock
export DOCKER_BUILDKIT=1

export XDG_RUNTIME_DIR=/run/user/$(id -u)

#ssh-add -q
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent -t 1h > "$XDG_RUNTIME_DIR/ssh-agent.env"
fi
if [ ! -f "$SSH_AUTH_SOCK" ]; then
    source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
fi

# nix / devenv / direnv 
PATH="/home/tomas/.nix-profile/bin:$PATH"
# eval "$(direnv hook zsh)"

# NVM
[ -z "$NVM_DIR" ] && export NVM_DIR="$HOME/.nvm"
source /usr/share/nvm/nvm.sh
source /usr/share/nvm/bash_completion

# Aliasses
alias vim=nvim
alias df=duf
alias ls='eza -lagbh --git --group-directories-first'
alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'
#alias dco=podman-compose
#alias d=podman

# Exports
export PAGER='less'
export MANPAGER='less'
export GROFF_NO_SGR=1
export MANROFFOPT=-c

# Path
export PATH=~/.bin:$PATH
export PATH="$HOME/.symfony5/bin:$PATH"

# Prompt
fpath+=($HOME/.zsh/pure)
autoload -U promptinit; promptinit
prompt pure
zstyle :prompt:pure:git:stash show yes

# Plugins
source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-fzf-history-search/zsh-fzf-history-search.plugin.zsh
source ~/.zsh/colored-man-pages/colored-man-pages.plugin.zsh 

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
setopt autocd extendedglob nomatch correct
bindkey -v
bindkey '^R' history-incremental-search-backward
bindkey "^[[1;5C" emacs-forward-word
bindkey "^[[1;5D" emacs-backward-word
bindkey "^[[3~" delete-char  # Del key
# bindkey "^?" backward-delete-char  # Backspace key

# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/tomas/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

if [ "$TMUX" = "" ]; then ;
	tmux attach -t main || tmux new-session -A -D -s main
fi
~/.bin/tmuxed_ssh.sh

export PATH="/home/tomas/.lando/bin:$PATH"; #landopath

# export PATH="/home/tomas/.config/herd-lite/bin:$PATH"
# export PHP_INI_SCAN_DIR="/home/tomas/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"
