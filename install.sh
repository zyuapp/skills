#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./install.sh [--target DIR] [--force] [--dry-run]

Symlink each top-level skill directory in this repo into the Codex skills directory.

Options:
  --target DIR  Install links into DIR instead of the default Codex skills dir.
  --force       Replace existing symlinks that point somewhere else.
  --dry-run     Print the actions without changing files.
  -h, --help    Show this help.
EOF
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -n "${CODEX_SKILLS_DIR:-}" ]]; then
  target_dir="$CODEX_SKILLS_DIR"
elif [[ -n "${AGENTS_SKILLS_DIR:-}" ]]; then
  target_dir="$AGENTS_SKILLS_DIR"
else
  target_dir="${CODEX_HOME:-"$HOME/.codex"}/skills"
fi
force=false
dry_run=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      if [[ $# -lt 2 ]]; then
        echo "error: --target requires a directory" >&2
        exit 2
      fi
      target_dir="$2"
      shift 2
      ;;
    --force)
      force=true
      shift
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

run() {
  if [[ "$dry_run" == true ]]; then
    printf 'dry-run:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

run mkdir -p "$target_dir"

found=false

for skill_manifest in "$repo_root"/*/SKILL.md; do
  [[ -e "$skill_manifest" ]] || continue
  found=true

  skill_dir="$(dirname "$skill_manifest")"
  skill_name="$(basename "$skill_dir")"
  link_path="$target_dir/$skill_name"

  if [[ -L "$link_path" ]]; then
    current_target="$(readlink "$link_path")"
    if [[ "$current_target" == "$skill_dir" ]]; then
      echo "ok: $link_path already points to $skill_dir"
      continue
    fi

    if [[ "$force" == true ]]; then
      run rm "$link_path"
    else
      echo "error: $link_path is already a symlink to $current_target" >&2
      echo "       rerun with --force to replace symlinks only" >&2
      exit 1
    fi
  elif [[ -e "$link_path" ]]; then
    echo "error: $link_path already exists and is not a symlink" >&2
    echo "       move it aside manually before installing" >&2
    exit 1
  fi

  run ln -s "$skill_dir" "$link_path"
  if [[ "$dry_run" == true ]]; then
    echo "would link: $link_path -> $skill_dir"
  else
    echo "linked: $link_path -> $skill_dir"
  fi
done

if [[ "$found" != true ]]; then
  echo "error: no top-level skill directories with SKILL.md found" >&2
  exit 1
fi
