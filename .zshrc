# ============================================================================
# Private Configuration
# ============================================================================
if [[ -f ~/.zshrc_private ]]; then
  source ~/.zshrc_private
fi

# ============================================================================
# Completion System
# ============================================================================
#source ~/.zshplugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh
autoload -Uz compinit
autoload -U +X bashcompinit && bashcompinit
compinit

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# ============================================================================
# Environment Variables
# ============================================================================
export TENV_DETACHED_PROXY=false
export PYTHONDONTWRITEBYTECODE=1
export K9S_CONFIG_DIR=~/.config/k9s
export KUBE_EDITOR=nvim
export TENV_AUTO_INSTALL=true
export GREP_OPTIONS='--color=auto'
export NVM_DIR="$HOME/.nvm"
export BUN_INSTALL="$HOME/.bun"
export ARM_SUBSCRIPTION_ID=$PROD_SUBSCRIPTION
export TRY_PATH="$HOME/Projects/tries"
export DOCKER_HOST=unix://$HOME/.local/share/containers/podman/machine/podman.sock

# ============================================================================
# PATH Configuration
# ============================================================================
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export PATH="/Users/max/.local/bin:$PATH"
export PATH="$PATH:/Users/max/.lmstudio/bin"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH=/Users/max/.opencode/bin:$PATH

# ============================================================================
# Aliases
# ============================================================================
alias ls='eza --long --all --time-style relative --group-directories-first --git --no-permissions --no-user --color always --ignore-glob .DS_Store'
alias k=kubectl
alias kc=kubecm --config /Users/max/.kube/config
alias d=docker
alias docker=podman
alias s=switch
alias klogout='kubectl config unset current-context > /dev/null; unset KUBECONFIG'
alias clip=pbcopy
alias ccat=/bin/cat
alias cat=bat
alias xxd=hexyl
alias vi=nvim
alias f=yazi
alias ..="cd .."
alias ...="cd ../../"
alias ....="cd ../../../"
alias .....="cd ../../../../"
alias temp="cd $(mktemp -d)"
alias home=cd ~
alias copysshkey=getsshkey
alias how='noglob how'
alias rg='rg -uu'

# Java version management
alias java-21="export JAVA_HOME=`/usr/libexec/java_home -v 21`"
alias java-11="export JAVA_HOME=`/usr/libexec/java_home -v 11`"
java-11

# ============================================================================
# Functions - Utility
# ============================================================================
function vizsh() {
  nvim ~/.zshrc
  source ~/.zshrc
}

function vizshprivate() {
  nvim ~/.zshrc_private
  source ~/.zshrc
}

function getsshkey() {
  cat ~/.ssh/id_rsa.pub | pbcopy
  echo "Copied SSH public key to clipboard."
}

function flushdns() {
  sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
}

# ============================================================================
# Functions - Development Tools
# ============================================================================
function activate() {
  if [[ -d "./.venv/bin" ]]; then
    source ./.venv/bin/activate
  else
    echo "Error: ./.venv/bin does not exist. Are you in the right directory?"
  fi
}

