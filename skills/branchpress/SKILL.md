---
name: branchpress
description: Give every WordPress plugin git worktree its own isolated test site (Docker, realistic data cloned from a snapshot, own URL) so several features can be tested in the browser at the same time. Use when installing branchpress or onboarding a developer; when starting, stopping, resetting or listing the test site for the current worktree; when a feature spans several plugins; when creating, importing or sharing a data snapshot; or when Claude needs a URL to test plugin changes in a browser.
---

# branchpress

`branchpress` (alias `bpress`) gives each plugin worktree its own WordPress site:

```
worktree  alpha-plugin @ feature-x ─┐
worktree  beta-plugin  @ feature-x ─┼─► container branchpress-alpha-plugin-feature-x ─► http://alpha-plugin-feature-x.localhost:8932
                                    │      DB site_alpha_plugin_feature_x (cloned from snapshot)
worktree  alpha-plugin @ main ──────┴─► container branchpress-alpha-plugin-main ──────► http://alpha-plugin-main.localhost:8717
shared:   branchpress-db (MySQL 8.4, host port 3407)   branchpress-mail (Mailpit, http://localhost:8025)
```

- **Snapshot**: a database dump + `wp-content` (themes, third-party plugins, uploads) of a realistic site. Imported once and stored in `~/.branchpress/snapshots/`.
- **Site**: one per worktree, named `<plugin-slug>-<branch>`. Its DB is a private clone of the snapshot, so changing data in one site never affects another. `wp-content` is shared from the snapshot, and the worktree folder(s) are mounted on top as live plugin folders, so edits show up immediately.
- All mail goes to Mailpit. Mailer plugins (WP Mail SMTP, FluentSMTP, …) are deactivated on every clone, so real customers are never emailed.

If `branchpress` isn't on PATH, try `~/.local/bin/branchpress`. If that's missing too, branchpress isn't installed yet; follow the steps below.

## Install / onboarding a developer

Claude's shell has no interactive terminal, so run `init` **with flags**. Ask the developer only for what the flags need.

1. **Docker**: run `docker info`. If it isn't running, ask them to install or start OrbStack (`brew install --cask orbstack`) or Docker Desktop. `init` can install OrbStack only when it runs in their own terminal.
2. **Ask**: which folder holds their plugin repos, and where the test data comes from:
   - a teammate's export file (`.tar.gz`)
   - a Local site name (list them with `python3 -c 'import json,os;print([s["name"] for s in json.load(open(os.path.expanduser("~/Library/Application Support/Local/sites.json"))).values()])'`)
   - or empty
