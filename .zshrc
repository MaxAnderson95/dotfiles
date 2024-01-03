autoload -Uz compinit
compinit

function activate() {
    if [[ -d "./venv/bin" ]]; then
        source ./venv/bin/activate
    else
        echo "Error: ./venv/bin does not exist. Are you in the right directory?"
    fi
}

#function kc() {
#  if [[ $@ == "sw" ]]; then
#	  command kubecm switch
#  else
#	  command kubecm "$@"
#  fi
#}

function vizsh() {
    vi ~/.zshrc
    source ~/.zshrc
}


export PATH=$PATH:$(go env GOPATH)/bin
export XDG_CONFIG_HOME=$HOME/.config
alias ls="ls -lah --color"
alias k=kubectl
alias kc=kubecm
alias klogout='kubectl config unset current-context > /dev/null'
alias clip=pbcopy
alias ccat=cat
alias cat=bat
alias vi=nvim
source <(kubectl completion zsh)
source <(talosctl completion zsh)
eval "$(starship init zsh)"

export PYTHONDONTWRITEBYTECODE=1

source <(pkgx --shellcode)  #docs.pkgx.sh/shellcode

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

