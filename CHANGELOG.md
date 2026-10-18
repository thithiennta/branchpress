# Changelog

## 0.4.0

- **Test data per plugin**: each developer chooses once per plugin which snapshot its sites are cloned from, with the new **`branchpress use`** command (`use NAME`, `use --from-local SITE`, `use --import FILE`, `use --empty`, `use --clear`; no arguments shows the current choice). Choices are saved in `~/.branchpress/plugin-snapshots`.
- **`up` asks when it can't tell**: with several snapshots and no choice for the plugin, `up` shows a menu in a terminal (your snapshots, plus Local sites not copied yet) and saves the answer. Without a terminal it lists the choices and exits with code 3, so Claude or a script can ask and run `branchpress use`. `BRANCHPRESS_ASK=0` uses the default snapshot instead.
- **`.branchpress` `snapshot=` accepts a domain** (e.g. `snapshot=abc.dev`) and matches the snapshot copied from that site on each machine, so one committed file works for the whole team. If nothing matches, `up` asks instead of failing.
- **`snapshot refresh NAME`** copies the data again from where it came from (a Local site, an export file or a dump). The new database is swapped in safely; running sites get the new files right away and the new data on `branchpress reset`. `--from-local`/`--import` changes the source.
- Snapshots record their source. `snapshot ls` shows it and which plugins use each snapshot, and `up` prints where the site's data came from. The source of older snapshots is guessed from their URL.
- Fixed: `snapshot rm` and temp-folder cleanup could fail on the empty mount-point folders Docker Desktop creates (they carry a macOS "deny delete" ACL). Exports no longer include those folders.

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
