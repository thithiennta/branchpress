# Changelog

## 0.2.0

- **Disk:** MySQL now runs without the binary log. v0.1 kept a 30-day copy of every site clone and reset. Existing installs are migrated automatically on the next command; data is kept.
- **Auto-prune:** sites whose worktree was deleted are removed on the next `up` or `ls`. Disable with `BRANCHPRESS_AUTO_PRUNE=0`.
- `prune` also removes stray site databases and core volumes that no site owns.
- New `branchpress du`: disk use per snapshot, per site, and for shared containers and images.
- `up` no longer sends a "Password Changed" email for the admin user.

## 0.1.0

- Initial release.
