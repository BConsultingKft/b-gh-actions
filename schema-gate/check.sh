#!/usr/bin/env bash
# Schema gate check: fails if the highest Flyway migration version found in
# <migrations-dir> is not in the list of versions applied on <env>.
#
# Usage: check.sh <env> <migrations-dir> <applied-versions>
#   <applied-versions>: comma- or newline-separated Flyway versions
#                       (value of SSM /bos-<env>-database/schema-versions)
#
# Writes required-version / env-max-version to $GITHUB_OUTPUT and a short
# report to $GITHUB_STEP_SUMMARY when those are set. No AWS calls here.
set -euo pipefail
shopt -s nullglob extglob

if [ "$#" -ne 3 ]; then
  echo "usage: $0 <env> <migrations-dir> <applied-versions>" >&2
  exit 2
fi

ENV_NAME="$1"
MIGRATIONS_DIR="$2"
APPLIED_RAW="$3"

error() {
  echo "::error::schema-gate: $*"
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    printf '### Schema gate (%s): failed\n\n%s\n' "$ENV_NAME" "$*" >> "$GITHUB_STEP_SUMMARY"
  fi
  exit 1
}

# Normalise a Flyway version: "_" -> ".", strip leading zeros per segment,
# drop trailing ".0" segments. 1 == 1.0 == 01, V1_1 == 1.1.
normalize() {
  local v="${1//_/.}" seg out=() i
  IFS=. read -ra segs <<< "$v"
  for seg in "${segs[@]}"; do
    seg="${seg##+(0)}"
    out+=("${seg:-0}")
  done
  i=$(( ${#out[@]} - 1 ))
  while [ "$i" -gt 0 ] && [ "${out[$i]}" = "0" ]; do
    unset 'out[i]'
    i=$(( i - 1 ))
  done
  local IFS=.
  echo "${out[*]}"
}

# Returns 0 if normalised version $1 > $2. Segments are compared as digit
# strings (length first, then lexically), so long timestamps never overflow.
version_gt() {
  local -a a b
  IFS=. read -ra a <<< "$1"
  IFS=. read -ra b <<< "$2"
  local n=$(( ${#a[@]} > ${#b[@]} ? ${#a[@]} : ${#b[@]} )) i x y
  for (( i = 0; i < n; i++ )); do
    x="${a[i]:-0}"
    y="${b[i]:-0}"
    if [ "${#x}" -ne "${#y}" ]; then
      [ "${#x}" -gt "${#y}" ] && return 0 || return 1
    fi
    if [ "$x" != "$y" ]; then
      [[ "$x" > "$y" ]] && return 0 || return 1
    fi
  done
  return 1
}

VERSION_RE='^[0-9]+([._][0-9]+)*$'

# --- Highest version in the submodule -------------------------------------
if [ ! -d "$MIGRATIONS_DIR" ]; then
  error "no migrations directory '$MIGRATIONS_DIR'. Was the b-onsite-database submodule checked out (actions/checkout with submodules: true and the App token)?"
fi

required=""
required_file=""
files=("$MIGRATIONS_DIR"/V*.sql)
for f in "${files[@]}"; do
  name="$(basename "$f")"
  if [[ "$name" != V*__*.sql ]]; then
    error "invalid migration filename '$name' (expected V<version>__<description>.sql)"
  fi
  raw="${name#V}"
  raw="${raw%%__*}"
  if ! [[ "$raw" =~ $VERSION_RE ]]; then
    error "invalid migration version '$raw' in '$name'"
  fi
  v="$(normalize "$raw")"
  if [ -z "$required" ] || version_gt "$v" "$required"; then
    required="$v"
    required_file="$name"
  fi
done

if [ -z "$required" ]; then
  error "no V*.sql migrations found in '$MIGRATIONS_DIR'. Was the b-onsite-database submodule checked out (actions/checkout with submodules: true and the App token)?"
fi

# --- Versions applied on the environment ----------------------------------
applied=()
env_max=""
while IFS= read -r entry; do
  entry="${entry//[[:space:]]/}"
  [ -z "$entry" ] && continue
  if ! [[ "$entry" =~ $VERSION_RE ]]; then
    error "unexpected entry '$entry' in the $ENV_NAME schema-versions list"
  fi
  v="$(normalize "$entry")"
  applied+=("$v")
  if [ -z "$env_max" ] || version_gt "$v" "$env_max"; then
    env_max="$v"
  fi
done <<< "${APPLIED_RAW//,/$'\n'}"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "required-version=$required"
    echo "env-max-version=$env_max"
  } >> "$GITHUB_OUTPUT"
fi

if [ "${#applied[@]}" -eq 0 ]; then
  error "the $ENV_NAME schema-versions list is empty; deploy b-onsite-database to $ENV_NAME first."
fi

for v in "${applied[@]}"; do
  if [ "$v" = "$required" ]; then
    echo "schema-gate: $ENV_NAME has schema version $required ($required_file) applied (latest applied: $env_max)."
    if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
      printf '### Schema gate (%s): passed\n\nRequired version `%s` (%s) is applied; latest applied `%s`.\n' \
        "$ENV_NAME" "$required" "$required_file" "$env_max" >> "$GITHUB_STEP_SUMMARY"
    fi
    exit 0
  fi
done

if [ "$ENV_NAME" = "prod" ]; then
  how="release b-onsite-database and run its deploy-to-prod workflow first"
else
  how="deploy b-onsite-database to $ENV_NAME first"
fi
error "$ENV_NAME is behind. This build needs schema version $required ($required_file), which is not applied on $ENV_NAME (latest applied: $env_max). To fix: $how, or update the db submodule to the schema that $ENV_NAME has."
