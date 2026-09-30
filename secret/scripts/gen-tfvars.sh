#!/usr/bin/env bash
set -euo pipefail

: "${NAMESPACE:?NAMESPACE required}"
: "${NAME:?NAME required}"
: "${VALUE:?VALUE required}"
OUT="${OUT:-terraform.tfvars}"

cat <<EOF > "$OUT"
namespace = "${NAMESPACE}"
name      = "${NAME}"
value = {
EOF

IFS=',' read -ra PAIRS <<< "$VALUE"
for pair in "${PAIRS[@]}"; do
  pair="$(echo "$pair" | xargs)"
  [ -z "$pair" ] && continue
  key="$(echo "${pair%%=*}" | xargs)"
  val="$(echo "${pair#*=}" | xargs)"
  echo "  \"${key}\" = \"${val}\"" >> "$OUT"
done

echo "}" >> "$OUT"
