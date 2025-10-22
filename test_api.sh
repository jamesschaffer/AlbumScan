#!/bin/bash

# Test Anthropic API
# Make sure to set ANTHROPIC_API_KEY environment variable first:
# export ANTHROPIC_API_KEY="your-key-here"

curl https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-3-opus-20240229",
    "max_tokens": 1024,
    "messages": [
      {"role": "user", "content": "Hello"}
    ]
  }'
