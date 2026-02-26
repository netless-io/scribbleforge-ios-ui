#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PODSPEC_PATH="${ROOT_DIR}/ScribbleForgeUI.podspec"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/release_cocoapods.sh <version> [options]

Example:
  ./scripts/release_cocoapods.sh 0.1.1

Options:
  --skip-lint       Skip `pod spec lint`
  --dry-run         Print commands only, do not execute
  -h, --help        Show this help

This script will:
1) bump version in ScribbleForgeUI.podspec
2) git add/commit/tag
3) git push branch and tag
4) run pod spec lint (unless --skip-lint)
5) pod trunk push
EOF
}

log() {
  echo "[release] $*"
}

die() {
  echo "[release] Error: $*" >&2
  exit 1
}

run_cmd() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "[dry-run] $*"
    return 0
  fi
  "$@"
}

ensure_command() {
  command -v "$1" >/dev/null 2>&1 || die "Command not found: $1"
}

ensure_clean_git_tree() {
  local status
  status="$(git -C "${ROOT_DIR}" status --porcelain)"
  [[ -z "${status}" ]] || die "Git working tree is not clean. Please commit/stash first."
}

extract_current_version() {
  sed -n "s/^[[:space:]]*s\\.version[[:space:]]*=[[:space:]]*'\\([^']*\\)'.*$/\\1/p" "${PODSPEC_PATH}" | head -n 1
}

version_greater_than() {
  local new_version="$1"
  local old_version="$2"
  ruby -e "exit(Gem::Version.new('${new_version}') > Gem::Version.new('${old_version}') ? 0 : 1)"
}

update_podspec_version() {
  local new_version="$1"
  local tmp_file
  tmp_file="$(mktemp)"

  sed "s/^\([[:space:]]*s\\.version[[:space:]]*=[[:space:]]*'\)[^']*'\(.*\)$/\1${new_version}'\2/" "${PODSPEC_PATH}" > "${tmp_file}"
  mv "${tmp_file}" "${PODSPEC_PATH}"
}

VERSION=""
SKIP_LINT="false"
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-lint)
      SKIP_LINT="true"
      shift
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      die "Unknown option: $1"
      ;;
    *)
      if [[ -z "${VERSION}" ]]; then
        VERSION="$1"
      else
        die "Unexpected argument: $1"
      fi
      shift
      ;;
  esac
done

[[ -n "${VERSION}" ]] || {
  usage
  exit 1
}

[[ "${VERSION}" =~ ^[0-9]+(\.[0-9]+){1,3}([.-][0-9A-Za-z]+)?$ ]] || die "Invalid version format: ${VERSION}"
[[ -f "${PODSPEC_PATH}" ]] || die "Podspec not found: ${PODSPEC_PATH}"

ensure_command git
ensure_command pod
ensure_command ruby

CURRENT_VERSION="$(extract_current_version)"
[[ -n "${CURRENT_VERSION}" ]] || die "Cannot parse current version from podspec."
[[ "${CURRENT_VERSION}" != "${VERSION}" ]] || die "New version equals current version (${CURRENT_VERSION})."

if ! version_greater_than "${VERSION}" "${CURRENT_VERSION}"; then
  die "New version (${VERSION}) must be greater than current version (${CURRENT_VERSION})."
fi

ensure_clean_git_tree

if git -C "${ROOT_DIR}" rev-parse "refs/tags/${VERSION}" >/dev/null 2>&1; then
  die "Tag already exists locally: ${VERSION}"
fi

BRANCH_NAME="$(git -C "${ROOT_DIR}" rev-parse --abbrev-ref HEAD)"

log "Current version: ${CURRENT_VERSION}"
log "Release version: ${VERSION}"
log "Branch: ${BRANCH_NAME}"

update_podspec_version "${VERSION}"

log "Committing version bump..."
run_cmd git -C "${ROOT_DIR}" add "${PODSPEC_PATH}"
run_cmd git -C "${ROOT_DIR}" commit -m "Release ${VERSION}"

log "Creating git tag ${VERSION}..."
run_cmd git -C "${ROOT_DIR}" tag -a "${VERSION}" -m "Release ${VERSION}"

log "Pushing branch ${BRANCH_NAME}..."
run_cmd git -C "${ROOT_DIR}" push origin "${BRANCH_NAME}"

log "Pushing tag ${VERSION}..."
run_cmd git -C "${ROOT_DIR}" push origin "${VERSION}"

if [[ "${SKIP_LINT}" == "false" ]]; then
  log "Running pod spec lint..."
  run_cmd pod spec lint "${PODSPEC_PATH}" --allow-warnings
else
  log "Skipping pod spec lint."
fi

log "Publishing to CocoaPods trunk..."
run_cmd pod trunk push "${PODSPEC_PATH}" --allow-warnings

log "Done. Released ${VERSION}."
