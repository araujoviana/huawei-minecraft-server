#!/bin/bash
set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

if [[ "$file_path" == *.tf ]] && [[ -f "$file_path" ]]; then
  terraform fmt "$file_path" >/dev/null 2>&1 || true
fi

exit 0
