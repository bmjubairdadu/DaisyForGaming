#!/bin/bash
#
# EXAMPLES
#   ./install-hook.sh
#

# Project owner - helper repo lives under this GitHub account
# Change it to your own GitHub username if you forked the repo
GH_USER="bmjubairdadu"

# Download prepare-commit-msg hook
curl -o prepare-commit-msg https://raw.githubusercontent.com/${GH_USER}/scripts/sh/prepare-commit-msg

# Move hook to .git/hooks directory
mv prepare-commit-msg .git/hooks/prepare-commit-msg

# Make the hook executable
chmod +x .git/hooks/prepare-commit-msg

echo "prepare-commit-msg hook successfully installed!"
