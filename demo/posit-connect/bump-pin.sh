#!/usr/bin/env bash
# Re-pin the Connect Cloud manifest to a commit of gladkia/igvShiny.
#
# Connect installs igvShiny from the SHA recorded in manifest.json, and app.R
# runs the demo out of that installed package - so this pin, not the branch,
# decides what the public demo shows. Merging a demo change to master does
# nothing until the pin moves.
#
#   ./demo/posit-connect/bump-pin.sh            # pin to origin/master
#   ./demo/posit-connect/bump-pin.sh <sha>      # pin to a specific commit
#   ./demo/posit-connect/bump-pin.sh --check    # report drift, change nothing
#
# Six fields have to stay in step (two SHAs, the version, two file checksums),
# which is why this is a script and not a paragraph in the README.

set -euo pipefail

repo="gladkia/igvShiny"
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
manifest="$dir/manifest.json"

command -v jq >/dev/null || { echo "need jq" >&2; exit 2; }
command -v gh >/dev/null || { echo "need gh" >&2; exit 2; }

md5of() {  # macOS has md5, GNU has md5sum
  if command -v md5sum >/dev/null; then md5sum "$1" | cut -d' ' -f1
  else md5 -q "$1"; fi
}

check_only=false
sha=""
case "${1:-}" in
  --check) check_only=true ;;
  "")      ;;
  *)       sha="$1" ;;
esac

# the full 40-char sha, always: the GitHub API silently returns nothing for
# an abbreviated one, which reads exactly like "this commit does not exist"
[[ -n "$sha" ]] || sha="$(gh api "repos/$repo/commits/master" --jq .sha)"
[[ ${#sha} -eq 40 ]] || { echo "not a full 40-char sha: $sha" >&2; exit 2; }

gh api "repos/$repo/commits/$sha" --jq .sha >/dev/null \
  || { echo "commit $sha not found in $repo" >&2; exit 2; }

# the package version as recorded at that commit, not the working tree's
version="$(gh api "repos/$repo/contents/DESCRIPTION?ref=$sha" --jq '.content' \
           | base64 -d | awk '/^Version:/ {print $2}')"

old_sha="$(jq -r '.packages.igvShiny.description.RemoteSha' "$manifest")"
old_ver="$(jq -r '.packages.igvShiny.description.Version' "$manifest")"

echo "pinned:  $old_ver  ${old_sha:0:7}"
echo "target:  $version  ${sha:0:7}"

# Drift is not "the pin differs from HEAD" - that is true right after every
# merge, including the merge that moves the pin, and a check that cries wolf
# once a week is a check nobody reads. What matters is whether the pinned
# commit would install a different app: only R/, inst/ and DESCRIPTION reach
# the served package.
stale_files=""
if [[ "$old_sha" != "$sha" ]]; then
  stale_files="$(gh api "repos/$repo/compare/$old_sha...$sha" \
                   --jq '.files[].filename' 2>/dev/null \
                 | grep -E '^(R/|inst/|DESCRIPTION$)' || true)"
fi

if [[ -z "$stale_files" ]]; then
  echo "the pinned commit installs the same app as master"
  $check_only && exit 0
else
  echo "the pinned commit predates these changes to the served app:"
  echo "$stale_files" | sed 's/^/  /' | head -20
  $check_only && { echo "DRIFT: the live demo runs ${old_sha:0:7}, not ${sha:0:7}"; exit 1; }
fi

app_md5="$(md5of "$dir/app.R")"
readme_md5="$(md5of "$dir/README.md")"

tmp="$(mktemp)"
jq --arg sha "$sha" --arg version "$version" \
   --arg app "$app_md5" --arg readme "$readme_md5" '
  .packages.igvShiny.description.RemoteSha  = $sha
  | .packages.igvShiny.description.GithubSHA1 = $sha
  | .packages.igvShiny.description.Version    = $version
  | .files["app.R"].checksum                  = $app
  | .files["README.md"].checksum              = $readme
' "$manifest" > "$tmp"

jq -e . "$tmp" >/dev/null || { echo "produced invalid json, manifest untouched" >&2; exit 1; }
mv "$tmp" "$manifest"

echo "manifest re-pinned; commit it, push to master, then republish in Connect Cloud."
echo "the app's sidebar footer should read: igvShiny $version"
