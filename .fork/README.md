# `.fork/` — fork-only tooling

Everything in this directory exists **only in `dylanrussellmd/headroom`**, never in `headroomlabs-ai/headroom`. It's namespaced under `.fork/` so:

- Upstream diffs stay clean (nothing in `.fork/` competes with anything upstream ships).
- If the fork retires (i.e., the PR merges upstream and there's no more reason to keep the fork), the directory can be deleted in one commit.
- Anyone browsing the repo can tell at a glance which files are fork-specific.

## Contents

- `sync-upstream.sh` — fetch `upstream/main`, fast-forward `main`, merge into `rp5-deploy`, push. Run on any cadence (weekly, on-demand). Exits non-zero if there are merge conflicts in the four files this fork touches (`output_shaper.py`, `handlers/openai.py`, `tests/test_output_shaper.py`, `README.md`) so a human can resolve them.

## Branch layout

- **`main`** — mirror of `upstream/main`. Never commit here directly. `sync-upstream.sh` keeps it fast-forwarded.
- **`feat/output-shaper-openai`** — the PR branch against upstream. See [#1725](https://github.com/headroomlabs-ai/headroom/pull/1725).
- **`rp5-deploy`** — long-lived deployment branch. Starts from `main`, merges in `feat/output-shaper-openai`. This is what the rp5 Ansible role installs from (`git+https://github.com/dylanrussellmd/headroom.git@<sha>`).

## When the upstream PR merges

Once `feat/output-shaper-openai` lands in upstream `main`, the next `.fork/sync-upstream.sh` run will bring those exact commits into this fork's `main`. At that point:

1. Drop the `rp5-deploy` branch (`git push origin --delete rp5-deploy`).
2. Switch the rp5 Ansible role back to installing `headroom-ai==<next-release>` from PyPI once upstream ships a release containing the merged commits.
3. Optionally, archive or delete the fork entirely.
