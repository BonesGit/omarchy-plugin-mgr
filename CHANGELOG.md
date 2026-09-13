# Changelog

## 1.2.0

- **New:** Install from a git URL in the panel (`+`). Secure Install scans then waits for Approve; Insecure Install adds immediately. New installs never auto-trust.
- **Change:** First Party tab is now labeled Omarchy.
- **Change:** Default security scan mode is Confirm (`trustScan` false). Trust still available when enabled.
- **Fix:** Enable/disable row toggle now calls `omarchy plugin enable|disable`. Omarchy's `ToggleSwitch` only emits `toggled()` and does not flip `checked`, so the old handler always no-op'd.
- **Fix:** Enable/disable/remove no longer prepend Omarchy's human "Enabled/Disabled …" lines onto stdout, so the panel can parse the refreshed plugin list instead of showing "action failed".
- **Fix:** Bar pill spinner while checking remotes, scanning, installing, or updating. Yellow warning triangle while Approve/Reject is waiting.

## 1.0.0

- **New:** Security scan on panel Update — Off / Confirm / Trust. Confirm waits for a thumbs-up after `CLEAR`; Trust installs immediately. Defaults follow `securityScan` / `trustScan` and whether a default agent is set. Panel clicks are session-only.
- **New:** Incoming commits are reviewed by `omarchy agent prompt` (malware, exploits, data leakage), not a sandbox.
- **Fix:** Cancel an in-flight scan with a red X on the update icon.
- **Fix:** After a confirmed `CLEAR`, right-click thumbs-down (then right-click again) aborts the update.
- **Fix:** Shell restart after update is queued with `systemd-run` before a self-update pull, so hot-reload cannot kill it.
- **Fix:** Subscript update count on the bar pill.
- **Fix:** Per-chip tooltips on Off / Confirm / Trust.
- **Fix:** Panel failed to open (`on_confirmChanged` is invalid QML).

## 0.9.2

- **Chore:** Version bump.

## 0.9.1

- **Chore:** Version bump.

## 0.9.0

- List first- and third-party plugins, enable/disable, git check, update, remove, repo button.
