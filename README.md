# skypies

Claude Code plugin for [skypies](https://contracthero.dev/skypies/), the
companion that lets your agents make links to the Mac app. It adds two things:

1. The **`skypies` MCP server**, which ships inside the skypies app. It sends
   local files straight to your paired skypies devices over a direct,
   end-to-end encrypted peer-to-peer link. Nothing is uploaded to a server.
2. A **SessionStart hook**, which offers device pairing the first time you open
   a Claude Code Remote Control session, so your phone can receive files without
   you having to remember to set it up.

## Install

The plugin needs the skypies app on your Mac.
[Download the DMG](https://github.com/contract-hero/skypies-releases/releases/latest/download/skypies-universal.dmg)
(universal, macOS 11+). Then install the plugin:

```
claude plugin marketplace add contract-hero/plugin-marketplace
claude plugin install skypies@contract-hero
```

The plugin downloads nothing. It runs the server at
`skypies.app/Contents/MacOS/skypies-mcp`, so the server and the app always come
from the same build. Update the app to update the server.

> If you already added `skypies` by hand with `claude mcp add`, remove that entry
> first with `claude mcp remove skypies`. Two servers with the same name is one
> too many.

## Tools

| Tool | Use it for |
|---|---|
| `share_link` | A link for the user's own paired devices; the device that opens it pulls the file from this Mac. |
| `beam_artifact` | A shareable link, or a recipient that is not paired. |
| `list_devices` | Which devices are paired, and whether each is online. |
| `list_feedback`, `resolve_feedback` | The comments the user left on an artifact, and marking one addressed. |
| `pair_device`, `pair_status`, `confirm_pairing` | Pairing a new device. |
| `server_status`, `stop_beam` | Diagnosing a failed send, and retiring a link. |

Pairing always needs a person: six words appear on both screens and the human
compares them before `confirm_pairing` runs.

## Send boundary

`SKYPIES_MCP_ROOTS` is a colon-separated list of directories the server may send
files from. A path outside every root is refused. The plugin leaves it unset, so
it defaults to the directory Claude Code launched the server in. Widen it only
on purpose, in your own MCP settings.

## The pairing hook

`hooks/offer-skypies-pairing.sh` runs on SessionStart and stays completely silent
unless every one of these is true:

| Condition | Why |
|---|---|
| `CLAUDE_CODE_ENVIRONMENT_KIND=bridge` | `claude rc` sets this in every session it spawns for a phone, before the process starts. A plain local session leaves it unset. |
| `CLAUDE_CODE_REMOTE_SESSION_ID` unset | Drops cloud sessions, which run on Anthropic hardware and cannot reach your machine's files. |
| `~/.claude/.skypies-paired` absent | Written once a device is confirmed paired. |
| `~/.claude/.skypies-no-offer` absent | Written if you decline the offer. |

When it does fire, it injects one note asking Claude to call `list_devices` and
offer pairing only when no device is paired. The hook never reads skypies state
files, so a change to skypies's on-disk format cannot break it.

### Known gap

A session that starts local and turns on Remote Control later with
`/remote-control` is **not** detected. The bridge attaches after SessionStart has
already run, so no SessionStart hook can see it. Sessions started from the phone
against a running `claude rc` are the covered path.

### Re-arm or silence it

```
rm    ~/.claude/.skypies-paired      # offer pairing again
touch ~/.claude/.skypies-no-offer    # never offer again
```

## Server resolution

The launcher, `bin/skypies-mcp-launch.sh`, tries these in order:

| Order | Source |
|---|---|
| 1 | `$SKYPIES_MCP_BIN` — explicit override, for a dev build |
| 2 | `/Applications/skypies.app`, then `~/Applications/skypies.app` |
| 3 | Spotlight, by the bundle id `ai.skypies.skypies` (build trees under `target/` are skipped) |

If it finds no app, or only an app older than the plugin (one without
`skypies-mcp`), the server fails to start, and the MCP log says which case
applies and where to download the app.

## License

Apache-2.0
