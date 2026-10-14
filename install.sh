#!/bin/bash
# Point each agent tool's home-directory rules file at the REANNZ agent rules.
#
#   ./install.sh               link the rules file of each tool below (the same links new accounts get)
#   ./install.sh --skills      also link the mahuika-* skills into ~/.agents/skills and ~/.claude/skills
#                              (otherwise agents find them through the index in AGENTS.md). The default
#                              off the cluster, where the index's paths don't exist
#   ./install.sh --project DIR also link DIR/AGENTS.md (read by most agents) if DIR has none
#
# The rules are the shared copy maintained by REANNZ when it exists, so every release reaches
# you with no action; otherwise this checkout's dist/AGENTS.md. Skills come from the skills/
# directory next to it. When linking skills, re-run after an update to pick up new skills.
# Never overwrites an existing file: it adds an import line where the tool supports one, or
# prints what to add.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
SHARED=${MAHUIKA_AGENTS_SHARED:-/opt/nesi/share/mahuika-agents/dist/AGENTS.md}
LOCAL=$HERE/dist/AGENTS.md
SRC=${MAHUIKA_AGENTS_SRC:-$([ -r "$SHARED" ] && echo "$SHARED" || echo "$LOCAL")}
SKILLS=$(dirname "$SRC")/skills
MARK="# REANNZ HPC rules for AI agents"

# Each tool's home-directory rules file, and whether it can `@`-import the rules into an existing file.
# Keep in step with the skeleton table in README.md.
TOOLS="Claude-Code:.claude/CLAUDE.md:import
Codex:.codex/AGENTS.md:-
Gemini-CLI:.gemini/GEMINI.md:-
Copilot-CLI:.copilot/copilot-instructions.md:-"

setup_tool() {   # name, file, import
    local name=${1//-/ } f=$HOME/$2
    mkdir -p "$(dirname "$f")"
    if [ -L "$f" ]; then
        case "$(readlink "$f")" in
            "$SHARED"|"$LOCAL"|"$SRC") echo "$name: already set up ($f)"; return ;;
        esac
    elif [ ! -e "$f" ]; then
        ln -s "$SRC" "$f"; echo "$name: linked $f"; return
    elif [ "$3" = import ] && [ -f "$f" ]; then
        if ! grep -qxF "$MARK" "$f"; then printf '\n%s\n@%s\n' "$MARK" "$SRC" >> "$f"; fi
        echo "$name: import in $f"; return
    fi
    echo "$name: $f already exists; not touching it. Add the rules to it yourself:"
    echo "    cat $SRC >> $f"
}

setup_skills() {
    local dir s link
    if [ ! -d "$SKILLS" ]; then echo "Skills: none found at $SKILLS"; return; fi
    for dir in "$HOME/.agents/skills" "$HOME/.claude/skills"; do   # the shared path, and Claude Code's
        mkdir -p "$dir"
        for link in "$dir"/mahuika-*; do   # drop our links, from either copy, so removed skills go too
            [ -L "$link" ] || continue
            case "$(readlink "$link")" in "$(dirname "$SHARED")"/skills/*|"$HERE"/dist/skills/*) rm "$link" ;; esac
        done
        for s in "$SKILLS"/mahuika-*/; do
            link=$dir/$(basename "$s")
            if [ -e "$link" ] || [ -L "$link" ]; then echo "Skills: $link exists; not touching it."; continue; fi
            ln -s "${s%/}" "$link"
        done
        echo "Skills: linked mahuika-* skills into $dir"
    done
}

setup_project() {
    local dir f
    dir=$(cd "$1" && pwd)
    f=$dir/AGENTS.md
    if [ -e "$f" ] || [ -L "$f" ]; then
        echo "Project: $f exists; add a line pointing agents to $SRC, or append it."
        return
    fi
    ln -s "$SRC" "$f"; echo "Project: linked $f -> $SRC"
    if [ "$SRC" != "$SHARED" ]; then
        echo "  Note: the link points into your own checkout, so other members of this project may not be able to read it."
    fi
    if git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
        echo "  Note: $dir is a git repo. To keep the link out of commits:"
        echo "    echo AGENTS.md >> $(git -C "$dir" rev-parse --absolute-git-dir)/info/exclude"
    fi
}

usage() { sed -n '2,14p' "$0"; exit 1; }

# No shared copy means we're off the cluster: the index's paths won't resolve, so link the skills.
skills=$([ -r "$SHARED" ] && echo 0 || echo 1) project=
while [ $# -gt 0 ]; do
    case "$1" in
        --skills) skills=1 ;;
        --project) project=${2:?--project needs a directory}; shift ;;
        *) usage ;;
    esac
    shift
done

echo "Rules: $SRC (release $(cat "$(dirname "$SRC")/RELEASE" 2>/dev/null || echo unknown))"
while IFS=: read -r name file imp; do setup_tool "$name" "$file" "$imp"; done <<< "$TOOLS"
if [ "$skills" = 1 ]; then setup_skills; fi
if [ -n "$project" ]; then
    setup_project "$project"
else
    echo "Tools without a home-directory rules file (Cursor CLI) read AGENTS.md in the project root."
    echo "Run: $0 --project /path/to/project"
fi
