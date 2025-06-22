#!/usr/bin/env bash
# xrp_tx_watch.sh
# ── XRP Transaction Watcher ───────────────────────────────────────
# Usage: ./xrp_watch_tx.sh <tx_hash>
#        Provide the transaction hash (64-char hex) to check its status
#        from the XRPL fullnode endpoint.

NODE="https://s1.ripple.com:51234/"  # XRPL Fullnode JSON-RPC endpoint
TX="$1"  # TX = Transaction Hash passed as the first CLI argument

# Check if TX hash was provided; if not, print usage and exit
[[ -z "$TX" ]] && {
    echo "❌ Missing transaction hash"
    echo "Usage: $0 <tx_hash>"
    exit 1
}

while true; do
    payload=$(cat <<EOF
{"method":"tx","params":[{"transaction":"$TX","binary":false}]}
EOF
)
    resp=$(curl -s -X POST -H "Content-Type: application/json" \
        --data "$payload" "$NODE")

    validated=$(echo "$resp" | jq -r '.result.validated // empty')

    if [[ -z "$validated" ]]; then
        echo "📡 TX not found yet …"; sleep 4; continue
    fi

    if [[ "$validated" == "true" ]]; then
        # Check if the transaction was successfully applied to the ledger
        # 'tesSUCCESS' means "Transaction Engine Success" (i.e. transaction is valid and finalized)
        if [[ "$status" == "tesSUCCESS" ]]; then
            ledger=$(echo "$resp" | jq -r '.result.ledger_index')
            echo "✅ VALIDATED in ledger $ledger"
        else
            echo "❌ Failed – engine_result: $status"
        fi
        echo "$resp" | jq
        break
    else
        echo "⏳ Seen but not validated – keep waiting"; sleep 4
    fi
done
