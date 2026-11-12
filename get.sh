#!/bin/sh
# Install or update this fork of frameeyeosc on a Steam Frame: frameeyeosc, the eye-camera tool (eyecam) and the
# SteamVR dashboard panel, from the fork's latest GitHub release. In Konsole on the Frame:
#   curl -fsSL https://raw.githubusercontent.com/NoahSunde/frameeyeosc/main/get.sh | sh
# It downloads the release's SHA256SUMS and tarball, checks the tarball against it, and runs the tarball's own
# install.sh --with-panel (no sudo; settings and calibration are kept). Upstream's installer (its option 1)
# installs over it again. FRAMEEYEOSC_GET_KEEP=1 keeps the download in ~/.cache/frameeyeosc-get (its install.sh
# --uninstall removes everything).
set -eu

repo=NoahSunde/frameeyeosc
base="https://github.com/$repo/releases/latest/download"

fail() {
    echo "get.sh: $*" >&2
    exit 1
}

[ "$(uname -m)" = aarch64 ] || fail "this is for the Steam Frame (aarch64), but this machine is $(uname -m)"
for tool in curl tar sha256sum awk; do
    command -v "$tool" >/dev/null 2>&1 || fail "$tool is needed"
done

work="${XDG_CACHE_HOME:-$HOME/.cache}/frameeyeosc-get"
rm -rf "$work"
mkdir -p "$work"
if [ "${FRAMEEYEOSC_GET_KEEP:-}" != 1 ]; then
    trap 'rm -rf "$work"' EXIT
fi

get() { # url file
    curl --fail --silent --show-error --location --proto =https --proto-redir =https --connect-timeout 15 \
        --max-time 600 -o "$2" "$1" || fail "could not download $1"
}

echo "Looking for the latest release of $repo..."
get "$base/SHA256SUMS" "$work/SHA256SUMS"
# The tarball's name (it carries the version) and its checksum, from SHA256SUMS
name=$(awk '{ n = $2; sub(/^\*/, "", n) } n ~ /^frameeyeosc-[0-9A-Za-z.+-]+-steamframe-aarch64\.tar\.gz$/ { print n; exit }' \
    "$work/SHA256SUMS")
[ -n "$name" ] || fail "the release's SHA256SUMS lists no frameeyeosc tarball"
expected=$(awk -v n="$name" '$2 == n || $2 == "*" n { print tolower($1); exit }' "$work/SHA256SUMS")
case $expected in
    '' | *[!0-9a-f]*) fail "SHA256SUMS has no usable entry for $name" ;;
esac

echo "Downloading $name..."
get "$base/$name" "$work/$name"
actual=$(sha256sum "$work/$name" | cut -c1-64)
[ "$actual" = "$expected" ] || fail "$name has SHA-256 $actual, but SHA256SUMS says $expected"
echo "SHA-256 ok."

mkdir "$work/files"
tar -xzf "$work/$name" -C "$work/files" || fail "could not extract $name"
installer="$work/files/frameeyeosc/install.sh"
[ -f "$installer" ] || fail "$name has no frameeyeosc/install.sh"
chmod u+x "$installer"
echo "Installing (frameeyeosc, the eye-camera tool and the panel)..."
"$installer" --with-panel </dev/null
