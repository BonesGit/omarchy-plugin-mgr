# Changelog

## Unreleased

- **New:** Security scan on panel Update — Off / Confirm / Trust. Confirm waits for a thumbs-up after `CLEAR`; Trust installs immediately. Defaults follow `securityScan` / `trustScan` and whether a default agent is set. Panel clicks are session-only.
- **New:** Incoming commits are reviewed by `omarchy agent prompt` (malware, exploits, data leakage), not a sandbox.
- **Fix:** Cancel an in-flight scan with a red X on the update icon.
- **Fix:** Shell restart after update is queued with `systemd-run` before a self-update pull, so hot-reload cannot kill it.
- **Fix:** Subscript update count on the bar pill.
- **Fix:** Per-chip tooltips on Off / Confirm / Trust.

## 0.9.1

- **Chore:** Version bump.

## 0.9.0

- List first- and third-party plugins, enable/disable, git check, update, remove, repo button.
