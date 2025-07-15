#!/bin/bash

find content -type f -name "*.md" ! -name "*.vi.md" | while read -r file; do
  vi_file="${file%.md}.vi.md"

  # Only create the duplicate if it doesn't already exist
  if [[ ! -e "$vi_file" ]]; then
    cp "$file" "$vi_file"
    echo "Created: $vi_file"
  else
    echo "Skipped (already exists): $vi_file"
  fi
done
