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
- **lint.yml** — validates every `.tmpl` renders (`chezmoi execute-template`) and runs `shellcheck` on non-template shell files
- **semgrep.yml** — static analysis scan

Additional repo-level checks (from GitHub Apps / branch protection, not from this repo's workflow files):
- **DCO** — every commit must be `Signed-off-by:` (see [Commits](#commits))
- **GitGuardian** — secret scanning on pushed content

## Commits

- **Sign off every commit.** Run `git commit -s` so each commit carries a `Signed-off-by` trailer (Developer Certificate of Origin). Commits without a sign-off are rejected by the DCO check.
- **Use Conventional Commits** for the subject: `type(scope): summary` (e.g. `fix:`, `feat:`, `ci:`, `docs:`, `chore:`). PRs to `main` are validated by the Conventional Commit Checker, and release versions are derived from commit types (`feat:` → minor, `fix:` → patch).
- **Keep messages minimal.** Prefer a short subject; add a body only when the "why" isn't obvious from the diff. No emojis unless requested.

## Branching and PRs

- **Never push directly to `main`.** Always work on a feature branch and open a pull request.
- **Branch naming**: `type/short-slug`, matching the commit type — `fix/…`, `feat/…`, `docs/…`, `chore/…`, `ci/…`, `build/…`.
- **Open PRs with `gh`**:
  ```bash
  git checkout -b fix/some-slug
  # ...commit work with -s...
  git push -u origin fix/some-slug
  gh pr create --base main --title "fix(scope): summary" --body "..."
  ```
- **Watch CI**: `gh pr checks <number>` or `gh pr view <number> --json statusCheckRollup`.

## Shell Script Conventions

Files sourced from `.profile`/`.bashrc`/`.zshrc` at shell startup must be portable across macOS zsh and Linux bash:

- **Shebang**: `#!/bin/sh` for sourced fragments; no bashisms (no arrays, no `[[`, no `local`).
- **Guard external tools** with `command -v foo >/dev/null 2>&1` before calling them — many bootstrap paths run before tools are installed.
- **Use `_`-prefixed variables** for locals in sourced scripts (e.g. `_gldir`, `_gl_force_refresh`) and `unset` them at the end to avoid polluting the caller's environment.
- **Prefer POSIX tests**: `[ "$a" = "$b" ]`, `[ -f path ]`, `[ path1 -nt path2 ]`. Avoid `==` and `[[ ]]`.
- **Cache tokens/credentials with an invalidation signal**, not a raw TTL. If the underlying source file (config, keyring export, etc.) can change, gate the cache on `[ "$cache" -nt "$source" ]`, not just on age.

## Pre-Push Validation

Before pushing a branch, run whatever the CI would run — locally:

- **Shell syntax**: `sh -n file`, `dash -n file`, `bash -n file` (POSIX + Debian sh + bash catches most portability bugs).
- **ShellCheck**: `shellcheck path/to/script` (matches the `lint.yml` job). If `shellcheck` isn't installed locally, note it and rely on CI.
- **Chezmoi templates**: `chezmoi execute-template < path/to/file.tmpl > /dev/null` for each edited `.tmpl`; matches the `Validate chezmoi templates` job.
- **Deployed state**: `chezmoi diff` to see what would apply. After editing a source file, `chezmoi apply <target>` to deploy — the copy in `$HOME` is **not** the source of truth and drifts silently otherwise.
- **Secret scan**: `git diff --cached | grep -iE '(token|password|secret|api[_-]?key)'` before committing. Secrets should come from Bitwarden templating, never a plaintext commit.

## Guardrails — Do Not Touch Without Approval

- **`.chezmoiignore`, `.chezmoiroot`**: control what chezmoi manages; changing them can silently orphan or clobber files in `$HOME`.
- **`.chezmoidata/**`, template data files**: change platform behavior globally.
- **`private_*` files**: contain or template sensitive material; never commit rendered output.
- **`.git/`**: obvious, but stated explicitly for LLM agents.

If a task appears to require editing any of the above, stop and confirm with the user first.
