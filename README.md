# Git Commit Message Generator

This script generates commit messages using the OpenAI GPT-3.5-turbo model based on the provided Git diff. It prompts the user to confirm the commit with the generated message.

## Prerequisites

- [jq](https://stedolan.github.io/jq/)
- [curl](https://curl.se/)
- An OpenAI API key

## Setup

1. Clone this repository
2. Install `jq` and `curl` if you haven't already:
- For Ubuntu/Debian:
```
sudo apt-get install jq curl
```
- For macOS (using [Homebrew](https://brew.sh/)):
```
brew install jq curl
```

3. Set your OpenAI API key as an environment variable directly in your terminal:
```
export OPENAI_API_KEY=your_api_key_here
```