function code() {
  WORKSPACE_STORAGE="$HOME/Library/Application Support/Code/User/workspaceStorage"

  if [ -d "$WORKSPACE_STORAGE" ]; then
    (
      setopt nullglob
      /bin/rm -rf "$WORKSPACE_STORAGE"/*
    )
  else
    echo "Workspace storage not found at: $WORKSPACE_STORAGE"
  fi

  open $1 -a "Visual Studio Code"
}

function yolo() {
  claude --dangerously-skip-permissions "$@"
}

function how() {
  emulate -L zsh
  setopt NO_GLOB
  local query="$*"
  local prompt="You are a command line expert. The user wants to run a command but they don't know how. They are running zsh on macOS. Here is what they asked: how ${query}. Return ONLY the exact shell command needed. Do not prepend with an explanation, no markdown, no code blocks - just return the raw command you think will solve their query."
  local model="gpt-4o-mini"
  #local model="gpt-5.1"
  local cmd
  cmd=$(llm -m $model --no-stream "$prompt" | tr -d '\000-\037' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  print -z -- "$cmd"
}

function kind() {
  # Save current KUBECONFIG if set
  local _old_kubeconfig=""
  if [[ -n "${KUBECONFIG:-}" ]]; then
    _old_kubeconfig="$KUBECONFIG"
  fi

  # Clear current kubectl context and KUBECONFIG
  kubectl config unset current-context > /dev/null 2>&1
  unset KUBECONFIG

  # Run the real kind command with all original args
  command kind "$@"
  local kind_status=$?

  # Restore KUBECONFIG only if it was previously set
  if [[ -n "$_old_kubeconfig" ]]; then
    export KUBECONFIG="$_old_kubeconfig"
  fi

  return $kind_status
}

# ============================================================================
# Functions - Data/Document Processing
# ============================================================================
neat() {
  kubectl neat | yq "$@"
}

function document() {
  local input="$1"

  if [[ -z "$input" ]]; then
    echo "Usage: document <number|range|list>"
    echo "Examples:"
    echo "  document 5        # Single document"
    echo "  document 1-3      # Range of documents"
    echo "  document 1,3,5    # Comma-separated list"
    return 1
  fi

  local query=""

  if [[ "$input" == *"-"* ]]; then
    local start="${input%-*}"
    local end="${input#*-}"

    if [[ "$start" =~ ^[0-9]+$ ]] && [[ "$end" =~ ^[0-9]+$ ]]; then
      query="select(di >= $start and di <= $end)"
    else
      echo "Error: Invalid range format. Use format like '1-3'"
      return 1
    fi
  elif [[ "$input" == *","* ]]; then
    local -a nums
    IFS=',' read -A nums <<< "$input"

    local query_parts=()
    for num in "${nums[@]}"; do
      num="${num// /}"
      if [[ "$num" =~ ^[0-9]+$ ]]; then
        query_parts+=("di == $num")
      else
        echo "Error: Invalid number '$num' in list"
        return 1
      fi
    done

    query="select(${query_parts[1]}"
    for ((i=2; i<=${#query_parts[@]}; i++)); do
      query="$query or ${query_parts[$i]}"
    done
    query="$query)"
  else
    if [[ "$input" =~ ^[0-9]+$ ]]; then
      query="select(di == $input)"
    else
      echo "Error: Invalid input. Must be a number, range (1-3), or comma-separated list (1,3,5)"
      return 1
    fi
  fi

  yq "$query"
}

# ============================================================================
# Functions - Docker/Infrastructure
# ============================================================================
function docker-clean-all() {
    alias docker=podman
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
    echo -n "Are you sure you want to delete .terraform, .terraform.lock.hcl, terraform.tfstate, and terraform.tfstate.backup? (y/n): "
    read -r REPLY
    echo
    if [[ $REPLY == [Yy] ]]; then
        rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup
        echo "Terraform files and directories removed."
    else
        echo "Operation cancelled."
    fi
}

# ============================================================================
# Functions - Kubernetes
# ============================================================================
function check_k8s_update_status() {
  clear
  while true; do
    kubectl version
    echo "Node Versions:"
    kubectl get nodes -o json | jq -r '.items[] | "\(.metadata.name): \(.status.nodeInfo.kubeletVersion)"'
    echo
    sleep 5
    clear
  done
}

# ============================================================================
# Shell Enhancements
# ============================================================================
eval "$(starship init zsh)"
eval "$(zoxide init --cmd cd zsh)"

# ============================================================================
# Lazy Loading - NVM
# ============================================================================
nvm() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm "$@"
}
node() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  node "$@"
}
npm() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  npm "$@"
}
npx() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  npx "$@"
}

# ============================================================================
# Completions and Tool Sources
# ============================================================================
source ~/.config/fzf/completions.zsh
source ~/.config/fzf/key-bindings.zsh
source <(kubectl completion zsh)
source <(jwt completion bash)
source $HOME/.zsh-functions/tf
source $HOME/.zshplugins/az.completion
source <(switcher init zsh)
source <(alias s=switch)
source <(switch completion zsh)
source <(helm completion zsh)
source $HOME/.tenv.completion.zsh
source <(stern --completion=zsh)
[ -s "/Users/max/.bun/_bun" ] && source "/Users/max/.bun/_bun"

# Google Cloud SDK
if [ -f '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc' ]; then . '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc'; fi
if [ -f '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc' ]; then . '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc'; fi

# ============================================================================
# Plugins
# ============================================================================
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ============================================================================
# Final Initialization
# ============================================================================
. "$HOME/.atuin/bin/env"
eval "$(atuin init zsh --disable-up-arrow)"
#eval "$(ruby ~/.local/try.rb init)"
eval "$(try init $TRY_PATH)"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
