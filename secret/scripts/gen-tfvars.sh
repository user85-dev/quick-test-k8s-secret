#!/usr/bin/env bash
set -euo pipefail

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

parse_value() {
  local value="$1" pair key val
  local IFS=','
  for pair in $value; do
    pair="$(trim "$pair")"
    [ -z "$pair" ] && continue
    key="$(trim "${pair%%=*}")"
    val="$(trim "${pair#*=}")"
    printf '  "%s" = "%s"\n' "$(escape "$key")" "$(escape "$val")"
  done
}

write_tfvars() {
  local namespace="$1" name="$2" value="$3" out_file="$4"
  {
    printf 'namespace = "%s"\n' "$(escape "$namespace")"
    printf 'name      = "%s"\n' "$(escape "$name")"
    printf 'value = {\n'
    parse_value "$value"
    printf '}\n'
  } > "$out_file"
}

assert_tfvars() {
  local desc="$1" ns="$2" name="$3" value="$4" expected="$5" tmp actual
  tmp="$(mktemp)"
  write_tfvars "$ns" "$name" "$value" "$tmp"
  actual="$(cat "$tmp")"
  rm -f "$tmp"
  if [ "$actual" != "$expected" ]; then
    printf 'FAIL: %s\nexpected:\n%s\nactual:\n%s\n' "$desc" "$expected" "$actual" >&2
    return 1
  fi
  printf 'PASS: %s\n' "$desc"
}

self_test() {
  local expected

  expected="$(cat <<'EOF'
namespace = "default"
name      = "app-secret"
value = {
  "secret_msg" = "hello"
  "api_key" = "abc"
}
EOF
)"
  assert_tfvars "basic spaced pairs" "default" "app-secret" "secret_msg=hello, api_key=abc" "$expected"

  expected="$(cat <<'EOF'
namespace = "ns"
name      = "n"
value = {
}
EOF
)"
  assert_tfvars "empty value" "ns" "n" "" "$expected"

  expected="$(cat <<'EOF'
namespace = "ns"
name      = "n"
value = {
  "token" = "abc=def"
}
EOF
)"
  assert_tfvars "value contains equals" "ns" "n" "token=abc=def" "$expected"

  expected="$(cat <<'EOF'
namespace = "ns"
name      = "n"
value = {
  "a" = "1"
  "b" = "2"
}
EOF
)"
  assert_tfvars "extra whitespace" "ns" "n" "  a = 1 ,b= 2  " "$expected"

  expected="$(cat <<'EOF'
namespace = "ns"
name      = "n"
value = {
  "q" = "\"x\""
  "p" = "a\\b"
}
EOF
)"
  assert_tfvars "escapes quotes and backslash" "ns" "n" 'q="x", p=a\b' "$expected"

  printf 'all self-tests passed\n'
}

if [ "${1:-}" = "--self-test" ]; then
  self_test
  exit 0
fi

: "${NAMESPACE:?NAMESPACE required}"
: "${NAME:?NAME required}"
: "${VALUE:?VALUE required}"
OUT="${OUT:-terraform.tfvars}"
write_tfvars "$NAMESPACE" "$NAME" "$VALUE" "$OUT"
