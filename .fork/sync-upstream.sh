#!/usr/bin/env bash
# Sync this fork's `main` with upstream `main`, then merge into `rp5-deploy`.
#
# Fork-only tooling. Lives under `.fork/` so it never conflicts with anything
# upstream ships and is trivially droppable if the fork retires.
#
# Workflow this implements:
#   1. Fetch upstream/main.
#   2. Fast-forward local main → upstream/main (no rewrites, no divergence).
#   3. Push origin/main so the fork on GitHub matches upstream on GitHub.
#   4. Merge fresh main into rp5-deploy. Conflicts in files this fork touches
#      (output_shaper.py, handlers/openai.py, tests/test_output_shaper.py,
#      README.md) are reported but not resolved — human intervention needed.
#   5. Push rp5-deploy so Ansible can pin against the new SHA.
#
# Usage: ./.fork/sync-upstream.sh
#
# Safe to run repeatedly. Exits non-zero on any fetch / merge / push failure.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo "==> Fetching upstream"
git fetch upstream

echo "==> Fast-forwarding main"
git checkout main
git merge --ff-only upstream/main

echo "==> Pushing main to origin"
git push origin main

echo "==> Merging main into rp5-deploy"
git checkout rp5-deploy
if ! git merge --no-edit main; then
	echo ""
	echo "!! Merge conflicts in rp5-deploy. Files this fork touches:"
	echo "   - headroom/proxy/output_shaper.py"
	echo "   - headroom/proxy/handlers/openai.py"
	echo "   - tests/test_output_shaper.py"
	echo "   - README.md"
	echo ""
	echo "Resolve conflicts, run 'pytest tests/test_output_shaper.py' to"
	echo "verify the shaper still works, then 'git commit' + rerun this script"
	echo "starting from the 'Pushing rp5-deploy' step below."
	exit 1
fi

echo "==> Pushing rp5-deploy to origin"
git push origin rp5-deploy

NEW_SHA=$(git rev-parse HEAD)
echo ""
echo "Sync complete. rp5-deploy HEAD is now: $NEW_SHA"
echo "Update roles/headroom/defaults/main.yml on the rp5 repo to pin this SHA."
