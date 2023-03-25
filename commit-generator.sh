#!/bin/bash

# Load the API key from the .env file
source .env

# Escape the diff for JSON
escaped_diff=$(echo "$diff" | jq -sR)

# Call the OpenAI API to generate a commit message
api_key=$OPENAI_API_KEY

# Escape the diff for JSON
escaped_diff=$(echo "$diff" | jq -sR)

prompt_template='Please generate an imperative concise and informative commit message based on the following Git diff. - means that the line was removed, + means that it was added.  If there is no + or - at the start of the line, you should only use the line as context, the line has not been changed. The commit message should not end with a period:\n\n'
instruction='\n\nPlease provide a single-line commit message that briefly describes the changes made in this diff.'

# Construct the JSON payload using jq
payload=$(jq -n --arg prompt_template "$prompt_template" --arg diff "$escaped_diff" --arg instruction "$instruction" '{model: "gpt-3.5-turbo", messages: [{role: "user", content: ($prompt_template + $diff + $instruction)}] }')

response=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $api_key" \
  -d "$payload")

# Parse the response and extract the generated commit message
commit_message=$(echo "$response" | jq -r '.choices[0].message.content' | tr -d '\n')

# Check if the commit message is empty or null
if [ -z "$commit_message" ] || [ "$commit_message" = "null" ]; then
  echo "Error: Failed to generate commit message."
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
