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

function jump() {
  ssh _manderson@jump.gucu.org
}

function flushdns() {
  sudo dscacheutil -flushcache
  sudo killall -HUP mDNSResponder
}

function docker-clean-all() {
  docker container stop $(docker container ls -a -q)
  docker container rm $(docker container ls -a -q)
  docker image rm $(docker image ls -a -q)
}

function utilpod() {
  kubectl run -it --rm utility-pod-$RANDOM --image=ghcr.io/maxanderson95/utility-image:latest
}
alias devpod=utilpod

export PYTHONDONTWRITEBYTECODE=1
export K9S_CONFIG_DIR=~/.config/k9s
export KUBE_EDITOR=nvim
export PROD_SUBSCRIPTION=93927568-fb85-4c03-9732-201f9a021d83
export LAB_SUBSCRIPTION=0b2584a6-d4ed-4459-8e12-01275f7cc843
export MAX_SUBSCRIPTION=ebfe4853-7922-40bf-a01e-6d3a1565dd23

alias ls="eza --all --color=always --long --git --icons=always --no-user --no-filesize --no-time --no-permissions"
alias k=kubectl
alias kc=kubecm
alias s=switch
alias klogout='kubectl config unset current-context > /dev/null; unset KUBECONFIG'
alias clip=pbcopy
alias ccat=/bin/cat
alias cat=bat
alias vi=nvim
alias tf=tofu
alias home=cd ~

source ~/.config/fzf/completion.zsh
source ~/.config/fzf/key-bindings.zsh
source <(pkgx --shellcode)
source <(kubectl completion zsh)
eval "$(starship init zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval $(thefuck --alias)
eval $(thefuck --alias fk)
#eval "$(/Users/max/Projects/starship/target/debug/starship init zsh)"

source $HOME/.zsh-functions/tf
source $HOME/.zshplugins/az.completion
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source <(switcher init zsh)
source <(alias s=switch)
source <(switch completion zsh)
