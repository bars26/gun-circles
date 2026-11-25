#!/usr/bin/env bash
# Runs a full savings circle end to end with three demo keys.
#
#   ./scripts/demo.sh local     # against gnodev (chain-id dev)
#   ./scripts/demo.sh testnet   # against the current gno.land testnet
#
# Keys gun-ayse, gun-mehmet and gun-zeynep must exist in gnokey and be funded.
# GNOKEY_PASSWORD is read from .env.
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; source .env; set +a

NS=g1k0pgsw39lh0a6mama0qh0lxa6vphd4yc2w9gqw
REALM="gno.land/r/$NS/gun"
case "${1:-local}" in
  local)   REMOTE=http://127.0.0.1:26657; CHAIN=dev ;;
  testnet) REMOTE=https://rpc.latest.testnets.gno.land:443; CHAIN=onyx-1 ;;
  *) echo "usage: $0 local|testnet"; exit 1 ;;
esac
PERIOD=${PERIOD:-60}
AMOUNT=${AMOUNT:-100000}   # 0.1 GNOT per round
COLLATERAL=${COLLATERAL:-2}
NAME=${NAME:-Salı günü}

addr() { gnokey list | awk -v n="$1" '$2==n {for(i=1;i<=NF;i++) if($i=="addr:") print $(i+1)}'; }
AYSE=$(addr gun-ayse); MEHMET=$(addr gun-mehmet); ZEYNEP=$(addr gun-zeynep)

call() { # key func send args...
  local key=$1 fn=$2 send=$3; shift 3
  local argv=()
  for a in "$@"; do argv+=(-args "$a"); done
  printf '%s\n' "$GNOKEY_PASSWORD" | gnokey maketx call -pkgpath "$REALM" -func "$fn" \
    ${send:+-send "$send"} "${argv[@]}" \
    -gas-fee 1000000ugnot -gas-wanted 30000000 -broadcast \
    -chainid "$CHAIN" -remote "$REMOTE" -insecure-password-stdin "$key" 2>&1 \
    | grep -E "OK!|TX HASH|Data|Error|error" | sed "s/^/  [$key $fn] /"
}

echo "create circle"
call gun-ayse Create "" "$NAME" "$AMOUNT" "$PERIOD" "$COLLATERAL" 3600 "$AYSE,$MEHMET,$ZEYNEP"
ID=$(gnokey query vm/qeval -data "$REALM.lastID" -remote "$REMOTE" 2>/dev/null | awk '/data:/ {print $2; exit}' | tr -d '()int ')
echo "circle id: $ID"

COLL=$((AMOUNT * COLLATERAL))
for k in gun-ayse gun-mehmet gun-zeynep; do
  echo "join $k"
  if [ "$COLL" -gt 0 ]; then call $k Join "${COLL}ugnot" "$ID"; else call $k Join "" "$ID"; fi
done

for round in 1 2 3; do
  echo "round $round"
  for k in gun-ayse gun-mehmet gun-zeynep; do
    if [ "$round" = 2 ] && [ "$k" = gun-zeynep ] && [ "${SKIP_ZEYNEP_R2:-1}" = 1 ]; then
      echo "  zeynep skips round 2; settling once the round is due"
      until call gun-mehmet Settle "" "$ID" | grep -q "OK!"; do sleep 10; done
      echo "  [gun-mehmet Settle] OK!"
      continue
    fi
    call $k Pay "${AMOUNT}ugnot" "$ID"
  done
done

for k in gun-ayse gun-mehmet gun-zeynep; do
  echo "withdraw $k"
  call $k Withdraw "" "$ID"
done
echo "done: $REALM:c/$ID"
