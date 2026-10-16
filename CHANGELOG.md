# Changelog

## 0.3.0

- **`branchpress init`**: guided first-time setup in 5 steps:
  1. checks Docker (and offers to install OrbStack on macOS)
  2. installs WP-CLI and the images, starts MySQL and Mailpit
  3. asks for the plugins folder
  4. gets test data: a teammate's file, a Local site, or empty
  5. offers to install the Claude Code skill

  At the end it can start the first site. Every question has a flag for scripted setup; re-running is safe.
- **One-line installer**: `curl -fsSL https://raw.githubusercontent.com/thithiennta/branchpress/main/install.sh | bash`.
- **`snapshot add NAME --from-local SITE`**: copy a running Local (localwp.com) site directly.
- `--url` is optional: the original site URL is read from the imported database.
- Snapshot copies skip `node_modules/` and `.git/`, and tolerate files that vanish mid-copy (build watchers). A failed snapshot cleans up after itself.
- `BRANCHPRESS_INSTANCE` runs a separate set of containers with its own settings folder.
- `open` falls back to `xdg-open` on Linux.

## 0.2.1

- Deactivate YaySMTP on clone along with the other mailer plugins. Your own worktree plugins are re-activated afterwards.
- Snapshots skip `et-cache/` (Divi) and `upgrade-temp-backup/`.

## 0.2.0

- **Disk:** MySQL now runs without the binary log. v0.1 kept a 30-day copy of every site clone and reset. Existing installs are migrated automatically on the next command; data is kept.
- **Auto-prune:** sites whose worktree was deleted are removed on the next `up` or `ls`. Disable with `BRANCHPRESS_AUTO_PRUNE=0`.
- `prune` also removes stray site databases and core volumes that no site owns.
- New `branchpress du`: disk use per snapshot, per site, and for shared containers and images.
- `up` no longer sends a "Password Changed" email for the admin user.

## 0.1.0

- Initial release.
