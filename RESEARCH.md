# AI agents on shared HPC systems: what other centres do

Research date: 2026-10-05; sections 7 to 9 (agent skills) added 2026-10-07. Web research only (no access to private mailing lists or member-only material). Claims link to
their source. Where a claim comes from a search-engine summary rather than a page I fetched, or is my own inference, it
is marked **[unverified]** or **[inference]**.

## Key takeaways for REANNZ

1. **REANNZ is not alone, and the field has converged fast.** In 2026 at least NERSC, ALCF, LUMI, CSCS, Isambard, Purdue
   RCAC, USC CARC, Stanford Sherlock, Yale YCRC, Utah CHPC, Aalto, LBL, OSC and ORNL ExCL published agent guidance. The
   common rules match REANNZ's: the user is accountable for everything the agent does; do not run agents (or heavy work)
   on login nodes; do not hand agents credentials; keep sensitive data away from external LLMs; supervise, do not run
   unattended.
2. **The leaders have moved from advice to system-wide enforcement.** NERSC deployed *managed hooks* for Claude Code and
   Codex on Perlmutter on 2026-08-19 to block broad filesystem traversals
   ([timeline](https://docs.nersc.gov/systems/perlmutter/timeline/)). USC CARC ships `CLAUDE.md`, `managed-settings.json`,
   `AGENTS.md`, `requirements.toml` and a `precheck.sh` hook under `/etc` on login and compute nodes, with an audit log
   ([CARC](https://www.carc.usc.edu/user-guides/ai-computing/ai-coding-agents)). Purdue RCAC deploys per-cluster context
   under `/etc/agents.d/` ([RCAC](https://docs.rcac.purdue.edu/agentic-ai/shared_context/context_files/)). A rules file
   alone is guidance; Claude Code's own docs say CLAUDE.md is context, not enforced configuration, and point to hooks for
   hard blocks ([memory docs](https://code.claude.com/docs/en/memory)).
3. **Only some tools have a true system-wide instruction file.** Claude Code has one (`/etc/claude-code/CLAUDE.md`, which
   users cannot exclude). OpenCode has a root-owned managed config directory (`/etc/opencode/`). Codex, Gemini CLI, Copilot
   CLI and Cursor CLI have **no documented system-wide instruction file**; for those, REANNZ's per-user install (symlink
   into `~/.codex/AGENTS.md` etc.) is the same approach NERSC and LBL use. Codex and Gemini do have system-level
   *enforcement* files (`/etc/codex/requirements.toml`, `/etc/gemini-cli/settings.json`), and Cursor has
   `/etc/cursor/hooks.json`. See the table below.
4. **There is now measurement data.** A Sep 2026 study of Harvard FASRC found agent users were 19.5% of users but 55.8% of
   job submissions, issued commands at 20.8x the human rate, queried the scheduler up to 14x more per job among heavy
   users, ran tree walks 7.9x more per user, and leaked 127 API keys in three weeks
   ([arXiv 2609.38723](https://arxiv.org/html/2609.38723)). This supports REANNZ rules on polling, filesystem traversal
   and secrets, and is citable when proposing rules to the docs team.
5. **Hard controls worth considering beyond AGENTS.md:** Claude Code managed settings + PreToolUse hook (as NERSC/CARC);
   Codex `requirements.toml` with managed hooks; Slurm per-user RPC rate limiting (`SlurmctldParameters=rl_enable`);
   login-node cgroup limits (NERSC cut to 30 GB / 12.5% CPU per user in Apr 2026); an Apptainer agent container (LUMI,
   ORNL ExCL); a centre-hosted LLM endpoint so code need not leave the country (CSCS, Yale, Utah, ALCF, Purdue).
6. **Skills are now a cross-tool standard, and centres ship them.** The Agent Skills format (`SKILL.md`) is read by Claude
   Code, Codex, Gemini CLI, Copilot, Cursor, OpenCode and most others; all but Claude Code also read the shared
   `~/.agents/skills/` path. Isambard, EPCC Cirrus, CSC, Aalto, UC Davis, Indiana and the Alliance (via UAlberta) publish
   official skills. The common design is an always-loaded rules file plus on-demand skills whose `SKILL.md` is a short
   router to `references/`, which is exactly the `dist/AGENTS.md` plus skill split planned here (section 7 and 8). The
   unofficial nesi-support-skill has the right shape but no responsible-use content and is stale (section 9).

## 1. Published guidance by centre

| Centre | What they publish | Notable specifics |
|---|---|---|
| NERSC (US) | [AI Coding Tools at NERSC](https://docs.nersc.gov/development/coding-agents/), [Claude Code on Perlmutter](https://docs.nersc.gov/development/coding-agents/claude-code/), [Codex on Perlmutter](https://docs.nersc.gov/development/coding-agents/codex/), repo [NERSC/coding-agents](https://github.com/nersc/coding-agents/) with `CLAUDE.md` and `AGENTS.md` templates | Users accountable; "Models must not be permitted to operate unsupervised"; agents may run on login nodes for small debugging work only; recommend default Manual permission mode, avoid `bypassPermissions`. Warns that driving Perlmutter via an MCP SSH tool or `ssh perlmutter ...` from a laptop bypasses the system safeguards. Managed hooks against filesystem traversal since 2026-08-19 ([timeline](https://docs.nersc.gov/systems/perlmutter/timeline/)). Templates are per-user, copied into `$HOME`. |
| ALCF / Argonne (US) | [AI Guidance](https://docs.alcf.anl.gov/support/ai-guidance/) **[unverified: page returned 403; content from search summary]** | Agents allowed but unsupported; run on compute nodes; login nodes have a hard per-user task limit that VS Code + AI extensions hit; agent SSH loops to other Argonne systems can get SSH blocked. |
| LBL Science IT, Lawrencium (US) | [Using AI Agents on Lawrencium](https://scienceit-docs.lbl.gov/hpc/ai-tools/ai-agents/) | Run on compute nodes via Slurm; never recursive traversal of `/`, `/global`, shared dirs; bounded `-maxdepth`; suggests putting rules in `~/.claude/CLAUDE.md` or `~/.codex/AGENTS.md` (no central install). |
| ORNL ExCL (US) | [Claude Code and Codex](https://docs.excl.ornl.gov/quick-start-guides/claude-code) | Both tools run inside Apptainer with a throwaway home, only the current repo bind-mounted, no `~/.ssh`, `~/.aws`, `~/.gnupg`; dangerous mode only inside the container. |
| USC CARC (US) | [AI coding agents](https://www.carc.usc.edu/user-guides/ai-computing/ai-coding-agents) | Strongest published example of system-wide enforcement: three layers (guidance file; fixed permission rules; `precheck.sh` hook returning block/ask/allow, logged to an audit log), preinstalled under `/etc` on login and compute nodes. Blocks `mpirun`, `torchrun`, Jupyter etc. on login nodes and destructive commands on other groups' project dirs even when Unix permissions allow. Says do not run agents on login nodes or from `/home`. |
| Purdue RCAC (US) | [Using AI Agents (Gautschi)](https://docs.rcac.purdue.edu/userguides/gautschi/using_ai_agents/), [acceptable use](https://docs.rcac.purdue.edu/agentic-ai/acceptable_use/), [shared context files](https://docs.rcac.purdue.edu/agentic-ai/shared_context/context_files/) | "Proactive engagement, not prohibition". Per-cluster generated Markdown in `/etc/agents.d/` (unix, filesystems, lmod, slurm, policies) concatenated into one `AGENTS.md` and symlinked to each harness's context filename. Recommends running agents locally and reaching the cluster through RCAC MCP servers. Exact delivery per tool not documented on the page I read. |
| Stanford Sherlock (US) | [Coding agents](https://www.sherlock.stanford.edu/docs/software/ai/coding-agents) | Nine agents provided as modules (Claude Code, Gemini CLI, Codex, Cursor CLI, Copilot CLI, Mistral Vibe, OpenCode, Crush, pi); use `sh_dev` interactive sessions, not login nodes; admins may kill agent processes on unstable login nodes; Ollama on a GPU node as private option. |
| Yale YCRC (US) | [AI coding tools](https://docs.ycrc.yale.edu/ai/aicodingtools) | Self-hosted Qwen model on Bouchet recommended; beta sandbox protections exist for Claude only; commercial agents carry data exposure risk. |
| Utah CHPC (US) | [Coding Agents](https://www.chpc.utah.edu/documentation/software/codingagents.php) | Agents only in the General Environment, banned from the Protected Environment; autonomous agents such as OpenClaw banned; only CHPC-provided modules, not self-installed; "Do not allow AI agents to run commands without your explicit approval"; OpenCode module defaults to a CHPC-hosted Qwen model. |
| OSC (US) | [Run Claude Code with local inference](https://www.osc.edu/resources/getting_started/howto/howto_run_claude_code_with_local_inference) | Compute nodes only (OnDemand or `sinteractive`), vLLM local model, sample `~/.claude/settings.json` denying `.ssh`, `.env`, `rm -rf`, `sudo`. |
| LUMI / CSC (EU) | [AI agent guide](https://docs.lumi-supercomputer.eu/development/ai-tools/ai-agent-guide/), [agent infrastructure](https://docs.lumi-supercomputer.eu/laif/software/agent-infrastructure), [announcement](https://lumi-supercomputer.eu/agent-infrastructure/) | Ties use to LUMI Terms of Use; never give credentials to agents on third-party systems; run in Apptainer; avoid many simultaneous agents; do not delegate Git operations. Provides a container where only `$PWD` is visible (not home), OpenCode configured to ask before every tool use, and a public docs MCP server. |
| CSCS Alps (CH) | [Coding Agents on Alps](https://docs.cscs.ch/guides/coding-agents/) | Do not run agents on login nodes; run on compute nodes (ideally in containers/uenvs) or locally with Slurm/FirecREST. Notes that a sandbox around the agent does not propagate to Slurm jobs it submits. Points to a CSCS-hosted LLM inference service. |
| Aalto Triton (FI) | [AI Agents on HPC](https://scicomp.aalto.fi/triton/usage/ai-agents/) | Example global rules include "Wait at least 15 seconds between squeue/sacct calls"; docs MCP server at `https://docs.triton.aalto.fi/mcp/`; asks users to tell the team which agent they use; no officially approved agents. |
| Isambard / BriCS (UK) | [Using AI agents](https://docs.isambard.ac.uk/user-documentation/guides/using_ai_agents/), skills repo [isambard-sc/skills.isambard.ac.uk](https://github.com/isambard-sc/skills.isambard.ac.uk) | Strictest: "Do not run AI agents directly on Isambard login nodes"; run locally, review commands and run them yourself. Publishes official skills. |
| Not found | TACC, PSC, SDSC, OLCF (beyond generic login-node rules), Jülich, ARCHER2, Pawsey, NCI Australia, Princeton, FASRC user docs | Searches found no agent-specific user docs **[absence not proven]**. Skills from CSC, Aalto, EPCC Cirrus, UC Davis, Indiana, the Alliance (via UAlberta) and community TACC/Princeton skills are covered in section 8. |

## 2. Technical controls in use

- **Managed hooks / pre-execution checks.** NERSC managed hooks for Claude Code and Codex
  ([timeline](https://docs.nersc.gov/systems/perlmutter/timeline/)); CARC `precheck.sh` with block/ask/allow and audit log
  ([CARC](https://www.carc.usc.edu/user-guides/ai-computing/ai-coding-agents)). Claude Code can restrict hooks to managed
  ones only via `allowManagedHooksOnly` ([managed settings](https://code.claude.com/docs/en/managed-settings)); Codex
  supports `[hooks]` and `allow_managed_hooks_only = true` in `requirements.toml`
  ([Codex managed configuration](https://learn.chatgpt.com/docs/enterprise/managed-configuration)).
- **Login-node resource limits.** NERSC: per-user login limits cut to 30 GB memory and 12.5% of CPUs on 2026-04-30
  ([timeline](https://docs.nersc.gov/systems/perlmutter/timeline/)). ALCF: hard per-user task limit **[unverified]**.
  Arbiter2 (cgroup daemon from Utah, [GitHub](https://github.com/chpc-uofu/arbiter2)) is used at Utah, where VS Code
  servers trigger Arbiter warnings ([CHPC VS Code](https://www.chpc.utah.edu/documentation/software/vscode.php)); UW Hyak
  moved to Arbiter 3 in Jan 2026 **[unverified, search summary]**. None of these is agent-specific, but they are the
  backstop centres rely on.
- **Agents only in jobs / OnDemand.** CARC, Sherlock, OSC, LBL, CSCS, Isambard require or recommend compute nodes or local
  machines. Utah offers agents through VS Code Desktop in Open OnDemand
  ([CHPC](https://www.chpc.utah.edu/documentation/software/codingagents.php)).
- **Process identification.** The FASRC study labelled login-node processes as agent-driven if they descend from a
  recognised harness (Claude Code, Codex, Cursor, Copilot) ([arXiv 2609.38723](https://arxiv.org/html/2609.38723)). This
  is a workable monitoring signal for REANNZ's misuse monitor **[inference]**.
- **Sandboxing.** Claude Code's Linux sandbox uses bubblewrap and socat, can be forced via managed settings
  (`sandbox.enabled`, `allowUnsandboxedCommands: false`, `failIfUnavailable`)
  ([sandboxing](https://code.claude.com/docs/en/sandboxing)). Codex on Linux uses `bwrap` plus seccomp, network off by
  default in workspace-write ([Codex security](https://learn.chatgpt.com/docs/agent-approvals-security)). Both need
  unprivileged user namespaces, which some HPC kernels disable **[inference; check on Mahuika]**. Container approaches:
  LUMI agent container, ORNL ExCL Apptainer, community [claude-hpc](https://github.com/nollde/claude-hpc) (Podman + Squid
  domain allowlist on Perlmutter).
- **Network egress.** No centre documents agent-specific egress filtering on login nodes. claude-hpc uses a proxy
  allowlist; Claude Code sandbox and Codex `requirements.toml` can restrict domains.
- **Scheduler protection.** Slurm 23.02+ has per-user RPC token-bucket rate limiting via
  `SlurmctldParameters=rl_enable,rl_refill_rate=...,rl_bucket_size=...`; clients are told to back off
  ([Niflheim notes](https://niflheim-system.readthedocs.io/en/latest/Slurm_configuration.html),
  [slurm.conf(5)](https://manpages.debian.org/unstable/slurm-client/slurm.conf.5.en.html)). No centre was found
  documenting turning it on specifically for agents.

## 3. Policy approaches

- **Accountability, not a new AUP.** Every centre states the user is responsible for agent actions (NERSC, LUMI, CSCS,
  Purdue, Isambard, Aalto). Purdue: "You are accountable for everything your agent does under your account, exactly as if
  you had typed it yourself" ([RCAC AUP](https://docs.rcac.purdue.edu/agentic-ai/acceptable_use/)). CSCS adds that
  violations can lead to access revocation ([CSCS](https://docs.cscs.ch/guides/coding-agents/)).
- **Credentials.** LUMI: never give passwords or SSH keys to agents on third-party systems
  ([LUMI guide](https://docs.lumi-supercomputer.eu/development/ai-tools/ai-agent-guide/)); Isambard prohibits sharing
  passwords or keys with agents; CARC denies reading private SSH keys outright. No centre found with agent-specific MFA
  rules.
- **Data classification.** Utah bans agents in its Protected Environment; Purdue requires confirming regulated or
  export-controlled data stays on approved systems; Sherlock, Yale, NERSC warn that prompts and code go to external
  providers.
- **Restrict which tools.** Utah allows only CHPC-provided modules and bans autonomous agents such as OpenClaw.
- **Monitoring / audit.** CARC hook audit log; Purdue notes logging of modules, applications and batch scripts
  ([RCAC AUP](https://docs.rcac.purdue.edu/agentic-ai/acceptable_use/)); FASRC study shows process-tree attribution works.
- **Polling limits.** Aalto's 15 second minimum between `squeue`/`sacct` calls is the only explicit published number
  found.

## 4. Centre-provided LLM services

| Provider | Service |
|---|---|
| CSCS | LLM inference service usable by coding agents, documented under `/services/inference/api/` on docs.cscs.ch ([CSCS](https://docs.cscs.ch/guides/coding-agents/)) |
| ALCF | Inference Service on Sophia and Metis, OpenAI-compatible API, Globus Auth ([docs](https://docs.alcf.anl.gov/services/inference-endpoints/) **[unverified, search summary]**) |
| Yale YCRC | Self-hosted Qwen on Bouchet for local coding agents ([YCRC](https://docs.ycrc.yale.edu/ai/aicodingtools)) |
| Utah CHPC | OpenCode module defaults to free CHPC-hosted Qwen, on test hardware ([CHPC](https://www.chpc.utah.edu/documentation/software/codingagents.php)) |
| Purdue RCAC | Purdue GenAI Studio and AnvilGPT ([RCAC](https://docs.rcac.purdue.edu/userguides/gautschi/using_ai_agents/)) |
| Stanford | Institutional Claude, ChatGPT Edu, Gemini, Copilot and an AI API Gateway; Ollama on GPU nodes ([Sherlock](https://www.sherlock.stanford.edu/docs/software/ai/coding-agents)) |
| OSC | User-run vLLM on GPU compute nodes as the Claude Code backend ([OSC](https://www.osc.edu/resources/getting_started/howto/howto_run_claude_code_with_local_inference)) |

## 5. Per-tool system-wide config locations (Linux)

| Tool | System-wide instruction file | System-wide enforcement | User can bypass? | Source |
|---|---|---|---|---|
| Claude Code | **Yes**: `/etc/claude-code/CLAUDE.md`, or `claudeMd` key inside managed settings. "This file cannot be excluded by individual settings." Loaded before user and project CLAUDE.md. | `/etc/claude-code/managed-settings.json`, `managed-settings.d/*.json`, `managed-mcp.json`: permissions, sandbox, hooks (`allowManagedHooksOnly`), `disableBypassPermissionsMode`, `availableModels`. Top of precedence. | Only by editing root-owned files, or by using a different tool ("managed settings bind Claude Code only"). A managed `model` is a default, not a lock. | [memory](https://code.claude.com/docs/en/memory), [managed settings](https://code.claude.com/docs/en/managed-settings), [settings](https://code.claude.com/docs/en/settings) |
| Codex CLI | **No** documented system AGENTS.md. Global file is `$CODEX_HOME/AGENTS.md` (default `~/.codex`), with `AGENTS.override.md` taking priority; project files capped at 32 KiB (`project_doc_max_bytes`). | `/etc/codex/requirements.toml` (hard constraints: approval policy, sandbox modes, MCP allowlist, network domains, command rules, managed `[hooks]`, `allow_managed_hooks_only`); `/etc/codex/managed_config.toml` (defaults users can change). | Requirements: no. Instructions: yes (user owns `~/.codex`, can set `CODEX_HOME`). Whether `developer_instructions` can be set in `managed_config.toml` is undocumented **[unverified]**. | [managed configuration](https://learn.chatgpt.com/docs/enterprise/managed-configuration), [AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md), [config reference](https://learn.chatgpt.com/docs/config-file/config-reference) |
| Gemini CLI | **No** system GEMINI.md. Global is `~/.gemini/GEMINI.md`; `context.fileName` can be set to `AGENTS.md`. | `/etc/gemini-cli/system-defaults.json` (base) and `/etc/gemini-cli/settings.json` (overrides, final say): `tools.core` allowlist, `tools.sandbox`, `security.disableYoloMode`, hooks. | Yes: path overridable with `GEMINI_CLI_SYSTEM_SETTINGS_PATH` unless a wrapper fixes it; docs say these measures stop accidents, not determined users. | [enterprise](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/enterprise.md), [GEMINI.md](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini-md.md), [settings](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/settings.md) |
| OpenCode | Partly: managed `/etc/opencode/opencode.json(c)` overrides user and project config; its `instructions` key accepts file paths, so it could point at a system rules file **[inference, untested]**. Global rules file `~/.config/opencode/AGENTS.md`; also falls back to `~/.claude/CLAUDE.md`. | Same managed file (permissions etc.). "These directories require admin/root access to write, so users cannot modify them." | Managed file: not by editing; behaviour under `OPENCODE_CONFIG_CONTENT` vs managed not verified. Open bug: global AGENTS.md not loaded when a project AGENTS.md exists ([#22020](https://github.com/anomalyco/opencode/issues/22020)). | [config](https://opencode.ai/docs/config/), [rules](https://opencode.ai/docs/rules/) |
| GitHub Copilot CLI | **No** system file. `~/.copilot/copilot-instructions.md`, `~/.copilot/instructions/**/*.instructions.md`, repo files, `AGENTS.md`/`CLAUDE.md`/`GEMINI.md`, plus dirs in `COPILOT_CUSTOM_INSTRUCTIONS_DIRS` (could be exported from `/etc/profile.d` **[inference]**). | GitHub enterprise/org policy can enable or disable Copilot CLI per organisation (cloud-side, not per machine). | Yes for instructions (env var and home are user-controlled). | [custom instructions](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions), [administering Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/administer-copilot-cli-for-your-enterprise) **[policy detail from search summary]** |
| Cursor CLI | **No** system rules file. Reads project `AGENTS.md`, `CLAUDE.md`, `.cursor/rules`; Team Rules via dashboard (Team/Enterprise plans). | `/etc/cursor/hooks.json` enterprise hooks; permissions in `~/.cursor/cli-config.json` (user-owned). | Instructions yes; enterprise hooks no. Whether `/etc/cursor/hooks.json` is honoured by the CLI (not just the desktop app) is not stated clearly **[unverified]**. | [CLI](https://cursor.com/docs/cli/using), [hooks](https://cursor.com/docs/hooks), [rules](https://cursor.com/docs/rules), [CLI config](https://cursor.com/docs/cli/reference/configuration) |

Implication for `install.sh` **[inference]**: for Claude Code, an admin-installed `/etc/claude-code/CLAUDE.md` containing
`dist/AGENTS.md` (or an `@` import of it) would reach every user with no opt-in, cannot be excluded, and could be paired
with managed hooks. For Codex, Gemini, Copilot and Cursor the per-user symlink remains the only instruction route; hard
limits for Codex and Gemini go in `/etc/codex/requirements.toml` and `/etc/gemini-cli/settings.json`. All `/etc` files
are per node, so they must be deployed on every login node (and compute nodes if agents run there), and do nothing when
a user drives the cluster from an agent on their laptop over SSH (NERSC makes this point explicitly).

## 6. Community and tools

- **Measurement paper:** Zheng et al., "Towards Efficient HPC Systems for Agents: Challenges and Opportunities", FASRC
  data Jul to Aug 2026: `rm -rf $VAR/` with `$VAR` unset in 3.5% of uses; agents weaken safeguards (`chmod 777`,
  disabling TLS checks); 77.2% of agent users fetch external content from login nodes (prompt injection surface)
  ([arXiv](https://arxiv.org/html/2609.38723)).
- **PEARC26 BoF:** "Implementing User-Friendly AI Assistants in HPC Environments" (USDA-ARS, Texas A&M, Harvard, MIT
  Lincoln Lab) with a published report ([Zenodo](https://zenodo.org/records/22218003)). Not read in full.
- **Security benchmark:** "Trusted Credentials, Untrusted Behavior: Benchmarking LLM-Agent Security in HPC"
  ([arXiv 2607.18485](https://arxiv.org/pdf/2607.18485)). PDF could not be parsed; content **[unverified]**.
- **Slurm MCP servers:** [Zhanyl-tech/slurm-mcp](https://github.com/Zhanyl-tech/slurm-mcp) is read-only by construction
  (seven binaries, argument allowlist, `shell=False`), caches 10 s, max 2 concurrent and 30 calls per minute, row caps,
  and runs unprivileged so slurmctld is the backstop. [naveenrajm7/slurm-mcp](https://github.com/naveenrajm7/slurm-mcp)
  is also read-only. [slurmx](https://github.com/ItayZloc/slurmx) defaults to dry-run submissions. Purdue RCAC runs its
  own MCP servers; LUMI and Aalto run docs MCP servers.
- **Skills / rules repos:** see section 8. [argonne-lcf/alcf-agentics-workflow](https://github.com/argonne-lcf/alcf-agentics-workflow)
  turned out to be LangGraph/Globus example workflows and a PBS MCP demo, not agent rules or skills.

## 7. Agent skills: the standard and tool support

- **Agent Skills** is an open format "originally developed by Anthropic, released as an open standard", maintained in the
  `agentskills` GitHub org ([home](https://agentskills.io/home), [repo](https://github.com/agentskills/agentskills)). It
  is not an Agentic AI Foundation project ([AAIF projects](https://aaif.io/projects/)); AGENTS.md is
  ([agents.md](https://agents.md/)). The spec page carries no version number.
- **Format** ([specification](https://agentskills.io/specification)): a directory `<name>/SKILL.md`, with optional
  `scripts/`, `references/`, `assets/`. Frontmatter: `name` (required, 1 to 64 chars of `a-z0-9-`, must equal the
  directory name), `description` (required, up to 1024 chars, says what and when), optional `license`, `compatibility`,
  `metadata` (string map) and experimental `allowed-tools`.
- **Progressive disclosure:** only name and description (about 100 tokens per skill) load at startup; the body loads when
  the skill activates (keep it under 5000 tokens and 500 lines); `references/` files load only when read. Keep references
  one level deep. A validator exists (`skills-ref validate`), labelled demonstration only
  ([skills-ref](https://github.com/agentskills/agentskills/tree/main/skills-ref)).
- **Activation** is model-driven from the description by default, plus an explicit slash or `$name` command in most tools.

| Tool | User path | Project path | System path (Linux) | Source |
|---|---|---|---|---|
| Claude Code | `~/.claude/skills/` | `.claude/skills/` | `/etc/claude-code/.claude/skills/` **[inference]** | [skills](https://code.claude.com/docs/en/skills) |
| Codex CLI | `~/.agents/skills/` | `.agents/skills/` | `/etc/codex/skills` | [build skills](https://learn.chatgpt.com/docs/build-skills) |
| Gemini CLI | `~/.gemini/skills/`, `~/.agents/skills/` | `.gemini/skills/`, `.agents/skills/` | none documented | [skills](https://geminicli.com/docs/cli/skills/) |
| Copilot CLI | `~/.copilot/skills`, `~/.agents/skills` | `.github/skills`, `.claude/skills`, `.agents/skills` | none documented | [create skills](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/create-skills) |
| VS Code Copilot | `~/.copilot/skills/`, `~/.claude/skills/`, `~/.agents/skills/` | same three under the project | none documented | [agent skills](https://code.visualstudio.com/docs/copilot/customization/agent-skills) |
| Cursor | `~/.agents/skills/`, `~/.cursor/skills/` (also `~/.claude`, `~/.codex`) | same under the project | none documented; CLI support not stated **[unverified]** | [skills](https://cursor.com/docs/context/skills) |
| OpenCode | `~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.agents/skills/` | same under the project | none documented | [skills](https://opencode.ai/docs/skills/) |
| Goose, Amp, Windsurf/Devin, Mistral Vibe, pi, Crush | all read `~/.agents/skills/` | all read `.agents/skills/` | Devin `/etc/devin/skills/`; others via a config path | [goose](https://goose-docs.ai/docs/guides/context-engineering/using-skills), [amp](https://ampcode.com/docs/customize/skills), [devin](https://docs.devin.ai/desktop/cascade/skills), [vibe](https://github.com/mistralai/mistral-vibe), [pi](https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/docs/skills.md), [crush](https://github.com/charmbracelet/crush) |

- **Shared paths.** `~/.agents/skills/` is read by every tool above except Claude Code; `~/.claude/skills/` is read by
  Claude Code plus VS Code, Cursor, OpenCode, Amp and Crush. Installing to `~/.agents/skills/<name>` with a symlink at
  `~/.claude/skills/<name>` covers all of them **[inference]**. The client guide recommends clients scan
  `~/.agents/skills/` ([adding skills support](https://agentskills.io/client-implementation/adding-skills-support.md)).
- **Skills and AGENTS.md.** No primary source says how to reference a skill from AGENTS.md. Claude Code's guidance is that
  always-loaded files stay short and "if an entry is a multi-step procedure or only matters for one part of the codebase,
  move it to a skill" ([memory](https://code.claude.com/docs/en/memory)); Ona says the same
  ([Ona](https://ona.com/docs/ona/agents-md)). The client guide's fallback for tools without skill support is a catalogue
  line giving the name, description and absolute path, telling the agent to read that `SKILL.md` when a task matches
  ([adding skills support](https://agentskills.io/client-implementation/adding-skills-support.md)). Claude Code warns that
  a prose pointer only works if the model decides to open the file ([memory](https://code.claude.com/docs/en/memory)).
- **Claude Code now reads AGENTS.md natively** (v2.1.277+), but only when no CLAUDE.md exists in the working directory or
  above it; an `@AGENTS.md` import in CLAUDE.md still works ([memory](https://code.claude.com/docs/en/memory)). The
  installer's import approach remains right.
- **Distribution.** Claude Code plugin marketplaces (`.claude-plugin/marketplace.json`), with admin force-install through
  managed settings and a read-only seed directory (`CLAUDE_CODE_PLUGIN_SEED_DIR`) for shared machines
  ([plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces), [org plugins](https://code.claude.com/docs/en/plugins/org)).
  Codex, Copilot CLI and Gemini have their own plugin or extension installers
  ([Codex](https://learn.chatgpt.com/docs/build-plugins),
  [Copilot](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/plugins-finding-installing),
  [Gemini](https://geminicli.com/docs/extensions/)). Agent Plugins 1.0 is a cross-vendor package (`plugin.json`, a
  `skills/` folder, `mcp.json`) backed by Amazon, Cursor, Microsoft, OpenAI and Vercel, not listing Claude Code
  ([spec](https://agent-plugins.org/specification), [AAIF blog](https://aaif.io/blog/from-skills-and-tools-to-portable-agent-plugins)).
  `npx skills` installs into 75+ agents ([vercel-labs/skills](https://github.com/vercel-labs/skills)).
- **Do agents actually use skills?** Not reliably. In Vercel's evals (Next.js tasks, Jan 2026) an available skill was
  never invoked in 56% of runs and gave no gain over no docs (53% pass); an explicit instruction to use it raised that to
  79%, and a compressed 8 KB docs index kept in AGENTS.md reached 100%; results were sensitive to the instruction's
  wording ([Vercel](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals)). Across 145 real skills,
  paired with/without trials found a positive lift in 72.8% of cases, and static reviews of skill text barely predicted
  real lift (rho 0.14) ([ACES, arXiv 2608.20614](https://arxiv.org/abs/2608.20614)). Implication: keep a compressed
  skill index and an explicit "load the skill" instruction in AGENTS.md, and measure with paired runs rather than review
  **[inference]**.
- **Docs for agents.** docs.nesi.org.nz already serves an `llms.txt` index of per-page Markdown URLs (`llms-full.txt` is
  404; both checked 2026-10-07). A skill can point at those URLs for detail it doesn't carry **[inference]**. GitMCP can
  serve any GitHub repo as a docs MCP server ([gitmcp.io](https://gitmcp.io/)).

## 8. Skills and context packages from other centres

| Centre / project | Official? | Format | Install | Kept in sync with docs? | URL |
|---|---|---|---|---|---|
| Isambard (BriCS) | Yes | 11 SKILL.md skills in a plugin, some with `references/` | Plugin marketplace (Claude, Codex, Cursor, Antigravity); raw URLs on skills.isambard.ac.uk | Agent-run workflow from per-skill `metadata.source_url`; CI checks structure only | [repo](https://github.com/isambard-sc/skills.isambard.ac.uk) |
| EPCC Cirrus | Yes | 6 skills, fork of the Isambard design | Plugin marketplace | As Isambard | [repo](https://github.com/EPCCed/skills.cirrus.ac.uk) |
| CSC (Finland) | Yes | 5 skills, each `SKILL.md` + `references/{concepts,code-patterns}.md` | Claude and Codex plugin manifests, `.agents/skills/` symlinks | `sync-upstream.sh` clones the docs; manual edits; `check-skills.sh` validates the spec | [repo](https://github.com/CSCfi/csc-skills) |
| Aalto Triton | Yes | 7 skills with `sources.tsv` provenance, plus an always-on `triton-rules.md`, plus a docs MCP server | Symlink from a shared directory on the cluster; MCP URL | Manual, MCP is live | [repo](https://github.com/AaltoSciComp/triton-skills) |
| UC Davis HPCCF | Yes | 1 skill: `SKILL.md` (155 lines), 7 references, 3 scripts, evals | Per-user symlink | Docs-derived, facts live-checked Sep 2026 | [repo](https://github.com/ucdavis/ucdhpc-cluster-skill) |
| Indiana (IUSCA) | Likely **[inference]** | 13 skills under `.agents/skills/`, every claim tagged Observed / KB-cited / Practice, "Verified" dates | Clone, Claude marketplace | Weekly freshness CI opens issues; stale after 120 days | [repo](https://github.com/IUSCA/research-technologies) |
| UAlberta (Alliance Canada) | Site-official **[inference]** | Skills plus `/etc` configs plus a docs RAG API skill | `/etc/claude-code/`, `/etc/agents/AGENTS.md`, `profile.d` script symlinking into `~/.agents/skills` etc. without overwriting; ansible | RAG live, skills manual | [repo](https://github.com/ualberta-rcg/drac-agent-skills) |
| Purdue RCAC | Yes | Generated `/etc/agents.d/*.md` concatenated into AGENTS.md; docs MCP; Slurm/Globus MCP servers | System `/etc` and managed settings | Generated from per-cluster YAML; volatile numbers deliberately not hardcoded (agents run `myquota`) | [docs](https://docs.rcac.purdue.edu/agentic-ai/shared_context/context_files/) |
| LUMI AI Factory | Yes | Agent container with bundled AGENTS.md, RAG docs MCP | `module load` | MCP vector index | [docs](https://docs.lumi-supercomputer.eu/laif/software/agent-infrastructure/) |
| USC CARC | Yes | ~18 KB always-loaded rules, managed permissions, 49 KB `precheck.sh` hook | System `/etc` | Hand-written | [repo](https://github.com/uschpc/CARC-Harness-for-Coding-Agents) |
| NERSC | Yes | ~3 KB CLAUDE.md / AGENTS.md; managed filesystem hook; a compute skill "planned" | Manual paste into `~/.claude`, `~/.codex` | Hand-written | [repo](https://github.com/NERSC/coding-agents) |
| Yale SOM | No (practitioners) | 23-skill plugin | Plugin marketplace | Hand-written | [repo](https://github.com/yale-som-hpc/claude-code-marketplace) |
| TACC | No (community) | One 734-line file used as SKILL.md; on-cluster verify scripts with `sbatch --test-only` | Per-user symlink | Hand-written | [repo](https://github.com/sebale16/claude-tacc-skills) |
| pu-shd/slurm-skill | **[unverified]** | Generic Slurm toolkit driven over SSH, site profiles, pytest against a fake cluster | `npx skills add` | Hand-written | [repo](https://github.com/pu-shd/slurm-skill) |

No HPC or Slurm skill is in [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills). Nothing found from
CSCS, NCI, Pawsey, ARCHER2, Jülich, OLCF, OSC, SDSC, PSC, MIT or Harvard **[absence not proven]**.

**Designs worth copying**
- Always-on rules file plus on-demand skills, with `SKILL.md` as a short router and detail in `references/` (Aalto, CSC).
  CSC's authoring guide is the best found: "write only what the reader doesn't already know"; "if deleting a line wouldn't
  change what a model does, delete it."
- Provenance per skill or section (Aalto `sources.tsv`, Isambard `metadata.source_url`), and freshness CI that opens issues
  (Indiana). This repo's `<!-- sources -->` comments and `drift.yml` already do both.
- Query volatile values with commands rather than hardcoding them (Purdue, Aalto).
- Scripts that validate without submitting (`sbatch --test-only` linters at UC Davis and TACC), and with/without-skill
  evals (UC Davis found only some rules measurably change behaviour).
- One source tree installed for many agents: `.agents/skills/` plus Claude plugin manifests (Isambard, CSC), with optional
  `/etc` and `profile.d` deployment (Alliance, Purdue).

**Pitfalls seen**
- Real incident details and an allocation code embedded in a community skill (TACC).
- A skill telling the agent it overrides user instructions and other skills (UC Davis), the pattern Aalto warns about as
  a prompt-injection vector.
- Large always-loaded files (CARC, ~18 KB); "Proprietary" licence on a docs-derived policy skill (Isambard); over-broad
  deny lists blocking read-only commands (Alliance); manual copy-paste updates (NERSC).

## 9. The unofficial nesi-support-skill

[chrisdjscott/nesi-support-skill](https://github.com/chrisdjscott/nesi-support-skill), reviewed at its 2026-09-17 commit
(GPLv3, one author, not affiliated with REANNZ). The upstream AI Agent Guidelines link it as "an unofficial AI skill for
responsible operation".
- **Shape:** `SKILL.md` (78 lines, about 6 KB) named `nesi-hpc`, a router with "Load for" hints; 9 topic references
  (Slurm, Slurm examples, hardware, filesystems, modules, parallel, containers, debugging and efficiency, access) and 53
  per-application files under `references/software/`, about 210 KB in all.
- **Sync:** hand-condensed; `sources.toml` maps references to upstream pages and a drift script diffs a pinned
  support-docs submodule, the same approach as this repo, but with no CI, lint or tests.
- **Coverage gaps:** no data transfer (Globus, rsync, rclone), almost nothing on OnDemand and Jupyter, accounts and
  allocations excluded, and **no responsible-use content**: nothing on polling, scoping, one session, tunnels, secrets or
  the AUP. 57 upstream commits behind, so it misses the AI Agent Guidelines, AUP clause 12 and recent application pages.
- **Possible conflicts with the rules:** a LOCAL-NOTE in that skill tells agents both login and compute nodes have outbound internet for
  `pip install` and `git clone`, with no dependency review; some application pages teach SSH tunnels without separating
  allowed inbound or intra-cluster forwards from forbidden outward ones.
- **Worth keeping:** the router layout and per-application references, terse agent-facing style, `nesi99991` as the only
  example project code, the GPU workload-fit advice.

## Gaps and open questions

- No Australian (NCI, Pawsey), Canadian (Alliance) or UK Tier-2/ARCHER2 agent guidance found. A direct look at their
  docs or an ask on their user lists may find unpublished positions.
- NERSC's managed hook code and CARC's `precheck.sh` are not public as far as I found; worth asking both centres
  directly. How CARC delivers `AGENTS.md` to Codex from `/etc` (given Codex has no system AGENTS.md) is not explained.
- Whether Codex `managed_config.toml` accepts `developer_instructions`, and whether Codex hooks can inject context, is
  undocumented; test before relying on it.
- Whether bubblewrap-based sandboxes work on Mahuika depends on unprivileged user namespaces; check
  `sysctl user.max_user_namespaces` on login nodes.
- ALCF guidance and the security benchmark could not be read directly.
- No centre publishes agent-specific Slurm RPC rate limits or egress filtering; REANNZ would be early if it did.
- Whether Claude Code honours skills under `/etc/claude-code/.claude/skills/` and whether Cursor CLI reads skills at all
  are inferred or unstated; test before relying on either.
- Indiana's and UAlberta's skills look official but neither says so on the pages read.
- Mailing lists (HPC-announce, slurm-users, CUG) were not searchable for this topic; no SC25/SC26 BoF specifically on
  agent safety was found.

## Sources

- NERSC: <https://docs.nersc.gov/development/coding-agents/>, <https://docs.nersc.gov/development/coding-agents/claude-code/>, <https://docs.nersc.gov/development/coding-agents/codex/>, <https://docs.nersc.gov/systems/perlmutter/timeline/>, <https://github.com/nersc/coding-agents/>
- ALCF: <https://docs.alcf.anl.gov/support/ai-guidance/>, <https://docs.alcf.anl.gov/services/inference-endpoints/>
- LBL: <https://scienceit-docs.lbl.gov/hpc/ai-tools/ai-agents/>
- ORNL ExCL: <https://docs.excl.ornl.gov/quick-start-guides/claude-code>
- USC CARC: <https://www.carc.usc.edu/user-guides/ai-computing/ai-coding-agents>
- Purdue RCAC: <https://docs.rcac.purdue.edu/userguides/gautschi/using_ai_agents/>, <https://docs.rcac.purdue.edu/agentic-ai/acceptable_use/>, <https://docs.rcac.purdue.edu/agentic-ai/shared_context/context_files/>
- Stanford: <https://www.sherlock.stanford.edu/docs/software/ai/coding-agents>
- Yale: <https://docs.ycrc.yale.edu/ai/aicodingtools>
- Utah: <https://www.chpc.utah.edu/documentation/software/codingagents.php>, <https://www.chpc.utah.edu/documentation/software/vscode.php>, <https://github.com/chpc-uofu/arbiter2>
- OSC: <https://www.osc.edu/resources/getting_started/howto/howto_run_claude_code_with_local_inference>
- LUMI: <https://lumi-supercomputer.eu/agent-infrastructure/>, <https://docs.lumi-supercomputer.eu/development/ai-tools/ai-agent-guide/>, <https://docs.lumi-supercomputer.eu/laif/software/agent-infrastructure>
- CSCS: <https://docs.cscs.ch/guides/coding-agents/>
- Aalto: <https://scicomp.aalto.fi/triton/usage/ai-agents/>
- Isambard: <https://docs.isambard.ac.uk/user-documentation/faqs/>, <https://docs.isambard.ac.uk/user-documentation/guides/using_ai_agents/>
- Claude Code: <https://code.claude.com/docs/en/memory>, <https://code.claude.com/docs/en/settings>, <https://code.claude.com/docs/en/managed-settings>, <https://code.claude.com/docs/en/sandboxing>
- Codex: <https://learn.chatgpt.com/docs/enterprise/managed-configuration>, <https://learn.chatgpt.com/docs/agent-configuration/agents-md>, <https://learn.chatgpt.com/docs/config-file/config-reference>, <https://learn.chatgpt.com/docs/agent-approvals-security>
- Gemini CLI: <https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/enterprise.md>, <https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini-md.md>, <https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/settings.md>
- OpenCode: <https://opencode.ai/docs/config/>, <https://opencode.ai/docs/rules/>, <https://github.com/anomalyco/opencode/issues/22020>
- Copilot CLI: <https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions>, <https://docs.github.com/en/copilot/how-tos/copilot-cli/administer-copilot-cli-for-your-enterprise>
- Cursor: <https://cursor.com/docs/cli/using>, <https://cursor.com/docs/hooks>, <https://cursor.com/docs/rules>, <https://cursor.com/docs/cli/reference/configuration>
- Slurm rate limiting: <https://niflheim-system.readthedocs.io/en/latest/Slurm_configuration.html>, <https://manpages.debian.org/unstable/slurm-client/slurm.conf.5.en.html>
- Agent Skills: <https://agentskills.io/home>, <https://agentskills.io/specification>, <https://agentskills.io/client-implementation/adding-skills-support.md>, <https://github.com/agentskills/agentskills>, <https://aaif.io/projects/>, <https://agents.md/>, <https://agent-plugins.org/specification>, <https://aaif.io/blog/from-skills-and-tools-to-portable-agent-plugins>, <https://github.com/vercel-labs/skills>, <https://gitmcp.io/>, <https://ona.com/docs/ona/agents-md>
- Skills per tool: <https://code.claude.com/docs/en/skills>, <https://code.claude.com/docs/en/plugin-marketplaces>, <https://code.claude.com/docs/en/plugins/org>, <https://learn.chatgpt.com/docs/build-skills>, <https://learn.chatgpt.com/docs/build-plugins>, <https://geminicli.com/docs/cli/skills/>, <https://geminicli.com/docs/extensions/>, <https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/create-skills>, <https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/plugins-finding-installing>, <https://code.visualstudio.com/docs/copilot/customization/agent-skills>, <https://cursor.com/docs/context/skills>, <https://opencode.ai/docs/skills/>, <https://goose-docs.ai/docs/guides/context-engineering/using-skills>, <https://ampcode.com/docs/customize/skills>, <https://docs.devin.ai/desktop/cascade/skills>, <https://github.com/mistralai/mistral-vibe>, <https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/docs/skills.md>, <https://github.com/charmbracelet/crush>
- Centre skills: <https://github.com/isambard-sc/skills.isambard.ac.uk>, <https://github.com/EPCCed/skills.cirrus.ac.uk>, <https://github.com/CSCfi/csc-skills>, <https://github.com/AaltoSciComp/triton-skills>, <https://github.com/ucdavis/ucdhpc-cluster-skill>, <https://github.com/IUSCA/research-technologies>, <https://github.com/ualberta-rcg/drac-agent-skills>, <https://github.com/uschpc/CARC-Harness-for-Coding-Agents>, <https://github.com/yale-som-hpc/claude-code-marketplace>, <https://github.com/pu-shd/slurm-skill>, <https://github.com/anthropics/skills>, <https://github.com/chrisdjscott/nesi-support-skill>, <https://github.com/lumi-ai-factory/laifs-agent-env>, <https://github.com/lumi-ai-factory/laifs-mcp-server>, <https://docs.rcac.purdue.edu/agentic-ai/mcp_servers/>
- Skill effectiveness: <https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals>, <https://arxiv.org/abs/2608.20614>
- Papers and community: <https://arxiv.org/html/2609.38723>, <https://arxiv.org/pdf/2607.18485>, <https://zenodo.org/records/22218003>, <https://github.com/Zhanyl-tech/slurm-mcp>, <https://github.com/naveenrajm7/slurm-mcp>, <https://github.com/ItayZloc/slurmx>, <https://github.com/nollde/claude-hpc>, <https://github.com/sebale16/claude-tacc-skills>, <https://github.com/argonne-lcf/alcf-agentics-workflow>
