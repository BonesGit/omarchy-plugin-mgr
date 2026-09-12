# Plugin Manager

Omarchy bar widget that lists **third-party** shell plugins, with enable/disable,
git update checks, update, remove, and a button that opens the repo.

Plugin id: `io.github.bonesgit.omarchy-plugin-mgr`

## What it shows

Each installed third-party plugin (anything under `~/.config/omarchy/plugins/`
that is not `omarchy.*`):

- name, id, version
- enabled / disabled
- git vs local-only
- commits ahead of origin (after a check)

First-party widgets are ignored.

## Actions

- **Enable / disable** — `omarchy plugin enable|disable`
- **Check** — `git fetch origin HEAD` then `rev-list HEAD..FETCH_HEAD` (same
  comparison `omarchy plugin update` uses)
- **Update** — `omarchy plugin update <id> --yes`
- **Remove** — right-click a row twice (second click within 4s)
- **Repo** — `xdg-open` the origin URL (or `repository` / `homepage` in the
  manifest)

Periodic checks default to every 24 hours (bar setting `checkHours`). Right-click
the pill, or `r` in the panel, runs a check now.

## Install

```bash
cd ~/projects/omarchy-plugin-mgr
chmod +x install-dev.sh bin/plugin-mgr
./install-dev.sh
omarchy restart shell
omarchy plugin enable io.github.bonesgit.omarchy-plugin-mgr --section right --after work
```

`install-dev.sh` copies (does not symlink) into
`~/.config/omarchy/plugins/io.github.bonesgit.omarchy-plugin-mgr`. It does not restart the shell.

Helper for the terminal:

```bash
~/.config/omarchy/plugins/io.github.bonesgit.omarchy-plugin-mgr/bin/plugin-mgr list
~/.config/omarchy/plugins/io.github.bonesgit.omarchy-plugin-mgr/bin/plugin-mgr check
```
