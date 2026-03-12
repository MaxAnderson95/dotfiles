#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Function to create a progress bar with color gradient
# Args: $1 = percentage (0-100), $2 = bar_length (default 5)
create_progress_bar() {
  local pct=$1
  local length=${2:-5}
  local filled=$((pct * length / 100))
  local empty=$((length - filled))

  # Determine color based on percentage
  local color
  if [ "$pct" -lt 50 ]; then
    color="\033[32m"  # Green
  elif [ "$pct" -lt 75 ]; then
    color="\033[33m"  # Yellow
  elif [ "$pct" -lt 90 ]; then
    color="\033[38;5;208m"  # Orange
  else
    color="\033[31m"  # Red
  fi

  # Build the bar
  local bar=""
  for ((i=0; i<filled; i++)); do
    bar="${bar}█"
  done
  for ((i=0; i<empty; i++)); do
    bar="${bar}░"
  done

  printf "${color}${bar}\033[0m"
}

# Extract basic info
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Get git branch
git_branch=$(git -C "$cwd" -c gc.autoDetach=false branch --show-current 2>/dev/null)
[ -z "$git_branch" ] && git_branch="none"

# Get kubernetes context
k8s_context=$(kubectl config current-context 2>/dev/null)
[ -z "$k8s_context" ] && k8s_context="none"

# Calculate context window usage percentage
context_window_size=$(echo "$input" | jq '.context_window.context_window_size')
cache_read=$(echo "$input" | jq '.context_window.current_usage.cache_read_input_tokens // 0')
cache_creation=$(echo "$input" | jq '.context_window.current_usage.cache_creation_input_tokens // 0')
input_tokens=$(echo "$input" | jq '.context_window.current_usage.input_tokens // 0')
context_tokens=$((cache_read + cache_creation + input_tokens))
context_pct=$((context_tokens * 100 / context_window_size))

# Create context progress bar
context_bar=$(create_progress_bar "$context_pct" 5)

# Build status line
output=""

# Current directory (dimmed)
output+="\033[2m${cwd}\033[0m"

# Kubernetes context (yellow)
output+=" \033[33m󱃾 ${k8s_context}\033[0m"

# Git branch (green)
output+=" \033[32m󰊢 ${git_branch}\033[0m"

# Context window usage bar
output+=" \033[36m󱦟\033[0m ${context_bar} \033[2m${context_pct}%\033[0m"

echo -e "$output"
