# Getting started with branchpress

From a blank Mac to testing several plugin features side by side, in two steps.

## For a new developer

### 1. Run the installer

```bash
curl -fsSL https://raw.githubusercontent.com/thithiennta/branchpress/main/install.sh | bash
```

The installer downloads branchpress and starts `branchpress init`, a short guided setup:

| Step | What happens |
|---|---|
| 1. Docker | Checks Docker. If it's missing, offers to install [OrbStack](https://orbstack.dev) with Homebrew, then starts it |
| 2. Install | Downloads WP-CLI and the Docker images, starts a shared MySQL and Mailpit, puts `branchpress` on your PATH |
| 3. Plugin repos | Asks which folder holds your plugin repos |
| 4. Test data | Pick one: a snapshot file from a teammate, a copy of one of your [Local](https://localwp.com) sites, or an empty WordPress |
| 5. Claude Code | Offers to install the branchpress skill, if you use [Claude Code](https://claude.com/claude-code) |

If you run it inside a plugin repo, it offers to start that plugin's site at the end.

> No git yet? On macOS run `xcode-select --install` first.
> If `branchpress` isn't found afterwards, open a new terminal, or run `echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc`.

### 2. Start a site for your worktree

```bash
cd ~/plugins/my-plugin
git worktree add ../my-plugin-feat-x -b feat-x
cd ../my-plugin-feat-x
branchpress up --open
```

wp-admin opens, already logged in. Every worktree gets its own site and URL, and they all run at the same time. Worktrees created by Claude Code (`.claude/worktrees/…`) work the same way.

If you have more than one snapshot, the first `up` in a plugin asks which data it should use, then remembers your answer for that plugin. Change it later with `branchpress use NAME`.

That's it. 🎉

---

## For the team lead: sharing test data

Give new developers the team's data so everyone tests against the same shop:

```bash
branchpress snapshot export shop ~/shop.tar.gz
```

Send the file privately (Google Drive, Slack DM, …), never through git. They choose *"A snapshot file from a teammate"* in step 4, or skip the questions with:

```bash
curl -fsSL https://raw.githubusercontent.com/thithiennta/branchpress/main/install.sh | bash -s -- --import ~/Downloads/shop.tar.gz
```

> If the data came from production, create the snapshot with `--sanitize` so customer emails are replaced before sharing.

### Different plugins, different dev sites

Say plugin A is developed against `abc.dev` and plugin B against `xyz.dev`. Commit a `.branchpress` file to each repo that names the site's domain:

```
snapshot=abc.dev
```

On each developer's machine, branchpress picks the snapshot copied from that domain. If there isn't one, it asks once, suggesting the matching Local site if they have it, and remembers the answer. Developers can always override it with `branchpress use`.

---

## Daily commands

| Task | Command |
|---|---|
| Start or resume this worktree's site | `branchpress up` (add `--open` to open wp-admin) |
| This worktree's URL | `branchpress url` |
| Log into wp-admin instantly | open `<url>/wp-admin/?branchpress_login=1` |
| See emails the site sent | http://localhost:8025 |
| Run WP-CLI | `branchpress wp plugin list` |
| See PHP errors | `branchpress logs --php` |
| Reset to clean data | `branchpress reset` |
| Which data this plugin uses, and why | `branchpress use` |
| Use other data for this plugin | `branchpress use NAME` · `branchpress use --from-local SITE` |
| Pull new data from your dev site | `branchpress snapshot refresh NAME`, then `branchpress reset` |
| List all sites | `branchpress ls` |
| Check disk use | `branchpress du` |
| Stop everything for the day | `branchpress halt` |

**A feature that spans two plugins:** use the **same branch name** in both repos, then run `branchpress up --with companion-plugin`.

**When a feature is done:** `git worktree remove ../my-plugin-feat-x`. Its site is deleted automatically the next time you run `branchpress up` or `branchpress ls`.

**Update branchpress:** run the installer again, or `git -C ~/.local/share/branchpress pull`.

---

## Setup without questions (CI, scripts, Claude)

Every `init` question has a flag:

```bash
branchpress init --plugins-dir ~/plugins --import ~/shop.tar.gz --no-claude --yes
branchpress init --plugins-dir ~/plugins --from-local my-local-site --yes
branchpress init --plugins-dir ~/plugins --empty --no-start --yes
```

Running `init` again is safe. It keeps everything that already exists and only changes what you ask for.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `up` asks "Which test data should … use?" | Pick one. It's saved per plugin; change it with `branchpress use NAME` |
| Test data is out of date | `branchpress snapshot refresh NAME`, then `branchpress reset` in the worktree |
| "Docker is not running" | Start OrbStack / Docker Desktop, then run `branchpress init` again |
| "Local site 'x' is not running" | Start the site in Local, then retry |
| Port 3407 or 8025 already in use | Set `BRANCHPRESS_DB_PORT` / `BRANCHPRESS_MAIL_PORT` in `~/.branchpress/config`, then `docker rm -f branchpress-db branchpress-mail && branchpress setup` |
| Site URL won't open in Safari | Use Chrome or Firefox; Safari doesn't resolve `*.localhost` |
| White screen or error | `branchpress logs --php` |
| Plugin change doesn't show up | Check the `up` output for the folder and branch it mounted |
| Need a different PHP version | Set `BRANCHPRESS_WP_IMAGE="wordpress:php8.2-apache"` in the config, then `branchpress up` |

More details are in the [README](../README.md).
