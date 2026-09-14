[![Built for Omarchy: Plugin](https://raw.githubusercontent.com/tcballard/omarchy-badges/75975e5b5bf75e7ede3764bcd2950046f7abfe2c/badges/v1/omarchy-plugin.svg)](https://github.com/tcballard/omarchy-badges)

# The Ultimate Plugin Manager

Omarchy bar widget that lists plugins in **Third Party** and **Omarchy**
tabs. Actions to check for updates, install and update from a git URL, enable/disable, visit
git repo, and remove plugins. With support for an AI prompt to scan for security, malware and data leakage concerns.

> [!IMPORTANT]
> **Security scan feature** Use your default AI agent to perform security scans on plugin updates. 
> Scans will look for malware, exploits, and data leakage. The plugin
> updates only if that scan reports clear. Toggle **Security scan** at the
> bottom of the panel. Set **Off**, **Confirm**, or **Trust**
> at the bottom of the panel. Confirm and Trust need `omarchy default agent` to enable it.

Plugin id: `io.github.bonesgit.omarchy-ultimate-plugin-mgr`

![Plugin Manager](preview.png)

## What it shows

**Third Party** is anything under `~/.config/omarchy/plugins/` that is not
`omarchy.*`. **Omarchy** is the stock `omarchy.*` set.

Each row:

- name, id, version
- enabled / disabled
- git vs local-only (third-party)
- commits ahead of origin after a check (third-party)

Filter box next to the tabs matches name or id on both tabs.

Omarchy rows can be enabled or disabled. They cannot be removed or git-updated.

## Actions

- **Install** — `+` opens a git URL field. **Secure Install** clones and scans
  with the default agent; on `CLEAR`, click **Approve** to add (new installs
  never auto-trust). **Insecure Install** runs `omarchy plugin add <url> --yes
  --enable` with no scan. Click `+` again to close the strip. Failures stay
  on the strip and show at the bottom of the panel.
- **Enable / disable** — `omarchy plugin enable|disable`
- **Check** — `git fetch origin HEAD` then `rev-list HEAD..FETCH_HEAD` (same
  comparison `omarchy plugin update` uses)
- **Update** — `omarchy plugin update <id> --yes`. The agent scan runs only
  from this panel, not from the CLI.
- **Remove** — right-click a row to arm it (urgent border, 4s), then left-click **Remove**
- **Repo** — `xdg-open` the origin URL (or `repository` / `homepage` in the
  manifest)

Periodic checks default to every 24 hours (bar setting `checkHours`), counted
from the last check stored in `~/.local/state/omarchy/plugin-mgr/last-check.json`.
Shell start and plugin load do not fetch remotes. Right-click the pill, **Check**
in the panel, or `r` in the panel, runs a check now.

## Security scan

Three modes on the panel footer (this session only — they do not write
settings). Widget settings `securityScan` and `trustScan` choose the default
the next time the shell loads:

| Mode | What Update does |
| --- | --- |
| **Off** | Update immediately, no agent. |
| **Confirm** | Agent reviews incoming `FETCH_HEAD`. On `CLEAR`, click the thumbs-up to install. |
| **Trust** | Same review; `CLEAR` installs with no extra click. |

Defaults: no default agent → **Off**. Agent set and `trustScan` off (the
schema default) → **Confirm**. Agent set and `trustScan` on → **Trust**.
`securityScan` off in settings also starts **Off**. Confirm and Trust do
nothing until `omarchy default agent` is set.

Footer Off / Confirm / Trust apply to **Update** on an installed plugin.
New installs use **Secure Install** / **Insecure Install** instead; Secure
always waits for Approve after `CLEAR`.

This is an LLM review via `omarchy agent prompt`, not a sandbox. Omarchy
launches the agent with its usual auto-approve flags against a detached
checkout. During the scan the update icon is a red X (cancel). The agent
window is not killed on cancel.

## Install

```bash
omarchy plugin add https://github.com/BonesGit/omarchy-ultimate-plugin-mgr.git --enable
```

## Update

```bash
omarchy plugin update io.github.bonesgit.omarchy-ultimate-plugin-mgr
```

Or use Plugin Manager to update itself.

## Remove

```bash
omarchy plugin remove io.github.bonesgit.omarchy-ultimate-plugin-mgr
```

Helper for the terminal:

```bash
~/.config/omarchy/plugins/io.github.bonesgit.omarchy-ultimate-plugin-mgr/bin/plugin-mgr list
~/.config/omarchy/plugins/io.github.bonesgit.omarchy-ultimate-plugin-mgr/bin/plugin-mgr check
```
