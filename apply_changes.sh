#!/usr/bin/env bash
set -euo pipefail

# Determine the target user and home directory
if [[ -n "${SUDO_USER:-}" && "${EUID}" -eq 0 ]]; then
  TARGET_USER="${SUDO_USER}"
  TARGET_HOME="$(getent passwd "${SUDO_USER}" | cut -d: -f6)"
else
  TARGET_USER="$(id -un)"
  TARGET_HOME="${HOME}"
fi

# Check if the home directory is valid
if [[ -z "${TARGET_HOME}" || ! -d "${TARGET_HOME}" ]]; then
  echo "There's an issue with home directory: ${TARGET_USER}." >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="${TARGET_HOME}/.config/backup"
BACKUP_DIR="${BACKUP_ROOT}/last"

# Skip repo metadata that is not a destination root
should_skip() {
  local name="$1"

  case "${name}" in
    .|..|.git|.gitignore|.agents|.codex|apply_changes.sh|README.md|LICENSE|backup)
      return 0
      ;;
  esac
  return 1
}

# Map a repo top-level name to a destination path.
# Hidden names (e.g. .config) live under the target home.
# Known system roots (e.g. etc) live at the filesystem root.
dest_for() {
  local name="$1"

  if [[ "${name}" == .* ]]; then
    echo "${TARGET_HOME}/${name}"
    return 0
  fi

  case "${name}" in
    etc)
      echo "/etc"
      return 0
      ;;
  esac

  return 1
}

is_home_dest() {
  local dest="$1"

  [[ "${dest}" == "${TARGET_HOME}" || "${dest}" == "${TARGET_HOME}/"* ]]
}

# Backup the matching files between the source and destination
backup_matching() {
  local src="$1"
  local dest_path="$2"
  local backup_path="$3"

  if [[ -f "${src}" ]]; then
    if [[ -f "${dest_path}" ]]; then
      mkdir -p "$(dirname "${backup_path}")"
      cp -a "${dest_path}" "${backup_path}"
    fi

    return
  fi

  if [[ -d "${src}" ]]; then
    local file rel

    while IFS= read -r -d '' file; do
      rel="${file#"${src}/"}"

      if [[ -f "${dest_path}/${rel}" ]]; then
        mkdir -p "$(dirname "${backup_path}/${rel}")"
        cp -a "${dest_path}/${rel}" "${backup_path}/${rel}"
      fi
    done < <(find "${src}" -type f -print0)
  fi
}

# Apply the item to the destination using rsync or cp
apply_item() {
  local src="$1"
  local dest_path="$2"

  if command -v rsync >/dev/null 2>&1; then
    if [[ -d "${src}" ]]; then
      mkdir -p "${dest_path}"
      rsync -a --exclude 'backup' "${src}/" "${dest_path}/"
    else
      mkdir -p "$(dirname "${dest_path}")"
      rsync -a "${src}" "$(dirname "${dest_path}")/"
    fi
  else
    mkdir -p "$(dirname "${dest_path}")"
    cp -a "${src}" "$(dirname "${dest_path}")/"
  fi
}

# Fix the owner of copied paths without touching the rest of the destination
fix_copied_owner() {
  local src="$1"
  local dest_path="$2"
  local owner="$3"

  if [[ "${EUID}" -ne 0 || ! -e "${dest_path}" ]]; then
    return
  fi

  if [[ -f "${src}" ]]; then
    chown "${owner}:${owner}" "${dest_path}"
    return
  fi

  if [[ -d "${src}" ]]; then
    local child name

    while IFS= read -r -d '' child; do
      name="$(basename "${child}")"
      [[ "${name}" == backup ]] && continue

      if [[ -e "${dest_path}/${name}" ]]; then
        chown -R "${owner}:${owner}" "${dest_path}/${name}"
      fi
    done < <(find "${src}" -mindepth 1 -maxdepth 1 -print0)
  fi
}

rm -rf "${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"

copied=0
skipped=0

# Apply each matching destination root in the repository
while IFS= read -r -d '' item; do
  name="$(basename "${item}")"

  if should_skip "${name}"; then
    continue
  fi

  if ! dest_path="$(dest_for "${name}")"; then
    continue
  fi

  if ! is_home_dest "${dest_path}"; then
    if [[ "${EUID}" -ne 0 ]]; then
      echo "Skipping ${name} -> ${dest_path} (requires root)." >&2
      skipped=$((skipped + 1))
      continue
    fi

    if [[ ! -d "${dest_path}" ]]; then
      echo "Skipping ${name}: no matching directory ${dest_path}." >&2
      skipped=$((skipped + 1))
      continue
    fi
  fi

  backup_path="${BACKUP_DIR}/${name}"

  backup_matching "${item}" "${dest_path}" "${backup_path}"
  apply_item "${item}" "${dest_path}"

  if is_home_dest "${dest_path}"; then
    fix_copied_owner "${item}" "${dest_path}" "${TARGET_USER}"
  else
    fix_copied_owner "${item}" "${dest_path}" "root"
  fi

  echo "Applied ${name} -> ${dest_path}"
  copied=$((copied + 1))
done < <(find "${REPO_ROOT}" -mindepth 1 -maxdepth 1 -print0 | sort -z)

# Fix the owner of the backup root
if [[ "${EUID}" -eq 0 && -e "${BACKUP_ROOT}" ]]; then
  chown -R "${TARGET_USER}:${TARGET_USER}" "${BACKUP_ROOT}"
fi

# If no files were applied, exit with an error
if [[ "${copied}" -eq 0 ]]; then
  echo "No config files found to apply." >&2
  exit 1
fi

echo "Success - Applied ${copied} item(s) (user: ${TARGET_USER})."

# Preserve the user's selected theme across repository deployments. The state
# lives outside the repository, in ~/.local/state/theme-switch/current.
if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this script without sudo in your desktop session to restore your selected theme."
else
  if command -v gsettings >/dev/null 2>&1; then
    for session_key in gtk-theme icon-theme; do
      if previous_value="$(gsettings get org.gnome.desktop.interface "${session_key}")"; then
        printf 'gsettings set org.gnome.desktop.interface %q %q\n' \
          "${session_key}" "${previous_value}" >> "${BACKUP_DIR}/restore-gtk-session.sh"
      fi
    done
  fi
  "${TARGET_HOME}/.local/bin/theme-switch" --restore
fi

if [[ "${skipped}" -gt 0 ]]; then
  echo "Skipped ${skipped} item(s). Re-run with sudo to apply system paths."
fi
echo "Previous config saved to ${BACKUP_DIR}."
