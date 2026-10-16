## Local test site (branchpress)

Each worktree of this plugin has its own WordPress test site with realistic data (see the `branchpress` skill).

- Start or resume it: `branchpress up`. Print its URL: `branchpress url`. Only test against this worktree's own URL.
- Logged-in admin: `<url>/wp-admin/?branchpress_login=1`. Outgoing mail: http://localhost:8025
- WP-CLI: `branchpress wp ...`. PHP errors: `branchpress logs --php`. Clean data: `branchpress reset`
- If the feature also changes another plugin, use the same branch name there and run `branchpress up --with <other-plugin-slug>`.
