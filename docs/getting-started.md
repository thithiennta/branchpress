# Getting started with branchpress

This guide takes a new developer from a blank Mac to testing several plugin features side by side. Plan for about 15 minutes, mostly Docker downloads.

Examples use a plugin called `my-plugin`, a second plugin `companion-plugin`, and a snapshot called `shop`. Replace them with your own names.

---

## Part 1: Team lead (once per new developer)

New developers need the same test data as everyone else. Export your snapshot and send the file **privately** (Google Drive, Slack DM, …), never through git:

```bash
branchpress snapshot export shop ~/shop.tar.gz
```

> If the snapshot came from production, create it with `--sanitize` so customer emails are replaced before you share it. See [Creating a snapshot](#creating-a-snapshot-from-scratch).

Also send them the clone URLs of the plugin repos they'll work on.

---

## Part 2: New developer

### 1. Install the prerequisites

macOS with [Homebrew](https://brew.sh):

```bash
brew install git
brew install --cask orbstack   # or Docker Desktop; OrbStack is faster on macOS
open -a OrbStack               # start it once and finish its setup
```

Check that both work:

```bash
docker info        # must print server info, not an error
git --version      # 2.31 or newer
```

On Linux, install Docker Engine and git with your package manager.

### 2. Install branchpress

```bash
git clone https://github.com/thithiennta/branchpress.git ~/.local/share/branchpress
~/.local/share/branchpress/bin/branchpress setup
```

`setup` downloads WP-CLI, pulls the Docker images, starts a shared MySQL and Mailpit, and links `branchpress` and `bpress` into `~/.local/bin`.

If it warns that `~/.local/bin` isn't on your PATH:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && exec zsh
```

Check: `branchpress --version`

### 3. Clone the plugin repos

Put all plugin repos in one folder. It doesn't need to be inside a WordPress install:

```bash
mkdir -p ~/plugins && cd ~/plugins
git clone <my-plugin repo url>
git clone <companion-plugin repo url>
```

### 4. Configure

Edit `~/.branchpress/config`:

```bash
BRANCHPRESS_PLUGINS_DIR="$HOME/plugins"
BRANCHPRESS_DEFAULT_SNAPSHOT="shop"
```

### 5. Import the team's data

```bash
branchpress snapshot import ~/Downloads/shop.tar.gz shop
branchpress snapshot ls
```

### 6. Install the Claude Code plugin (optional, recommended)

If you use [Claude Code](https://claude.com/claude-code), run this inside it:

```
/plugin marketplace add thithiennta/branchpress
/plugin install branchpress@branchpress
```

Restart Claude Code. You can then ask Claude to *"start my test site"* or *"check this in the browser"*. Claude knows to use the current worktree's own site and login link.

### 7. First run

```bash
cd ~/plugins/my-plugin
branchpress up --open
```

Your browser opens wp-admin, already logged in. You're set up. 🎉

---

## Daily workflow

### One worktree per feature, one site per worktree

```bash
cd ~/plugins/my-plugin
git worktree add ../my-plugin-feat-x -b feat-x
cd ../my-plugin-feat-x
branchpress up --open      # e.g. http://my-plugin-feat-x.localhost:8412
```

Repeat for as many features as you like. Every worktree gets its own site, database and URL, and they all run at the same time. Worktrees created by Claude Code (`.claude/worktrees/…`) work the same way: `cd` into one and run `branchpress up`.

| Task | Command |
|---|---|
| This worktree's URL | `branchpress url` |
| Log into wp-admin instantly | open `<url>/wp-admin/?branchpress_login=1` |
| See emails the site sent | http://localhost:8025 |
| Run WP-CLI | `branchpress wp plugin list` |
| See PHP errors | `branchpress logs --php` |
| Reset to clean data | `branchpress reset` |
| List all sites | `branchpress ls` |
| Check disk use | `branchpress du` |
| Stop everything for the day | `branchpress halt` (`branchpress up` brings a site back) |

### A feature that spans two plugins

Use the **same branch name** in both repos:

```bash
cd ~/plugins/companion-plugin
git worktree add ../companion-plugin-feat-x -b feat-x

cd ~/plugins/my-plugin-feat-x
branchpress up --with companion-plugin   # mounts companion-plugin's feat-x worktree too
```

The `up` output shows which folder and branch each plugin came from. branchpress remembers `--with`, so next time a plain `branchpress up` is enough.

### Finishing a feature

```bash
git worktree remove ../my-plugin-feat-x
```

The site that belonged to it is deleted automatically the next time you run `branchpress up` or `branchpress ls`.

### Updating branchpress

```bash
git -C ~/.local/share/branchpress pull
```

---

## Creating a snapshot from scratch

Only needed if nobody gave you an export.

**From a [Local](https://localwp.com) site:**
1. In Local, open the site, then *Open site shell*.
2. Run `wp db export ~/Desktop/site.sql`.
3. Run:
   ```bash
   branchpress snapshot add shop \
     --sql ~/Desktop/site.sql \
     --wp-content "$HOME/Local Sites/<site>/app/public/wp-content" \
     --url http://<site>.local
   ```

**From production or staging:** get a SQL dump (`wp db export`, phpMyAdmin or a host backup; `.sql` or `.sql.gz`) and a copy of `wp-content`, then:

```bash
branchpress snapshot add shop --sql shop.sql.gz --wp-content ./wp-content \
  --url https://shop.example.com --sanitize
```

**Empty WordPress, no data:** `branchpress snapshot add blank --empty`

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `docker: command not found` or "Docker is not running" | Install or start OrbStack / Docker Desktop |
| `branchpress: command not found` | Add `~/.local/bin` to PATH (step 2) |
| Port 3407 or 8025 already in use | Set `BRANCHPRESS_DB_PORT` / `BRANCHPRESS_MAIL_PORT` in `~/.branchpress/config`, then `docker rm -f branchpress-db branchpress-mail && branchpress setup` |
| Site URL won't open in Safari | Use Chrome or Firefox; Safari doesn't resolve `*.localhost` |
| White screen or error | `branchpress logs --php` |
| Plugin change doesn't show up | Check the `up` output for the folder and branch it mounted |
| "Database update required" | `branchpress wp core update-db` |
| Need a different PHP version | Set `BRANCHPRESS_WP_IMAGE="wordpress:php8.2-apache"` in the config, then `branchpress up` |

More details are in the [README](../README.md).
