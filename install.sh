#!/usr/bin/env bash
# branchpress installer
#
#   curl -fsSL https://raw.githubusercontent.com/thithiennta/branchpress/main/install.sh | bash
#
# Downloads (or updates) branchpress into ~/.local/share/branchpress and runs `branchpress init`.
# Options after `bash -s --` are passed to init, e.g.:
#   curl -fsSL .../install.sh | bash -s -- --import ~/Downloads/shop.tar.gz
set -euo pipefail

REPO="${BRANCHPRESS_REPO:-https://github.com/thithiennta/branchpress.git}"
DIR="${BRANCHPRESS_SRC:-$HOME/.local/share/branchpress}"

if ! command -v git >/dev/null; then
	echo "git is required. On macOS run: xcode-select --install  (then rerun this installer)" >&2
	exit 1
fi

if [ -d "$DIR/.git" ]; then
	echo "Updating branchpress in $DIR"
	git -C "$DIR" pull -q --ff-only
else
	echo "Downloading branchpress to $DIR"
	mkdir -p "$(dirname "$DIR")"
	git clone -q "$REPO" "$DIR"
fi

# Under `curl | bash` stdin is the script itself; give init the terminal so it can ask questions.
if (exec </dev/tty) 2>/dev/null; then
	exec "$DIR/bin/branchpress" init "$@" </dev/tty
else
	exec "$DIR/bin/branchpress" init "$@"
fi
