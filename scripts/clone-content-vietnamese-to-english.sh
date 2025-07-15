#!/bin/bash

find content -type f -name "*.vi.md" | while read -r file; do
  # Determine corresponding .md file
  md_file="${file%.vi.md}.md"

  # Skip if the .md file already exists
  if [[ ! -e "$md_file" ]]; then
    cp "$file" "$md_file"
    echo "Created: $md_file"
  else
    echo "Skipped (already exists): $md_file"
  fi
done
