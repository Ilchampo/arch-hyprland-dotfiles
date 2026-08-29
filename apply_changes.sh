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
DEST="${TARGET_HOME}/.config"

BACKUP_ROOT="${DEST}/backup"
BACKUP_DIR="${BACKUP_ROOT}/last"

mkdir -p "${DEST}"

# Skip the item if it's a special file or a directory
should_skip() {
  local name="$1"

  case "${name}" in
    .|..|.git|.gitignore|apply_changes.sh|README.md|LICENSE|backup)
      return 0
      ;;
  esac
  [[ "${name}" == .* ]] && return 0
  return 1
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
      rsync -a "${src}/" "${dest_path}/"
    else
      rsync -a "${src}" "$(dirname "${dest_path}")/"
    fi
  else
    mkdir -p "$(dirname "${dest_path}")"
    cp -a "${src}" "$(dirname "${dest_path}")/"
  fi
}

# Fix the owner of the path to the target user
fix_owner() {
  local path="$1"
  
  if [[ "${EUID}" -eq 0 && -e "${path}" ]]; then
    chown -R "${TARGET_USER}:${TARGET_USER}" "${path}"
  fi
}

rm -rf "${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"

copied=0

# Apply the changes to the destination
while IFS= read -r -d '' item; do
  name="$(basename "${item}")"

  if should_skip "${name}"; then
    continue
  fi

  dest_path="${DEST}/${name}"
  backup_path="${BACKUP_DIR}/${name}"

  backup_matching "${item}" "${dest_path}" "${backup_path}"
  apply_item "${item}" "${dest_path}"
  fix_owner "${dest_path}"

  echo "Applied ${name} -> ${dest_path}"
  copied=$((copied + 1))
done < <(find "${REPO_ROOT}" -mindepth 1 -maxdepth 1 -print0 | sort -z)

# Fix the owner of the backup root
fix_owner "${BACKUP_ROOT}"

# If no files were applied, exit with an error
if [[ "${copied}" -eq 0 ]]; then
  echo "No config files found to apply." >&2
  exit 1
fi

TARGET_UID="$(id -u "${TARGET_USER}")"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/${TARGET_UID}}"

# Reload Hyprland as the session user with the runtime directory restored
if [[ "${EUID}" -eq 0 ]]; then
  sudo -u "${TARGET_USER}" XDG_RUNTIME_DIR="${RUNTIME_DIR}" hyprland reload
else
  XDG_RUNTIME_DIR="${RUNTIME_DIR}" hyprland reload
fi

echo "Success - Applied ${copied} item(s) to ${DEST} (user: ${TARGET_USER})."
echo "Previous config saved to ${BACKUP_DIR}."