#!/bin/sh
set -eu

: "${NAMESPACE:?NAMESPACE required}"
: "${NAME:?NAME required}"
: "${VALUE:?VALUE required}"
OUT="${OUT:-terraform.tfvars}"

cat <<EOF > "$OUT"
namespace = "${NAMESPACE}"
name      = "${NAME}"
value = {
EOF

OLD_IFS="$IFS"
IFS=','
for pair in $VALUE; do
  IFS="$OLD_IFS"
  pair="$(echo "$pair" | xargs)"
  [ -z "$pair" ] && continue
  key="$(echo "${pair%%=*}" | xargs)"
  val="$(echo "${pair#*=}" | xargs)"
  echo "  \"${key}\" = \"${val}\"" >> "$OUT"
  IFS=','
done
IFS="$OLD_IFS"

echo "}" >> "$OUT"
