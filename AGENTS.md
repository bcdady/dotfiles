# AGENTS.md

This file provides guidance to AI Agents when working with code in this repository.

## What This Is

Profile dotfiles managed by [chezmoi](https://www.chezmoi.io/), targeting **macOS (darwin)** and **Ubuntu Linux**. The source directory (`~/.local/share/chezmoi`) contains templates and scripts that chezmoi renders and applies to the home directory. This is NOT a software project — there is no build system, package manager, or test suite.

## Key Commands

```bash
# Preview what chezmoi would change
chezmoi diff

# Apply dotfiles to the home directory
chezmoi apply

# Apply a single file
chezmoi apply ~/.bashrc

# Edit a managed file (opens in editor, then applies)
chezmoi edit ~/.bashrc

# Add an existing file to chezmoi management
chezmoi add ~/.some_config

# Re-run template rendering after changing .tmpl files
chezmoi execute-template < file.tmpl   # dry-run a template

# Check managed file status
chezmoi status
```

## Chezmoi Naming Conventions

Chezmoi uses filename prefixes to control behavior. These are **not** arbitrary — they map directly to target paths and attributes:

- `dot_` → `.` (e.g., `dot_bashrc` → `~/.bashrc`)
- `private_dot_` → `.` with `0600` permissions (e.g., `private_dot_gitconfig.tmpl` → `~/.gitconfig`)
- `.tmpl` suffix → file is a Go `text/template` processed at apply time
- `run_` prefix → script executed by `chezmoi apply` (not installed as a file)
- `run_once_` prefix → script executed only once (tracked by checksum)
- `.chezmoiscripts/` → directory for run-once scripts separate from the source root

## Template System

`.tmpl` files use Go `text/template` syntax with chezmoi-provided data:

- **OS detection**: `{{ .chezmoi.os }}` — values are `"darwin"` (macOS) or `"linux"` (Ubuntu)
- **Conditionals**: `{{- if eq .chezmoi.os "linux" }}...{{- end }}`
- **Bitwarden integration**: `{{ (bitwarden "item" "github.com").login.username }}` — requires `bw` CLI unlocked
- **Shell output**: `{{ output "sh" "-c" "bw status 2>/dev/null | jq -r .status" | trim }}`

When editing `.tmpl` files, always test rendering with `chezmoi execute-template` or `chezmoi diff` before applying.

## Architecture

### Platform Branching

Almost every `.tmpl` file branches on `{{ .chezmoi.os }}` to handle macOS vs Linux differences:
- **macOS**: Homebrew for package management, zsh as default shell, Oh My Zsh
- **Linux**: apt/snap for packages, bash as default shell, starship prompt, hstr for history

### Shell Initialization Chain

On Linux (bash): `~/.profile` → `~/.bashrc` → `~/.my_tools` → `~/.my_aliases`
On macOS (zsh): `~/.profile` → `~/.zshrc` (Oh My Zsh + Powerlevel10k)

### Tool Management

`dot_mise.toml` defines all dev tool versions via [mise](https://mise.jdx.dev/). Tools include AWS CLI, Terraform, kubectl, Helm, Go, Node, Python, and many others. mise is activated in `dot_my_tools.tmpl`.

### Secrets

Sensitive values (git email addresses) are pulled from Bitwarden at template render time. The gitconfig templates check `bw status` and only populate email if the vault is unlocked. The `.chezmoiscripts/run_once_bw_unlock.sh` script handles initial vault unlock during first apply.

### Git Configuration

`private_dot_gitconfig.tmpl` is the main git config. It uses `[includeIf]` to switch between work (`~/.gitconfig.work`) and personal (`~/.gitconfig.personal`) email based on the repo directory path (`**/github/bcdady/**`).

### Bootstrap Scripts

`run_*.tmpl` files at the root are chezmoi run scripts that install system-level tooling on first apply:
- `run_brew_setup.tmpl` — installs Homebrew (macOS) or snapd (Linux)
- `run_tools_setup.tmpl` — installs GUI apps and CLI tools via brew/apt/snap
- `run_ohmyzsh_setup.tmpl` — installs Oh My Zsh on macOS
- `run_openvpn3_setup.tmpl` — installs OpenVPN client

### CI

GitHub Actions run on push/PR to `main`:
- **ci.yml** — semver release via `huggingface/semver-release-action`
- **commit.yml** — enforces [Conventional Commits](https://www.conventionalcommits.org/) on PRs
- **semgrep.yml** — static analysis scan

Commit messages must follow Conventional Commits format (e.g., `feat:`, `fix:`, `chore:`).
