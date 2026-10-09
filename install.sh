#!/bin/bash
# Point each agent tool's home-directory rules file at the REANNZ agent rules.
#
#   ./install.sh               link the rules file of each tool below (the same links new accounts get)
#   ./install.sh --skills      also link the mahuika-* skills into ~/.agents/skills and ~/.claude/skills
#                              (otherwise agents find them through the index in AGENTS.md)
#   ./install.sh --project DIR also link DIR/AGENTS.md (read by most agents) if DIR has none
#   ./install.sh --uninstall   remove what this script, or the skeleton home directory, added
#
# The rules are the shared copy maintained by REANNZ when it exists, so every release reaches
# you with no action; otherwise this checkout's dist/AGENTS.md. Skills come from the skills/
# directory next to it. With --skills, re-run after an update to pick up new skills.
# Never overwrites an existing file: it adds an import line where the tool supports one, or
# prints what to add.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
SHARED=${MAHUIKA_AGENTS_SHARED:-/opt/nesi/share/mahuika-agents/dist/AGENTS.md}
LOCAL=$HERE/dist/AGENTS.md
SRC=${MAHUIKA_AGENTS_SRC:-$([ -r "$SHARED" ] && echo "$SHARED" || echo "$LOCAL")}
CONF=$HOME/.config/mahuika-agents
PROJECTS=$CONF/projects
SKILLS=$CONF/skills
SKILL_DIRS="$HOME/.agents/skills $HOME/.claude/skills"   # the shared path, and Claude Code's
MARK="# REANNZ HPC rules for AI agents"

# Each tool's home-directory rules file, and whether it can `@`-import the rules into an existing file.
# Keep in step with the skeleton table in README.md.
TOOLS="Claude-Code:.claude/CLAUDE.md:import
Codex:.codex/AGENTS.md:-
Gemini-CLI:.gemini/GEMINI.md:-
Copilot-CLI:.copilot/copilot-instructions.md:-"

# True if $1 is a link to the rules: the shared copy, or a checkout's.
links_to_rules() {
    [ -L "$1" ] || return 1
    case "$(readlink "$1")" in "$SHARED"|"$LOCAL"|"$SRC") return 0 ;; *) return 1 ;; esac
}

setup_tool() {   # name, file, import
    local name=${1//-/ } f=$HOME/$2
    mkdir -p "$(dirname "$f")"
    if links_to_rules "$f"; then echo "$name: already set up ($f)"; return; fi
    if [ ! -e "$f" ] && [ ! -L "$f" ]; then ln -s "$SRC" "$f"; echo "$name: linked $f"; return; fi
    if [ "$3" = import ] && [ -f "$f" ] && [ ! -L "$f" ]; then
        if grep -qxF "$MARK" "$f"; then echo "$name: already set up ($f)"; return; fi
        printf '\n%s\n@%s\n' "$MARK" "$SRC" >> "$f"; echo "$name: added import to $f"; return
    fi
    echo "$name: $f already exists; not touching it. Add the rules to it yourself:"
    echo "    cat $SRC >> $f"
}

remove_tool() {   # name, file
    local name=${1//-/ } f=$HOME/$2
    if links_to_rules "$f"; then rm "$f"; echo "$name: removed $f"; return; fi
    [ -f "$f" ] && [ ! -L "$f" ] && grep -qxF "$MARK" "$f" || return 0
    # Drop the marker, the import line after it, and the blank line setup_tool added before it.
    awk -v m="$MARK" '
        $0 == m { drop = 1; blank = 0; next }
        drop    { drop = 0; next }
        blank   { print ""; blank = 0 }
        $0 == "" { blank = 1; next }
        { print }
        END { if (blank) print "" }' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    if [ -s "$f" ]; then echo "$name: removed import from $f"; else rm "$f"; echo "$name: removed $f (it held only the import)"; fi
}

each_tool() {   # function to call with name, file, import
    local name file imp
    while IFS=: read -r name file imp; do "$1" "$name" "$file" "$imp"; done <<< "$TOOLS"
}

setup_skills() {
    local src dir s name link
    src=$(dirname "$SRC")/skills
    if [ ! -d "$src" ]; then echo "Skills: none found at $src"; return; fi
    mkdir -p "$CONF"; ln -sfn "$src" "$SKILLS"
    for dir in $SKILL_DIRS; do
        mkdir -p "$dir"
        for s in "$SKILLS"/mahuika-*/; do
            name=$(basename "$s"); link=$dir/$name
            if [ -L "$link" ] && [ "$(readlink "$link")" = "$SKILLS/$name" ]; then continue; fi
            if [ -e "$link" ] || [ -L "$link" ]; then echo "Skills: $link exists; not touching it."; continue; fi
            ln -s "$SKILLS/$name" "$link"
        done
        remove_skill_links "$dir" stale
    done
    echo "Skills: linked $(ls -d "$SKILLS"/mahuika-*/ | wc -l) mahuika-* skills into $SKILL_DIRS"
}

# Remove links into $SKILLS from a skills directory: all of them, or only those whose skill is gone.
remove_skill_links() {
    local link
    for link in "$1"/mahuika-*; do
        [ -L "$link" ] || continue
        case "$(readlink "$link")" in "$SKILLS"/*) ;; *) continue ;; esac
        if [ "$2" = all ] || [ ! -e "$link" ]; then rm "$link"; fi
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
    mkdir -p "$CONF"; grep -qxF "$f" "$PROJECTS" 2>/dev/null || echo "$f" >> "$PROJECTS"
    if [ "$SRC" != "$SHARED" ]; then
        echo "  Note: the link points into your own checkout, so other members of this project may not be able to read it."
    fi
    if git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
        echo "  Note: $dir is a git repo. To keep the link out of commits:"
        echo "    echo AGENTS.md >> $(git -C "$dir" rev-parse --absolute-git-dir)/info/exclude"
    fi
}

uninstall() {
    each_tool remove_tool
    local dir f
    for dir in $SKILL_DIRS; do remove_skill_links "$dir" all; done
    if [ -L "$SKILLS" ]; then rm "$SKILLS"; echo "Skills: removed links"; fi
    if [ -f "$PROJECTS" ]; then
        while read -r f; do
            if links_to_rules "$f"; then rm "$f"; echo "Project: removed $f"; fi
        done < "$PROJECTS"
        rm "$PROJECTS"
    fi
    rmdir "$CONF" 2>/dev/null || true
}

usage() { sed -n '2,14p' "$0"; exit 1; }

skills=0 project=
while [ $# -gt 0 ]; do
    case "$1" in
        --uninstall) [ $# -eq 1 ] || usage; uninstall; exit ;;
        --skills) skills=1 ;;
        --project) project=${2:?--project needs a directory}; shift ;;
        *) usage ;;
    esac
    shift
done

echo "Rules: $SRC (release $(cat "$(dirname "$SRC")/RELEASE" 2>/dev/null || echo unknown))"
each_tool setup_tool
if [ "$skills" = 1 ]; then setup_skills; fi
if [ -n "$project" ]; then
    setup_project "$project"
else
    echo "Tools without a home-directory rules file (Cursor CLI) read AGENTS.md in the project root."
    echo "Run: $0 --project /path/to/project"
fi
