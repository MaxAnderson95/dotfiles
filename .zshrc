#zmodload zsh/zprof

# Source private configuration
if [[ -f ~/.zshrc_private ]]; then
  source ~/.zshrc_private
fi

#source ~/.zshplugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh
autoload -Uz compinit
autoload -U +X bashcompinit && bashcompinit
compinit

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

function activate() {
  if [[ -d "./.venv/bin" ]]; then
    source ./.venv/bin/activate
  else
    echo "Error: ./.venv/bin does not exist. Are you in the right directory?"
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
  sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
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
    # Handle range (e.g., 1-3)
    local start="${input%-*}"
    local end="${input#*-}"
    
    if [[ "$start" =~ ^[0-9]+$ ]] && [[ "$end" =~ ^[0-9]+$ ]]; then
      query="select(di >= $start and di <= $end)"
    else
      echo "Error: Invalid range format. Use format like '1-3'"
      return 1
    fi
  elif [[ "$input" == *","* ]]; then
    # Handle comma-separated list (e.g., 1,3,5)
    local -a nums
    IFS=',' read -A nums <<< "$input"
    
    local query_parts=()
    for num in "${nums[@]}"; do
      num="${num// /}" # Remove any spaces
      if [[ "$num" =~ ^[0-9]+$ ]]; then
        query_parts+=("di == $num")
      else
        echo "Error: Invalid number '$num' in list"
        return 1
      fi
    done
    
    # Join with " or " and wrap in select()
    query="select(${query_parts[1]}"
    for ((i=2; i<=${#query_parts[@]}; i++)); do
      query="$query or ${query_parts[$i]}"
    done
    query="$query)"
  else
    # Handle single number
    if [[ "$input" =~ ^[0-9]+$ ]]; then
      query="select(di == $input)"
    else
      echo "Error: Invalid input. Must be a number, range (1-3), or comma-separated list (1,3,5)"
      return 1
    fi
  fi
  
  yq "$query"
}

function bell() {
  echo -e "\a"
}

function chrome() {
  if [ -z "$1" ]; then
    echo "Usage: chrome <URL>"
    echo "Example: chrome https://www.google.com"
    return 1 # Use 'return' in functions instead of 'exit'
  fi

  local URL="$1" # Use 'local' for variables inside functions

  open -a "Google Chrome" -u "$URL"
}

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


export TENV_DETACHED_PROXY=false
export PYTHONDONTWRITEBYTECODE=1
export K9S_CONFIG_DIR=~/.config/k9s
export KUBE_EDITOR=nvim
export TENV_AUTO_INSTALL=true
export GREP_OPTIONS='--color=auto'

#export NODE_TLS_REJECT_UNAUTHORIZED=0
#export REQUESTS_CA_BUNDLE=/Users/max/Documents/Certificates/proxy.pem

alias ls='eza --long --all --time-style relative --group-directories-first --git --no-permissions --no-user --color always --ignore-glob .DS_Store'
alias k=kubectl
neat() {
  kubectl neat | yq "$@"
}
alias kc=kubecm --config /Users/max/.kube/config # This ensures that when using switch command, kc write-type commands always touch the main kubeconfig
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
alias java-21="export JAVA_HOME=`/usr/libexec/java_home -v 21`"
alias java-11="export JAVA_HOME=`/usr/libexec/java_home -v 11`"
java-11

alias home=cd ~
source ~/.config/fzf/completions.zsh
source ~/.config/fzf/key-bindings.zsh
#source <(pkgx --shellcode)
source <(kubectl completion zsh)
source <(jwt completion bash)
eval "$(starship init zsh)"
eval "$(zoxide init --cmd cd zsh)"
# Lazy load thefuck - only initialize on first use
fuck() {
  unset -f fuck fk
  eval $(thefuck --alias)
  eval $(thefuck --alias fk)
  fuck "$@"
}
fk() {
  unset -f fuck fk
  eval $(thefuck --alias)
  eval $(thefuck --alias fk)
  fk "$@"
}
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
source $HOME/.tenv.completion.zsh

# Lazy load nvm - only load when needed
export NVM_DIR="$HOME/.nvm"
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

function code() {
  # Define the workspace storage path.
  WORKSPACE_STORAGE="$HOME/Library/Application Support/Code/User/workspaceStorage"

  # Check if the workspace storage directory exists.
  if [ -d "$WORKSPACE_STORAGE" ]; then
    # Use a subshell to temporarily enable 'nullglob', so that
    # if no files match the pattern, the glob expands to nothing.
    (
      setopt nullglob
      /bin/rm -rf "$WORKSPACE_STORAGE"/*
    )
  else
    echo "Workspace storage not found at: $WORKSPACE_STORAGE"
  fi

  # Launch VS Code with all provided arguments.
  open $1 -a "Visual Studio Code"
}

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

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/max/.lmstudio/bin"


tempo() {
    case "$1" in
        new)
            dir=$(command tempo new | grep -o 'Created temporary directory: .*' | cut -d' ' -f4)
            cd "$dir"
            ;;
        list)
            dir=$(command tempo list | grep -o 'Selected directory: .*' | cut -d' ' -f3)
            if [ -n "$dir" ]; then
                cd "$dir"
            fi
            ;;
        *)
            command tempo "$@"
            ;;
    esac
}


#zprof

# bun completions
[ -s "/Users/max/.bun/_bun" ] && source "/Users/max/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# opencode
export PATH=/Users/max/.opencode/bin:$PATH

function yolo() {
  claude --dangerously-skip-permissions "$@"
}

function how() {
  emulate -L zsh
  setopt NO_GLOB
  local query="$*"
  local prompt="You are a command line expert. The user wants to run a command but they don't know how. They are running zsh on macOS. Here is what they asked: ${query}. Return ONLY the exact shell command needed. Do not prepend with an explanation, no markdown, no code blocks - just return the raw command you think will solve their query."
  local model="gpt-4o-mini"
  local cmd
  cmd=$(llm -m $model --no-stream "$prompt" | tr -d '\000-\037' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  print -z -- "$cmd"
}
# Ensure globbing is disabled when invoking `d`
alias how='noglob how'

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc' ]; then . '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc' ]; then . '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc'; fi

. "$HOME/.atuin/bin/env"

eval "$(atuin init zsh --disable-up-arrow)"
