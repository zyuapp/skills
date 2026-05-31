#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./uninstall.sh [--target DIR] [--dry-run]

Remove symlinks from the Codex skills directory that point to top-level skills in this repo.

Options:
  --target DIR  Remove links from DIR instead of the default Codex skills dir.
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

found=false

for skill_manifest in "$repo_root"/*/SKILL.md; do
  [[ -e "$skill_manifest" ]] || continue
  found=true

  skill_dir="$(dirname "$skill_manifest")"
  skill_name="$(basename "$skill_dir")"
  link_path="$target_dir/$skill_name"

  if [[ ! -e "$link_path" && ! -L "$link_path" ]]; then
    echo "skip: $link_path does not exist"
    continue
  fi

  if [[ ! -L "$link_path" ]]; then
    echo "skip: $link_path is not a symlink"
    continue
  fi

  current_target="$(readlink "$link_path")"
  if [[ "$current_target" != "$skill_dir" ]]; then
    echo "skip: $link_path points to $current_target"
    continue
  fi

  run rm "$link_path"
  if [[ "$dry_run" == true ]]; then
    echo "would remove: $link_path"
  else
    echo "removed: $link_path"
  fi
done

if [[ "$found" != true ]]; then
  echo "error: no top-level skill directories with SKILL.md found" >&2
  exit 1
fi
