#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=release_metadata.sh
source "$ROOT_DIR/script/release_metadata.sh"

EXPECTED_NAME="SakuraCord.v0.1.0.dmg"
ACTUAL_NAME="$(sakuracord_release_dmg_name "0.1.0")"
ACTUAL_URL_NAME="$(sakuracord_release_dmg_url_name "0.1.0")"

if [[ "$ACTUAL_NAME" != "$EXPECTED_NAME" ]]; then
  echo "Unexpected release DMG name: $ACTUAL_NAME" >&2
  exit 1
fi
if [[ "$ACTUAL_URL_NAME" != "$EXPECTED_NAME" ]]; then
  echo "Unexpected release DMG URL name: $ACTUAL_URL_NAME" >&2
  exit 1
fi
if [[ "$ACTUAL_NAME" == *" "* || "$ACTUAL_NAME" == *"%"* ]]; then
  echo "Release asset names must not be normalized by GitHub." >&2
  exit 1
fi
if sakuracord_release_dmg_name "0.1" >/dev/null 2>&1; then
  echo "Invalid release versions must be rejected." >&2
  exit 1
fi

DEFAULT_REPOSITORY="$(
  unset SAKURACORD_RELEASE_REPOSITORY
  sakuracord_release_repository
)"
if [[ "$DEFAULT_REPOSITORY" != "SakuraCordApp/SakuraCord" ]]; then
  echo "Unexpected default release repository: $DEFAULT_REPOSITORY" >&2
  exit 1
fi

FORK_BASE_URL="$(
  SAKURACORD_RELEASE_REPOSITORY="waruhachi/SakuraCord"
  export SAKURACORD_RELEASE_REPOSITORY
  sakuracord_release_base_url
)"
if [[ "$FORK_BASE_URL" != "https://github.com/waruhachi/SakuraCord" ]]; then
  echo "Unexpected configured release URL: $FORK_BASE_URL" >&2
  exit 1
fi

if SAKURACORD_RELEASE_REPOSITORY="waruhachi/SakuraCord/extra" \
  sakuracord_release_repository >/dev/null 2>&1; then
  echo "Invalid release repositories must be rejected." >&2
  exit 1
fi

printf 'Release metadata tests passed.\n'
