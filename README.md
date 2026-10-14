# mahuika-agents

Rules and skills for AI agents (Claude Code, Codex, Copilot, Gemini CLI, OpenCode, ...) running on REANNZ HPC
(Mahuika).

- [`dist/AGENTS.md`](dist/AGENTS.md): the rules, condensed from the
  [AI Agent Guidelines](https://docs.nesi.org.nz/Software/AI/AI_Agent_Guidelines/), the
  [Acceptable Use Policy](https://docs.nesi.org.nz/Policy/Acceptable_Use_Policy/) and the scheduler and storage facts
  an agent needs. Loaded into every session, so kept under 150 lines.
- [`dist/skills/mahuika-*`](dist/skills): how-to detail, read only when a task needs it. `AGENTS.md` lists each one
  with its path. They replace the unofficial [nesi-support-skill](https://github.com/chrisdjscott/nesi-support-skill).

## Users

Agents should read `/opt/nesi/share/mahuika-agents/dist/AGENTS.md`. Each tool's home-directory rules file links to
it. The installer makes these links.

| Link in `$HOME` | Read by |
|---|---|
| `.claude/CLAUDE.md` | Claude Code, and OpenCode as a fallback |
| `.codex/AGENTS.md` | Codex |
| `.gemini/GEMINI.md` | Gemini CLI |
| `.copilot/copilot-instructions.md` | Copilot CLI |

Run it to make any that are missing:

```bash
/opt/nesi/share/mahuika-agents/install.sh
```

`--skills` will also link the skills into ~/.agents/skills and ~/.claude/skills (native loading, /mahuika-* commands).
`--project ~/myproj` will also ~/myproj/AGENTS.md, for tools with no home-directory file (Cursor CLI)

It never overwrites a file: if one already exists, it adds an `@` import (Claude Code) or prints what to add.

**Agents on your own computer** don't see the cluster's copy. Clone this repo there and run
`install.sh`, which links the skills too off the cluster; `git pull` to update, then re-run it to pick up new skills. Never let such an agent log in on its own.

## Update Main Repo

`/opt/nesi/share/mahuika-agents` is a clone of this repo, readable by everyone and writable only by the account that
updates it. Everything points into its `dist/`, so the path must not change. To deploy, pull the latest:

```bash
git -C /opt/nesi/share/mahuika-agents pull --ff-only
```

## Global links and configs

System-wide config files

| Link | Target | Why |
|---|---|---|
| `/etc/claude-code/managed-settings.d/mahuika-agents.json` | `/opt/nesi/share/mahuika-agents/etc/claude-code/managed-settings.d/mahuika-agents.json` | Claude Code reads the skills without a permission prompt |
| `/etc/claude-code/CLAUDE.md` | `/opt/nesi/share/mahuika-agents/dist/AGENTS.md` | Optional: rules for every Claude Code user, which users can't opt out of |
| `/etc/ampcode/AGENTS.md` | `/opt/nesi/share/mahuika-agents/dist/AGENTS.md` | the same for Amp |
| `/etc/codex/skills/` | `/opt/nesi/share/mahuika-agents/dist/skills/` | native skills for Codex |

## Workflow

`dist/` says only what the [support docs](https://github.com/nesi/support-docs) say, plus facts from the live
cluster and official tool documentation.

- Each heading in `src/` cites the docs pages it condenses.
- `tools/drift.py` (weekly in CI) reports docs changes and the sections that cite them.
- `tools/verify.py` checks every enforced limit in `dist/` against `sacctmgr` and `sinfo`.
- Where the docs are wrong or missing something, it goes to the docs team via [DOC-ISSUES.md](DOC-ISSUES.md),
  not into `dist/`.

To maintain it, see [MAINTAINING.md](MAINTAINING.md):

```bash
tools/drift.py              # what changed upstream, and which rules cite it
tools/verify.py             # published numbers against the live cluster (on a login node)
# edit src/
tools/build.py && python3 -m unittest discover tests
tools/drift.py --mark       # refuses unless the build passes
```

## Licence

GPLv3, as a derivative of [nesi/support-docs](https://github.com/nesi/support-docs) (copyright REANNZ / NeSI,
GPLv3). Structure and update approach follow [nesi-support-skill](https://github.com/chrisdjscott/nesi-support-skill).
