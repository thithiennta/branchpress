# branchpress

**One isolated WordPress test site per git worktree, with realistic data, so you can test parallel features side by side.**

If you build WordPress or WooCommerce plugins with git worktrees (by hand, or with Claude Code running several features at once), you hit the same wall: you have many branches but only one local WordPress site to test them in. branchpress gives each worktree its own disposable site:

```
alpha-plugin @ feature-x  ─┐
beta-plugin  @ feature-x  ─┴─►  http://alpha-plugin-feature-x.localhost:8932   (own DB, cloned from your real data)
alpha-plugin @ main       ───►  http://alpha-plugin-main.localhost:8717
```

- 🧪 **Real data, private copies**: import a production, staging or Local dump once as a *snapshot*. Every site gets its own clone of that database, so breaking one site never affects another.
- 🔌 **Live code**: the worktree is mounted straight into `wp-content/plugins`. Save a file, refresh the page.
- 🧩 **Multi-plugin features**: `--with other-plugin` mounts the other plugin's worktree on the same branch.
- 📭 **Safe by default**: all mail is caught by [Mailpit](https://mailpit.axllent.org/), mailer plugins are disabled, and `--sanitize` replaces customer emails.
- 🤖 **Agent-friendly**: stable URL per worktree, `?branchpress_login=1` instant admin login, and a bundled [Claude Code](https://claude.com/claude-code) skill.
- 🤝 **Runs next to Local/Valet**: uses ports 3407, 8025 and 8100–8999 only.

> 👋 **New to branchpress?** Follow the step-by-step [Getting started guide](docs/getting-started.md).

## Requirements

- macOS or Linux
- Docker: [OrbStack](https://orbstack.dev) (recommended on macOS) or Docker Desktop
- git 2.31+, bash, curl, rsync

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/thithiennta/branchpress/main/install.sh | bash
```

This downloads branchpress to `~/.local/share/branchpress` and runs **`branchpress init`**, a guided setup. It checks or installs Docker, starts the shared MySQL and Mailpit, asks where your plugin repos live, and gets your test data. For the data you can import a teammate's snapshot, copy one of your [Local](https://localwp.com) sites, or start empty. It then offers to install the Claude Code skill and starts your first site.

Run the same command again to update. Prefer not to pipe to bash? `git clone` the repo and run `bin/branchpress init`.

### Claude Code plugin

`init` offers to install it for you. To install it by hand, run this inside Claude Code:

```
/plugin marketplace add thithiennta/branchpress
/plugin install branchpress@branchpress
```

The skill teaches Claude to start and test each worktree against its own site.

## Quick start

```bash
cd ~/plugins/my-plugin
git worktree add ../my-plugin-feat-x -b feat-x
cd ../my-plugin-feat-x
branchpress up --open        # its own site, already logged in
```

More test data later:

```bash
branchpress snapshot add shop --from-local my-local-site            # copy a running Local site
branchpress snapshot add shop --sql shop.sql.gz --wp-content ./wp-content --sanitize   # production dump
branchpress snapshot import ~/Downloads/shop.tar.gz                 # a teammate's export
branchpress snapshot refresh shop                                   # copy it again from where it came from
```

## Test data per plugin

Different plugins often need different data, and every developer has their own dev sites. Each developer chooses, **once per plugin**, which snapshot that plugin's sites are cloned from:

```bash
cd ~/plugins/plugin-a
branchpress use                          # show what plugin-a uses and why
branchpress use abc                      # use the snapshot "abc"
branchpress use --from-local abc-dev     # or copy one of your Local sites and use it
branchpress use --import ~/abc.tar.gz    # or load a teammate's export and use it
```

The choice is saved on your machine (`~/.branchpress/plugin-snapshots`), not in git.

**How `up` picks the data**, first match wins:

1. `--snapshot NAME`
2. what this worktree's site already uses
3. your `branchpress use` choice for the plugin
4. `snapshot=` in the repo's `.branchpress`, matched by snapshot name **or by the domain it was copied from**
5. the only snapshot, if you have just one

Otherwise `up` **asks**: in a terminal it shows a menu (your snapshots, plus Local sites you haven't copied yet), then saves your answer. Without a terminal (Claude, scripts) it prints the choices and exits with code 3, so the caller can decide and run `branchpress use`. Set `BRANCHPRESS_ASK=0` to use the default snapshot without asking.

**Team setup.** Plugin A is developed against `abc.dev` and plugin B against `xyz.dev`? Commit the domain to each repo:

```
# plugin-a/.branchpress          # plugin-b/.branchpress
snapshot=abc.dev                 snapshot=xyz.dev
```

A teammate who copied their Local site `abc.dev` gets it picked automatically. Anyone else is asked once, with that Local site suggested if they have it.

`up` always prints where the data came from:

```
==> Site plugin-a-feat-x — data: abc (Local site abc.dev, copied 2026-10-18) [your choice for plugin-a]
```

**Refresh.** A snapshot is a frozen copy. After you change your dev site, run `branchpress snapshot refresh abc`: it copies the data again from the same Local site or export file. Running sites see new files (themes, plugins, uploads) right away and get the new database on `branchpress reset`.

## Commands

| Command | What it does |
|---|---|
| `branchpress init` | Guided setup; every question also has a flag (`branchpress help`) |
| `branchpress up [--snapshot S] [--with SPEC]... [--fresh] [--open]` | Start or resume this worktree's site |
| `branchpress reset` | Re-clone the database from the snapshot |
| `branchpress down [--purge]` | Stop the site (`--purge` also deletes its database) |
| `branchpress url` / `open` | Print the URL / open wp-admin logged in |
| `branchpress wp <args>` | WP-CLI against this site |
| `branchpress sql` | MySQL shell on this site's database |
| `branchpress logs [--php]` | Apache log, or PHP `debug.log` |
| `branchpress ls` | All sites and their status |
| `branchpress prune` | Delete sites whose worktree no longer exists (also runs automatically) |
| `branchpress du` | Disk used by snapshots, sites and shared containers |
| `branchpress halt` | Stop all containers (keeps data) |
| `branchpress use [NAME \| --from-local SITE \| --import FILE]` | Choose which snapshot this plugin uses (see [Test data per plugin](#test-data-per-plugin)) |
| `branchpress snapshot add\|ls\|refresh\|rm\|export\|import` | Manage snapshots (`branchpress snapshot help`) |

### Multi-plugin features

Use the same branch name in every plugin involved, then:

```bash
branchpress up --with beta-plugin           # beta-plugin's worktree on the same branch, else its main checkout
branchpress up --with beta-plugin@some-br   # a specific branch's worktree
branchpress up --with ../path/to/plugin     # any folder
```

Set `BRANCHPRESS_PLUGINS_DIR` in `~/.branchpress/config` to the folder that holds your plugin repos.

### Per-repo config: `.branchpress`

Commit this file to a plugin repo to set defaults for everyone:

```
slug=my-plugin        # plugin folder name, if different from the repo folder name
snapshot=abc.dev      # the team's dev site: a snapshot name, or the domain it was copied from
with=companion-addon  # companion plugin, one line each
```

Snapshot names differ between developers, so prefer a domain for `snapshot=`. If nobody matches it on a machine, `up` asks instead of failing.

### Sharing data with a teammate

```bash
branchpress snapshot export shop ~/shop.tar.gz      # you
branchpress snapshot import ~/shop.tar.gz shop      # them
```

> ⚠️ Exports contain real site data. Share them privately and never commit them.

## How it works

- One shared **MySQL 8.4** container (`branchpress-db`) and one **Mailpit** container (`branchpress-mail`).
- Each snapshot is a database (`snap_<name>`) plus a copy of `wp-content` in `~/.branchpress/snapshots/<name>`. Its `meta` file records where it was copied from, so `snapshot refresh` can copy it again.
- Each site is an official `wordpress` container with:
  - a database cloned from the snapshot, with URLs rewritten (including serialized and JSON-escaped values)
  - the snapshot's `wp-content` mounted, with your worktree(s) on top
  - an mu-plugin that routes mail to Mailpit and adds the login link
- Sites are named `<plugin-slug>-<branch>` and reachable at `http://<name>.localhost:<port>`. The port is derived from the name, so it stays stable. `*.localhost` works in Chrome, Firefox, curl and Playwright, but not Safari.

## Configuration (`~/.branchpress/config`)

| Variable | Default | |
|---|---|---|
| `BRANCHPRESS_PLUGINS_DIR` | – | Folder of plugin repos, for `--with slug` |
| `BRANCHPRESS_DEFAULT_SNAPSHOT` | – | Suggested snapshot when a plugin has no choice yet |
| `BRANCHPRESS_ASK` | `1` | With several snapshots, ask which one a plugin uses (`0`: use the default silently) |
| `BRANCHPRESS_WP_IMAGE` | `wordpress:php8.3-apache` | Pick PHP/WP version |
| `BRANCHPRESS_DB_PORT` | `3407` | Host port of the shared MySQL |
| `BRANCHPRESS_MAIL_PORT` | `8025` | Host port of the Mailpit UI |
| `BRANCHPRESS_INSTANCE` | `branchpress` | Name prefix for containers; a second instance gets its own `~/.branchpress-<name>` |
| `BRANCHPRESS_AUTO_PRUNE` | `1` | Remove sites of deleted worktrees on every `up`/`ls` (`0` to disable) |

## Disk usage and cleanup

| What | Typical size | Cleaned up |
|---|---|---|
| Snapshot | Database + one copy of `wp-content` (uploads can be GBs) | Only by `branchpress snapshot rm NAME`, because many sites share it |
| Site | One database copy (same size as the snapshot's) + ~95 MB WordPress core | **Automatically** once its worktree is deleted (on the next `up` or `ls`), or `branchpress down --purge` |
| Docker images | ~2.3 GB once (WordPress, MySQL, Mailpit) | Shared by everything |

- Sites never copy `wp-content`. They mount the snapshot's copy, so ten sites cost ten database copies, not ten copies of your uploads.
- `branchpress prune` also removes leftover databases and volumes that no site owns.
- Run `branchpress du` to see where the space goes.
- MySQL runs without the binary log, so cloning and resetting sites leaves no hidden copies behind.
- Deleted databases free space inside Docker's virtual disk. OrbStack returns that space to macOS automatically; Docker Desktop may need *Troubleshoot → Clean / Purge data* to shrink its disk file.

## Limitations

- Multisite isn't supported.
- Sites from the same snapshot share its `wp-content` (themes, third-party plugins, uploads). Installing or updating a third-party plugin in one site affects the others.
- Realistic data keeps live payment-gateway keys. Switch gateways to sandbox mode, then re-export your snapshot.

## License

[MIT](LICENSE)
