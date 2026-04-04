#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C
export LANG=C

ARCH="amd64"
SUITE="stable"
RUNS=3
PING_COUNT=4
CONNECT_TIMEOUT=5
MAX_TIME=60

MIRRORS=(
  "deb.debian.org"
  "ftp.se.debian.org"
  "ftp.acc.umu.se"
  "debian.lth.se"
  "mirrors.glesys.net"
  "mirror.zetup.net"
  "ftpmirror1.infania.net"
  "mirror.braindrainlan.nu"
  "debian.mirror.su.se"
)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --suite) SUITE="${2:-}"; shift 2 ;;
    --arch) ARCH="${2:-}"; shift 2 ;;
    --runs) RUNS="${2:-}"; shift 2 ;;
    *) echo "Unknown parameter: $1"; exit 1 ;;
  esac
done

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

is_number() { [[ "${1:-}" =~ ^[0-9]+([.][0-9]+)?$ ]]; }

format_float() { awk -v x="${1:-0}" 'BEGIN { printf "%.0f", x }'; }
format_ms() { awk -v x="${1:-0}" 'BEGIN { printf "%.1f ms", x }'; }
format_s() { awk -v x="${1:-0}" 'BEGIN { printf "%.3f s", x }'; }

human_speed() {
  awk -v b="${1:-0}" 'BEGIN {
    split("B/s KiB/s MiB/s GiB/s", u, " ");
    i=1;
    while (b >= 1024 && i < 4) { b/=1024; i++ }
    printf "%.2f %s", b, u[i];
  }'
}

median() {
  sort -n "$1" | awk '
  { a[NR]=$1 }
  END {
    if (NR==0) { print "NA"; exit }
    if (NR%2) print a[(NR+1)/2]
    else printf "%.6f\n", (a[NR/2]+a[NR/2+1])/2
  }'
}

ping_avg() {
  ping -c "$PING_COUNT" -n "$1" 2>/dev/null \
  | awk -F'=' '/min\/avg/ {split($2,a,"/"); print a[2]}'
}

curl_test() {
  curl -L -o /dev/null -sS \
    --connect-timeout "$CONNECT_TIMEOUT" \
    --max-time "$MAX_TIME" \
    -w '%{time_starttransfer}\t%{time_total}\t%{speed_download}\t%{http_code}\n' \
    "$1" 2>/dev/null || echo -e "NA\tNA\tNA\t000"
}

score() {
  awk -v p="$1" -v t="$2" -v s="$3" '
  BEGIN {
    score=0
    if (p!="NA") score += (100-p)*2
    if (t!="NA") score += (1/t)*50
    if (s!="NA") score += s/1000000
    printf "%.0f\n", score
  }'
}

is_swedish() {
  case "$1" in
    ftp.se.debian.org|ftp.acc.umu.se|debian.lth.se|mirrors.glesys.net|mirror.zetup.net|ftpmirror1.infania.net|mirror.braindrainlan.nu|debian.mirror.su.se)
      return 0 ;;
    *) return 1 ;;
  esac
}

RESULTS="$TMPDIR/results"
: > "$RESULTS"

echo "Testing mirrors..." >&2

for host in "${MIRRORS[@]}"; do
  echo "Testing $host..." >&2

  base="https://${host}/debian"
  small="$base/dists/${SUITE}/main/binary-${ARCH}/Packages.gz"
  large="$base/dists/${SUITE}/main/Contents-${ARCH}.gz"

  ping="$(ping_avg "$host" || echo NA)"

  for i in $(seq 1 $RUNS); do
    curl_test "$small" >> "$TMPDIR/small"
    curl_test "$large" >> "$TMPDIR/large"
  done

  ttfb=$(awk '{print $1}' "$TMPDIR/small" | median /dev/stdin)
  total=$(awk '{print $2}' "$TMPDIR/large" | median /dev/stdin)
  speed=$(awk '{print $3}' "$TMPDIR/large" | median /dev/stdin)

  sc=$(score "$ping" "$ttfb" "$speed")

  echo -e "$sc\t$host\t$ping\t$ttfb\t$speed\t$base" >> "$RESULTS"

  : > "$TMPDIR/small" "$TMPDIR/large"
done

sort -nr "$RESULTS" > "$TMPDIR/sorted"

echo
printf "%-4s %-6s %-30s %-10s %-10s %-15s\n" "RANK" "SCORE" "HOST" "PING" "TTFB" "SPEED"
echo "-----------------------------------------------------------------------"

rank=1
while read -r line; do
  host=$(echo "$line" | cut -f2)
  ping=$(echo "$line" | cut -f3)
  ttfb=$(echo "$line" | cut -f4)
  speed=$(echo "$line" | cut -f5)

  marker=""
  [[ $rank -eq 1 ]] && marker="<<< BEST"

  printf "%-4s %-6s %-30s %-10s %-10s %-15s %s\n" \
    "$rank" \
    "$(format_float "$(echo "$line" | cut -f1)")" \
    "$host" \
    "$(format_ms "$ping")" \
    "$(format_s "$ttfb")" \
    "$(human_speed "$speed")" \
    "$marker"

  rank=$((rank+1))
done < "$TMPDIR/sorted"

best=$(head -n1 "$TMPDIR/sorted")
best_host=$(echo "$best" | cut -f2)
best_base=$(echo "$best" | cut -f6)

echo
echo "Best overall:"
echo "deb $best_base $SUITE main contrib non-free non-free-firmware"

while read -r line; do
  host=$(echo "$line" | cut -f2)
  if is_swedish "$host"; then
    base=$(echo "$line" | cut -f6)
    echo
    echo "Best Swedish mirror:"
    echo "deb $base $SUITE main contrib non-free non-free-firmware"
    break
  fi
done < "$TMPDIR/sorted"