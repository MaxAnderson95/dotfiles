#source ~/.zshplugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh
autoload -Uz compinit
autoload -U +X bashcompinit && bashcompinit
compinit

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

function activate() {
    if [[ -d "./venv/bin" ]]; then
        source ./venv/bin/activate
    else
        echo "Error: ./venv/bin does not exist. Are you in the right directory?"
    fi
}

function vizsh() {
    nvim ~/.zshrc
    source ~/.zshrc
}

function getsshkey() {
    cat ~/.ssh/id_rsa.pub | pbcopy
    echo "Copied SSH public key to clipboard."
}
alias copysshkey=getsshkey

function flushdns() {
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
}

function utilpod() {
    kubectl run -it --rm utility-pod-$RANDOM --image=ghcr.io/maxanderson95/utility-image:latest
}
alias devpod=utilpod

export PYTHONDONTWRITEBYTECODE=1
export K9S_CONFIG_DIR=~/.config/k9s
export KUBE_EDITOR=nvim

alias ls="ls -lh --color"
alias k=kubectl
alias kc=kubecm
alias klogout='kubectl config unset current-context > /dev/null'
alias clip=pbcopy
alias ccat=cat
alias cat=bat
alias vi=nvim
alias tf=tofu

source /usr/local/share/fzf/completion.zsh
source /usr/local/share/fzf/key-bindings.zsh
source <(pkgx --shellcode)
source <(kubectl completion zsh)
eval "$(starship init zsh)"
eval "$(zoxide init --cmd cd zsh)"

source $HOME/.zsh-functions/tf
source $HOME/.zshplugins/az.completion
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
