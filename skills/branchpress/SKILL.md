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

Walk the developer through these steps in order. Run the commands yourself and ask only for what you can't find out.

1. **Docker**: run `docker info`. If it's missing, recommend OrbStack (`brew install orbstack`; its file mounts are much faster on macOS) or Docker Desktop, then wait for the developer to start it. Git must be 2.31 or newer.
2. **Install the CLI**:
   ```bash
   git clone https://github.com/thithiennta/branchpress.git ~/.local/share/branchpress
   ~/.local/share/branchpress/bin/branchpress setup
   ```
   Setup downloads WP-CLI, pulls images, starts MySQL and Mailpit, and links `branchpress` and `bpress` into `~/.local/bin`. If it warns that PATH is missing, apply the suggested `~/.zshrc` line. To update later: `git -C ~/.local/share/branchpress pull`.
3. **Plugins folder**: ask where their plugin repos live and set `BRANCHPRESS_PLUGINS_DIR="$HOME/..."` in `~/.branchpress/config`. `--with <slug>` needs it.
4. **Data snapshot**: choose one of these sources:
   - **From a teammate (preferred)**: `branchpress snapshot import shop.tar.gz shop`
   - **From production or staging**: they provide a SQL dump (`wp db export`, phpMyAdmin, a host backup; `.sql` or `.sql.gz`) and a copy of `wp-content`:
     `branchpress snapshot add shop --sql ~/Downloads/shop.sql.gz --wp-content ~/Downloads/wp-content --url https://shop.example.com --sanitize`
   - **From a Local (localwp.com) site**: in Local, open the site, go to *Open site shell*, and run `wp db export ~/Desktop/site.sql`. Then use
     `--sql ~/Desktop/site.sql --wp-content "<Local sites folder>/<site>/app/public/wp-content" --url http://<site>.local`
   - **No data needed**: `branchpress snapshot add blank --empty`

   Recommend `--sanitize` for production data. It replaces customer emails with `@example.test` addresses. The table prefix is detected automatically; if detection fails, pass `--prefix`. Multisite isn't supported.
5. **Default snapshot**: set `BRANCHPRESS_DEFAULT_SNAPSHOT="shop"` in `~/.branchpress/config`.
6. **Per-repo wiring**, optional but recommended:
   - commit a `.branchpress` file in each plugin repo (format below)
   - append [references/claude-md-snippet.md](references/claude-md-snippet.md) to the repo's `CLAUDE.md`
7. **Smoke test**: in a plugin repo, run `branchpress up --open` and confirm wp-admin opens already logged in.

To share data with the next developer, run `branchpress snapshot export shop ~/shop.tar.gz`. The file contains real site data, so share it privately (not in git).

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
| Clean up after deleting worktrees | `branchpress prune` |
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
