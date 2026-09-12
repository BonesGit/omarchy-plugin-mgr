.pragma library

function configuredCheckHours(settings) {
  var n = settings && settings.checkHours != null ? Number(settings.checkHours) : 24
  if (!isFinite(n)) n = 24
  if (n < 1) n = 1
  if (n > 168) n = 168
  return Math.round(n)
}

function configuredCheckMs(settings) {
  return configuredCheckHours(settings) * 3600 * 1000
}

function clipError(text) {
  var s = String(text || "").replace(/\s+/g, " ").trim()
  if (s.length > 240) s = s.slice(0, 237) + "..."
  return s
}

function updateCount(plugins) {
  var n = 0
  var list = plugins || []
  for (var i = 0; i < list.length; i++) {
    if (list[i] && list[i].updateAvailable) n++
  }
  return n
}

function gitCount(plugins) {
  var n = 0
  var list = plugins || []
  for (var i = 0; i < list.length; i++) {
    if (list[i] && list[i].git) n++
  }
  return n
}

function pillTooltip(count, updates, checking, lastError) {
  if (checking) return "Plugins · checking"
  if (lastError) return "Plugins · " + clipError(lastError)
  if (updates === 1) return "Plugins · 1 update"
  if (updates > 1) return "Plugins · " + updates + " updates"
  if (count === 1) return "1 third-party plugin"
  return count + " third-party plugins"
}

function relativeTime(ts, now) {
  var t = Number(ts || 0)
  if (!t) return "never"
  var sec = Math.max(0, Math.round((now - t * 1000) / 1000))
  if (sec < 60) return "just now"
  if (sec < 3600) return Math.round(sec / 60) + "m ago"
  if (sec < 86400) return Math.round(sec / 3600) + "h ago"
  return Math.round(sec / 86400) + "d ago"
}

function versionLine(p) {
  if (!p || !p.version) return ""
  return "v" + p.version
}

function idLine(p) {
  return p && p.id ? String(p.id) : ""
}

function gitLine(p) {
  if (!p) return ""
  if (!p.git) return "local"
  if (p.checkError) return "check failed"
  var sha = p.localCommit || ""
  if (p.updateAvailable && Number(p.ahead) > 0) {
    var n = Number(p.ahead)
    var behind = n === 1 ? "1 behind" : n + " behind"
    return sha ? behind + " · " + sha : behind
  }
  return sha
}

function statusLine(p) {
  var left = idLine(p)
  var right = gitLine(p)
  if (left && right) return left + " · " + right
  return left || right
}

function kindsLine(p) {
  if (!p || !p.kinds || !p.kinds.length) return ""
  return p.kinds.join(", ")
}