3. **Run** one of:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/thithiennta/branchpress/main/install.sh | bash -s -- --plugins-dir ~/plugins --import ~/Downloads/shop.tar.gz --no-claude --no-start --yes
   curl -fsSL https://raw.githubusercontent.com/thithiennta/branchpress/main/install.sh | bash -s -- --plugins-dir ~/plugins --from-local <local-site> --no-claude --no-start --yes
   curl -fsSL https://raw.githubusercontent.com/thithiennta/branchpress/main/install.sh | bash -s -- --plugins-dir ~/plugins --empty --no-claude --no-start --yes
   ```
   If branchpress is already installed, run `branchpress init <same flags>` instead. Re-running is safe: it keeps existing snapshots and settings.
   - A Local site must be **running** in Local for `--from-local`.
   - Suggest `--sanitize` (via `branchpress snapshot add NAME ... --sanitize`) for production data.
4. **Smoke test**: in a plugin repo, run `branchpress up` and open `<url>/wp-admin/?branchpress_login=1`.
5. **Optional per-repo wiring**: commit a `.branchpress` file (format below) and append [references/claude-md-snippet.md](references/claude-md-snippet.md) to the repo's `CLAUDE.md`.

When a developer runs the installer in their own terminal (no flags), `init` asks these questions itself.

To share data with the next developer: `branchpress snapshot export shop ~/shop.tar.gz`. It contains real site data, so share it privately (not in git).

## Daily use (inside a worktree)

| Goal | Command |
|---|---|
| Start or resume this worktree's site | `branchpress up` |
| Start it and open wp-admin, logged in | `branchpress up --open` |
| Include another plugin | `branchpress up --with beta-plugin` |
| Back to a clean copy of the data | `branchpress reset` (same as `up --fresh`) |
| URL of this site | `branchpress url` |
| WP-CLI / MySQL shell | `branchpress wp plugin list` · `branchpress sql` |
| Logs | `branchpress logs --php` (debug.log) · `branchpress logs` (Apache) |
| Stop / delete this site | `branchpress down` · `branchpress down --purge` |
| See all sites | `branchpress ls` |
| Clean up after deleting worktrees | automatic on next `up`/`ls`; or `branchpress prune` |
| Disk use per snapshot / site | `branchpress du` |
| Free all RAM at the end of the day | `branchpress halt` |

`up` remembers the snapshot, port and `--with` plugins it used last time. The URL stays the same for the life of the worktree.

### Features that span several plugins

Use the **same branch name** in every plugin involved (e.g. `feature-x` in both `alpha-plugin` and `beta-plugin`). Then, from the alpha worktree:

```bash
branchpress up --with beta-plugin           # finds beta-plugin's worktree on branch feature-x; falls back to its main checkout
branchpress up --with beta-plugin@other-br  # a specific branch (that branch must have a worktree)
branchpress up --with ../some/plugin/folder # any folder
```

`up` prints which folder and branch each plugin was mounted from. Check that output when a change "doesn't show up".

### `.branchpress` (per repo, committed)

```
slug=my-plugin        # plugin folder name, if it differs from the repo folder name
snapshot=shop         # default snapshot for this plugin
with=companion-addon  # companion plugin; one line each, same syntax as --with
```

## Testing in the browser (for Claude)

1. In the worktree, run `branchpress up` (or `branchpress url` if it's already running) and use that URL. Never use another worktree's URL.
2. Open `<url>/wp-admin/?branchpress_login=1` to get logged in as admin (`branchpress` / `branchpress`) with no login form. This also works on any front-end path.
3. Check emails in Mailpit at `http://localhost:8025`.
4. For Playwright/e2e: `WP_BASE_URL=$(branchpress url) npx playwright test`. Each worktree targets its own site, so suites can run in parallel.
5. After changing data heavily, or before a clean test run, use `branchpress reset`.
6. `*.localhost` hostnames work in Chrome, Firefox, curl and Playwright. Safari doesn't resolve them.

## Disk usage

- A site costs one database copy + ~95 MB of core. `wp-content` is shared from the snapshot, never copied per site.
- Sites of deleted worktrees are removed automatically on the next `up`/`ls` (set `BRANCHPRESS_AUTO_PRUNE=0` to turn this off).
- Snapshots are never removed automatically. When the user asks about disk space, run `branchpress du` and suggest `snapshot rm` for unused snapshots, after checking no site uses them.

## Safety rules for Claude

- Before `snapshot rm` or `down --purge`, check `branchpress ls`. Other sessions may be using a site or snapshot. Never pass `--force` without the user's confirmation.
- Never commit snapshot exports, SQL dumps or `wp-content` copies to git.

## Troubleshooting

- **"Database update required" or WooCommerce update notice**: `up` runs both updates after a clone. If the notice remains, run `branchpress wp core update-db` / `branchpress wp wc update`.
- **White screen or fatal error**: `branchpress logs --php`. Caching drop-ins (`object-cache.php`, `advanced-cache.php`, `db.php`) are stripped when a snapshot is copied; with `--link` they aren't, so remove them.
- **Plugin not active**: `branchpress wp plugin list`. If the slug is wrong, set `slug=` in `.branchpress`.
- **Payment gateways and webhooks**: realistic data keeps live API keys. Switch gateways to sandbox once on a site, then re-export the snapshot.
- **Pick a PHP/WP version**: set `BRANCHPRESS_WP_IMAGE`, e.g. `wordpress:6.8-php8.2-apache`, in `~/.branchpress/config`, then `branchpress up`.
- **Port clash on 3407 or 8025**: set `BRANCHPRESS_DB_PORT` / `BRANCHPRESS_MAIL_PORT` in the config, then `docker rm -f branchpress-db branchpress-mail && branchpress setup`. Data is kept in a volume.
- **Slow pages on macOS**: use OrbStack instead of Docker Desktop.
- `snapshot rm NAME` refuses while sites use that snapshot, because they mount its `wp-content`. `--force` also deletes those sites.
