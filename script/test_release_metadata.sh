#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=release_metadata.sh
source "$ROOT_DIR/script/release_metadata.sh"

EXPECTED_NAME="SakuraCord.v0.1.0.dmg"
ACTUAL_NAME="$(sakuracord_release_dmg_name "0.1.0")"
ACTUAL_URL_NAME="$(sakuracord_release_dmg_url_name "0.1.0")"
ACTUAL_TAG_NAME="$(sakuracord_release_dmg_name_from_tag "v0.1.0")"
ACTUAL_BETA_TAG_NAME="$(sakuracord_release_dmg_name_from_tag "v0.2.0-Beta-3")"

if [[ "$ACTUAL_NAME" != "$EXPECTED_NAME" ]]; then
  echo "Unexpected release DMG name: $ACTUAL_NAME" >&2
  exit 1
fi
if [[ "$ACTUAL_URL_NAME" != "$EXPECTED_NAME" ]]; then
  echo "Unexpected release DMG URL name: $ACTUAL_URL_NAME" >&2
  exit 1
fi
if [[ "$ACTUAL_TAG_NAME" != "$EXPECTED_NAME" ]]; then
  echo "Unexpected release tag DMG name: $ACTUAL_TAG_NAME" >&2
  exit 1
fi
if [[ "$ACTUAL_BETA_TAG_NAME" != "SakuraCord-v0.2.0-Beta-3.dmg" ]]; then
  echo "Unexpected beta release tag DMG name: $ACTUAL_BETA_TAG_NAME" >&2
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
if sakuracord_release_dmg_name_from_tag "0.1.0" >/dev/null 2>&1; then
  echo "Invalid release tags must be rejected for DMG names." >&2
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

set +e
VALIDATOR_OUTPUT="$(
  env -u SAKURACORD_RELEASE_TAG -u GITHUB_REF_NAME \
    SAKURACORD_VERSION=0.1.0 \
    "$ROOT_DIR/script/validate_appcast.sh" \
    "$ROOT_DIR/dist/missing-appcast.xml" \
    "$ROOT_DIR/dist/missing-release.dmg" 2>&1
)"
VALIDATOR_STATUS=$?
set -e
if [[ "$VALIDATOR_STATUS" -ne 2 ]]; then
  echo "Missing release tags must stop appcast validation with status 2." >&2
  exit 1
fi
if [[ "$VALIDATOR_OUTPUT" != \
  "SAKURACORD_RELEASE_TAG or GITHUB_REF_NAME must use vMAJOR.MINOR.PATCH or vMAJOR.MINOR.PATCH-Beta-NUMBER." ]]; then
  echo "Unexpected missing release tag validation: $VALIDATOR_OUTPUT" >&2
  exit 1
fi

printf 'Release metadata tests passed.\n'
