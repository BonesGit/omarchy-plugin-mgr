.pragma library

// Temporary local-test switch. true = every git Update button is enabled even
// when origin is not ahead, and prepare-scan will review HEAD. Set false before shipping.
function debugForceUpdateButtons() {
  return false
}

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

function parseBool(value, fallback) {
  if (value === true || value === "true") return true
  if (value === false || value === "false") return false
  return fallback === true
}

// Default on when unset. Callers still AND this with hasDefaultAgent.
function configuredSecurityScan(settings) {
  if (!settings || settings.securityScan == null || settings.securityScan === "")
    return true
  return parseBool(settings.securityScan, true)
}

// Default off when unset (Confirm mode). Trust only when explicitly enabled.
function configuredTrustScan(settings) {
  if (!settings || settings.trustScan == null || settings.trustScan === "")
    return false
  return parseBool(settings.trustScan, false)
}

function defaultScanMode(settings, hasAgent) {
  if (!hasAgent) return "off"
  if (!configuredSecurityScan(settings)) return "off"
  if (!configuredTrustScan(settings)) return "confirm"
  return "trust"
}

function msUntilDue(checkedAt, checkMs) {
  var last = Number(checkedAt || 0)
  var interval = Number(checkMs || 0)
  if (!last || !interval || !isFinite(last) || !isFinite(interval)) return 0
  var remaining = last * 1000 + interval - Date.now()
  if (remaining < 0) return 0
  return remaining
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

function filterByFirstParty(plugins, firstParty) {
  var out = []
  var list = plugins || []
  var want = !!firstParty
  for (var i = 0; i < list.length; i++) {
    if (list[i] && (list[i].firstParty === true) === want) out.push(list[i])
  }
  return out
}

function matchesQuery(p, query) {
  var q = String(query || "").trim().toLowerCase()
  if (!q) return true
  if (!p) return false
  var name = String(p.name || "").toLowerCase()
  var id = String(p.id || "").toLowerCase()
  return name.indexOf(q) !== -1 || id.indexOf(q) !== -1
}

function filterPlugins(plugins, firstParty, query) {
  var list = filterByFirstParty(plugins, firstParty)
  var q = String(query || "").trim()
  if (!q) return list
  var out = []
  for (var i = 0; i < list.length; i++) {
    if (matchesQuery(list[i], q)) out.push(list[i])
  }
  return out
}

function thirdPartyCount(plugins) {
  return filterByFirstParty(plugins, false).length
}

function gitCount(plugins) {
  var n = 0
  var list = plugins || []
  for (var i = 0; i < list.length; i++) {
    if (list[i] && list[i].git) n++
  }
  return n
}

function pillTooltip(count, updates, checking, lastError, busyKind) {
  if (busyKind === "scan") return "Plugins · scanning"
  if (busyKind === "add") return "Plugins · installing"
  if (busyKind === "confirm") return "Plugins · scan clear — decision needed"
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
  if (p.firstParty === true) return ""
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
