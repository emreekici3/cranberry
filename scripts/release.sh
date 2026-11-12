#!/bin/bash
# Publishes a new version: run scripts/release.sh and type the version.
# Run it with all your work committed. It bumps the version, pushes a tag,
# waits for GitHub to build the binaries and updates the Homebrew formula.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"

current="$(perl -ne 'if (/^version = "(.*)"/) { print $1; exit }' "$repo/Cargo.toml")"
echo "Current version: $current"
read -r -p "New version: " version
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: write a version like 0.2.2" >&2
  exit 1
fi
if [[ "$version" == "$current" ]]; then
  echo "error: $version is the current version" >&2
  exit 1
fi

tap="$(dirname "$repo")/homebrew-formulae"
formula="$tap/Formula/cranberry.rb"
tag="v$version"
url="https://github.com/emreekici3/cranberry/releases/download/$tag"

fail() { echo "error: $1" >&2; exit 1; }

cd "$repo"
[[ -f "$formula" ]] || fail "$formula not found"
[[ "$(git branch --show-current)" == master ]] || fail "switch to master first"
[[ -z "$(git status --porcelain)" ]] || fail "commit your changes first"
[[ -z "$(git -C "$tap" status --porcelain)" ]] || fail "homebrew-formulae has uncommitted changes"
git fetch -q origin --tags
[[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/master)" || \
   "$(git merge-base HEAD origin/master)" == "$(git rev-parse origin/master)" ]] \
  || fail "pull first: origin/master has commits you do not have"
! git rev-parse -q --verify "refs/tags/$tag" >/dev/null || fail "$tag already exists"

echo "==> Testing"
cargo test --quiet

echo "==> Releasing $version"
perl -pi -e 'if (!$done && /^version = /) { s/"[^"]*"/"'"$version"'"/; $done = 1 }' Cargo.toml
cargo build --quiet
git add Cargo.toml Cargo.lock
git commit -q -m "Release $version"
git tag "$tag"
git push -q origin master
git push -q origin "$tag"

echo "==> Waiting for GitHub to build the binaries"
arm="cranberry-aarch64-apple-darwin.tar.gz"
intel="cranberry-x86_64-apple-darwin.tar.gz"
ready=0
for _ in $(seq 1 60); do
  if curl -fsIL -o /dev/null "$url/$arm" && curl -fsIL -o /dev/null "$url/$intel"; then
    ready=1
    break
  fi
  sleep 10
done
[[ "$ready" == 1 ]] || fail "no release after 10 minutes; see the Actions page on GitHub"

echo "==> Updating the formula"
arm_sha="$(curl -fsSL "$url/$arm" | shasum -a 256 | cut -d' ' -f1)"
intel_sha="$(curl -fsSL "$url/$intel" | shasum -a 256 | cut -d' ' -f1)"
export version arm_sha intel_sha
perl -0pi -e '
  s/version "[^"]*"/version "$ENV{version}"/;
  s{download/v[^/]+/}{download/v$ENV{version}/}g;
  s/(aarch64-apple-darwin\.tar\.gz"\s+sha256 ")[0-9a-f]+/$1$ENV{arm_sha}/;
  s/(x86_64-apple-darwin\.tar\.gz"\s+sha256 ")[0-9a-f]+/$1$ENV{intel_sha}/;
' "$formula"
git -C "$tap" add Formula/cranberry.rb
git -C "$tap" commit -q -m "cranberry $version"
git -C "$tap" push -q origin main

echo "==> Done: brew upgrade cranberry gets $version"
