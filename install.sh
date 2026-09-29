#!/bin/bash
#
# dev-init: set up a new Mac for aneko development.
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/aneko-ai/dev-init/main/install.sh)"
#
# Gets the Mac far enough to download the private aneko-ai/dev-setup repo,
# then hands over to it:
#
#   1. Homebrew. Its installer also installs Apple's Command Line Tools,
#      which include Git.
#   2. GitHub CLI, and a GitHub login in your browser
#   3. ~/dev, where your projects live
#   4. aneko-ai/dev-setup, downloaded to ~/.local/share/aneko/dev-setup
#   5. `dev-setup install`, which does the rest
#
# Each step is skipped if it's already done, so it's safe to run again.

set -euo pipefail

REPO="aneko-ai/dev-setup"
DEST="$HOME/.local/share/aneko/dev-setup"
BREW=/opt/homebrew/bin/brew

step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
say()  { printf '    %s\n' "$*"; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

[[ "$(uname -s)" == Darwin ]] || die "dev-init is for macOS."
[[ "$(uname -m)" == arm64 ]] || die "dev-init supports Apple silicon Macs only."
[[ $EUID -ne 0 ]] || die "Run this as yourself, not with sudo. It asks for your password when it needs it."
# Piping into bash (curl … | bash) takes over the keyboard, so prompts can't be answered.
[[ -t 0 ]] || die "Run it as: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/aneko-ai/dev-init/main/install.sh)\""

printf '\033[1mSetting up this Mac for aneko development\033[0m\n'

step "Homebrew"
if [[ -x $BREW ]]; then
  say "already installed"
else
  say "installing (it will ask for your Mac password)…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
[[ -x $BREW ]] || die "Homebrew didn't install. Scroll up for its error, fix it, then run dev-init again."
eval "$("$BREW" shellenv)"

step "Git"
# Check the Command Line Tools first: without them, running git opens an install pop-up.
if xcode-select -p >/dev/null 2>&1 && git --version >/dev/null 2>&1; then
  say "$(git --version)"
else
  die "Git isn't working because Apple's Command Line Tools didn't install. Run: xcode-select --install, then run dev-init again."
fi

step "GitHub"
if command -v gh >/dev/null 2>&1; then
  say "GitHub CLI already installed"
else
  "$BREW" install gh
fi
if gh auth status --hostname github.com >/dev/null 2>&1; then
  say "logged in as $(gh api user --jq .login)"
else
  say "Log in with the GitHub account that's a member of aneko-ai."
  gh auth login --hostname github.com --git-protocol https --web
fi
# Let Git use that login: for the download below, and for the daily sync.
if ! git config --global --get-regexp '^credential\..*helper$' 2>/dev/null | grep -q 'gh auth git-credential'; then
  gh auth setup-git --hostname github.com
fi
# GitHub answers "not found" both for a repo that doesn't exist and for one
# you can't see, so the message has to cover both.
if ! gh repo view "$REPO" >/dev/null 2>&1; then
  die "Couldn't reach $REPO as $(gh api user --jq .login). Either this account isn't in the aneko-ai organization (ask an admin to add you) or the repo doesn't exist yet. Then run dev-init again."
fi

step "~/dev"
if [[ -d "$HOME/dev" ]]; then
  say "already there"
else
  mkdir -p "$HOME/dev"
  say "created; your projects go here"
fi

step "$REPO"
if [[ -d "$DEST/.git" ]]; then
  git -C "$DEST" pull --quiet --ff-only
  say "updated"
else
  mkdir -p "$(dirname "$DEST")"
  git clone --quiet "https://github.com/$REPO.git" "$DEST"
  say "downloaded to ~/.local/share/aneko/dev-setup"
fi

exec "$DEST/bin/dev-setup" install
