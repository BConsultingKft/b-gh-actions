#!/usr/bin/env bash
# Tests for schema-gate/check.sh. Run: bash schema-gate/tests/test.sh
set -uo pipefail

CHECK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/check.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0

# make_dir <name> <file>... : creates $WORK/<name> with empty files
make_dir() {
  local dir="$WORK/$1"
  shift
  mkdir -p "$dir"
  local f
  for f in "$@"; do
    : > "$dir/$f"
  done
  echo "$dir"
}

# expect <pass|fail> <description> <env> <dir> <applied> [expected output substring]
expect() {
  local want="$1" desc="$2" env="$3" dir="$4" applied="$5" needle="${6:-}"
  local out rc got
  out="$(GITHUB_OUTPUT="$WORK/output" GITHUB_STEP_SUMMARY="$WORK/summary" \
    bash "$CHECK" "$env" "$dir" "$applied" 2>&1)"
  rc=$?
  [ "$rc" -eq 0 ] && got=pass || got=fail
  if [ "$got" = "$want" ] && { [ -z "$needle" ] || [[ "$out" == *"$needle"* ]]; }; then
    pass=$((pass + 1))
    echo "ok   - $desc"
  else
    fail=$((fail + 1))
    echo "FAIL - $desc (wanted $want${needle:+ with '$needle'}, got $got rc=$rc)"
    echo "$out" | sed 's/^/       /'
  fi
}

d=$(make_dir baseline V1__baseline.sql)
expect pass "baseline only" dev "$d" "1"

d=$(make_dir ts V1__baseline.sql V20261029143000__BO-970_a.sql V20261030091500__BO-971_b.sql)
expect pass "timestamp versions applied" dev "$d" "1,20261029143000,20261030091500"
expect fail "newest timestamp not applied" dev "$d" "1,20261029143000" \
  "needs schema version 20261030091500 (V20261030091500__BO-971_b.sql)"
expect fail "prod message points at deploy-to-prod" prod "$d" "1,20261029143000" "deploy-to-prod"
expect pass "out-of-order: older version missing, max applied" dev "$d" "1,20261030091500"
expect fail "empty applied list" dev "$d" "" "list is empty"
rm -f "$WORK/output"
expect pass "newline/whitespace separated list" dev "$d" $' 1\n20261029143000 ,\n 20261030091500\n'

grep -q '^required-version=20261030091500$' "$WORK/output" \
  && grep -q '^env-max-version=20261030091500$' "$WORK/output" \
  && { pass=$((pass + 1)); echo "ok   - outputs written"; } \
  || { fail=$((fail + 1)); echo "FAIL - outputs written"; cat "$WORK/output"; }

d=$(make_dir underscore V1__baseline.sql V1_1__x.sql)
expect pass "V1_1 matches flyway 1.1" dev "$d" "1,1.1"
expect fail "V1_1 not applied" dev "$d" "1" "needs schema version 1.1"

d=$(make_dir zeros V001__baseline.sql)
expect pass "V001 matches 1" dev "$d" "1"
expect pass "1 matches 1.0" dev "$(make_dir zeros2 V1__baseline.sql)" "1.0"

d=$(make_dir order V1_9__a.sql V1_10__b.sql)
expect pass "1.10 > 1.9 (numeric, not lexical)" dev "$d" "1.10"
expect fail "1.9 is not the max" dev "$d" "1.9" "needs schema version 1.10"

d=$(make_dir repeatable V1__baseline.sql R__seed.sql U2__undo.sql README.md)
expect pass "R__/U__/other files ignored" dev "$d" "1"

d=$(make_dir badname V1__baseline.sql Vabc__x.sql)
expect fail "invalid version in filename" dev "$d" "1" "invalid migration version 'abc'"
d=$(make_dir nosep V1__baseline.sql V2.sql)
expect fail "filename without __" dev "$d" "1" "invalid migration filename 'V2.sql'"

expect fail "missing migrations dir" dev "$WORK/does-not-exist" "1" "no migrations directory"
d=$(make_dir empty)
expect fail "no V files" dev "$d" "1" "no V*.sql migrations found"

d=$(make_dir badlist V1__baseline.sql)
expect fail "garbage in applied list" dev "$d" "1,foo" "unexpected entry 'foo'"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
