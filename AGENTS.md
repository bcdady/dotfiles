# AGENTS.md

Project rules for agents working in this repository. These dotfiles are managed
by [chezmoi](https://chezmoi.io): the repo root is the chezmoi source directory,
so most files are applied into `$HOME`.

## Commits
- **Sign off every commit.** Run `git commit -s` so each commit carries a
  `Signed-off-by` trailer (Developer Certificate of Origin). Commits without a
  sign-off are not accepted.
- **Use Conventional Commits** for the subject line: `type(scope): summary`
  (e.g. `fix:`, `feat:`, `ci:`, `docs:`, `chore:`). Pull requests to `main` are
  validated by a Conventional Commit Checker, and release versions are derived
  from commit types (`feat:` → minor, `fix:` → patch).
