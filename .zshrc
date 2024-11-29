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

function external() {
  ssh max@172.191.71.251
}

function flushdns() {
  sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
}

function bell() {
  echo -e "\a"
}

function docker-clean-all() {
    if [ "$(docker container ls -a -q)" ]; then
        docker container stop $(docker container ls -q)
        docker container rm -f $(docker container ls -a -q)
    else
        echo "No containers to stop or remove."
    fi

    if [ "$(docker image ls -a -q)" ]; then
        docker image rm -f $(docker image ls -a -q)
    else
        echo "No images to remove."
    fi

    docker image prune -f
}

function tf_cleanup() {
    # Prompt for confirmation
    echo -n "Are you sure you want to delete .terraform, .terraform.lock.hcl, terraform.tfstate, and terraform.tfstate.backup? (y/n): "
    read -r REPLY
    echo # move to a new line
    if [[ $REPLY == [Yy] ]]; then
        # Remove the files and directories
        rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup
        echo "Terraform files and directories removed."
    else
        echo "Operation cancelled."
    fi
}

function devpod() {
  kubectl run -it --rm dev-pod-$RANDOM --labels="logicmonitor.k8s.gucu.org/ping=false" --image=ghcr.io/maxanderson95/utility-image:latest
}

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
alias ..="cd .."
alias ...="cd ../../"
alias ....="cd ../../../"
alias .....="cd ../../../../"

alias home=cd ~
source ~/.config/fzf/completion.zsh
source ~/.config/fzf/key-bindings.zsh
#source <(pkgx --shellcode)
source <(kubectl completion zsh)
eval "$(starship init zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval $(thefuck --alias)
eval $(thefuck --alias fk)
#eval "$(/Users/max/Projects/starship/target/debug/starship init zsh)"

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export PATH="/Users/max/.local/bin:$PATH"
source $HOME/.zsh-functions/tf
source $HOME/.zshplugins/az.completion
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source <(switcher init zsh)
source <(alias s=switch)
source <(switch completion zsh)
source <(helm completion zsh)

