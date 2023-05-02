#!/bin/bash
set -e

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "You are not in a Git repository."
    exit 0
fi

diff=$(git diff)

if [ "$diff" = "" ]; then
  echo "No changes detected. Exiting."
  exit 0
fi

# Set default model to GPT-3
model="gpt-3.5-turbo"

# Parse the arguments
while getopts ":m:" opt; do
  case $opt in
    m)
      model="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Escape the diff for JSON
escaped_diff=$(echo "$diff" | jq -sR)

# Call the OpenAI API to generate a commit message
api_key=$OPENAI_API_KEY

if [ -z "$api_key" ]; then
  echo "Error: Missing OpenAI API key. Please set the OPENAI_API_KEY environment variable."
  exit 1
fi

prompt_template="Rewrite the following Git diff into a concise and informative commit message within 75 characters preferably less, using the '-' to indicate removed lines and '+' for added lines. Use unchanged lines for context only:\n"
instruction='\n\nProvide a short and concise imperative single-line commit message that briefly describes the changes made in this diff.'

# Construct the JSON payload using jq
payload=$(jq -n --arg prompt_template "$prompt_template" --arg diff "$escaped_diff" --arg instruction "$instruction" --arg model "$model" '{model: $model, messages: [{role: "user", content: ($prompt_template + $diff + $instruction)}] }')

response=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $api_key" \
  -d "$payload")

# Parse the response and extract the generated commit message
commit_message=$(echo "$response" | jq -r '.choices[0].message.content' | tr -d '\n' | sed 's/\.$//')

# Check if the commit message is empty or null
if [ -z "$commit_message" ] || [ "$commit_message" = "null" ]; then
  echo "Error: Failed to generate commit message."
  echo "Response from API:"
  echo "$response"
  exit 1
fi

# Print the commit message
echo "$commit_message"

# Prompt the user to confirm the commit
read -p "Commit these changes? [y/N] " confirm
if [ "$confirm" = "y" ]; then
  git commit -am "$commit_message"
else
  echo "Aborted commit."
fi
