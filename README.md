# dev-init

One command to set up a new Mac for aneko development.

Open Terminal and run:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/aneko-ai/dev-init/main/install.sh)"
```

You'll type your Mac password when asked (for Homebrew, and for apps like
Docker Desktop) and log in to GitHub in your browser. Everything else runs on
its own.

## What it does

1. Installs **Homebrew**, which also installs Apple's Command Line Tools (and
   with them, Git)
2. Installs the **GitHub CLI** and logs you in to GitHub
3. Creates **`~/dev`**, where your projects live
4. Downloads **`aneko-ai/dev-setup`** (private) to
   `~/.local/share/aneko/dev-setup`
5. Runs **`dev-setup install`**, which sets up everything else and keeps it up
   to date

Every step is skipped if it's already done, so it's safe to run again.

## Requirements

- An Apple silicon Mac
- An administrator account on it (Homebrew needs one)
- A GitHub account that's a member of the `aneko-ai` organization

## Why this repo is public

The rest of the setup lives in the private `aneko-ai/dev-setup` repo, which a
new Mac can't download until it's logged in to GitHub. This script is the
public first step that gets it there. It contains nothing secret.
