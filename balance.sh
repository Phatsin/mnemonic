#!/usr/bin/env bash
# check-balance.sh — Query BTC, ETH, SOL, XRP, XLM balances with public APIs
# chmod +x check-balance.sh && ./check-balance.sh

# ── YOUR ADDRESSES ───────────────────────────────────────────────────────────
BTC_ADDR="bc1qyepl4nlufak200sxc04k8ynsug4wvksdhzd7x6"
ETH_ADDR="0x5A205785490ec581C15a351355B9aA3340F6EBF3"
SOL_ADDR="7WeSqB1K5PE67sViVUWE4dYTpsdN5FRF3ZjZdWLqTajQ"
XRP_ADDR="rpYfjZnV7dse1NAoes9ykLrYGYb9kPjVEy"
XLM_ADDR="GBHUVNEHLMB5YJZHESDQ2HN22KBQ7KIVYLIK347AEJFQLEATHHPVKSKJ"

# ── API KEYS (only ETH needs one) ────────────────────────────────────────────
ETHERSCAN_API_KEY="your_etherscan_api_key"

echo "📡 Checking balances …"

# ── BTC via Blockstream ──────────────────────────────────────────────────────
echo -n "BTC [$BTC_ADDR] : "
curl -s "https://blockstream.info/api/address/$BTC_ADDR" |
 jq -r '.chain_stats.funded_txo_sum - .chain_stats.spent_txo_sum' |
 awk '{printf "%.8f BTC\n", $1/100000000}'

# ── ETH via Cloudflare Ethereum Gateway ─────────────────────────────
echo -n "ETH [$ETH_ADDR] : "
BAL_HEX=$(curl -s -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"eth_getBalance","params":["'"$ETH_ADDR"'", "latest"]}' \
  https://cloudflare-eth.com | jq -r '.result')

BAL_DEC=$(printf "%f" "$(echo "ibase=16; ${BAL_HEX#0x}" | bc)")
printf "%.6f ETH\n" "$(echo "$BAL_DEC / 1e18" | bc -l)"

# ── SOL via Solana RPC ───────────────────────────────────────────────────────
echo -n "SOL [$SOL_ADDR] : "
curl -s "https://api.mainnet-beta.solana.com" \
 -H "Content-Type: application/json" \
 -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getBalance\",\"params\":[\"$SOL_ADDR\"]}" |
 jq -r '.result.value' |
 awk '{printf "%.9f SOL\n", $1/1000000000}'

# ── XRP via XRPScan API ──────────────────────────────────────────────────────
NODE="https://s1.ripple.com:51234/"

echo -n "XRP [$XRP_ADDR] : "

read -r -d '' PAYLOAD <<-EOF
{"method": "account_info", "params":[{"account":"$XRP_ADDR","ledger_index":"validated","strict":true}]}
EOF

resp=$(curl -s -X POST -H "Content-Type: application/json" \
     --data "$PAYLOAD" "$NODE")

bal=$(echo "$resp" | jq -r '.result.account_data.Balance' 2>/dev/null)

if [[ "$bal" =~ ^[0-9]+$ ]]; then
  bal_xrp=$(echo "scale=6; $bal/1000000" | bc)
  echo "$bal_xrp XRP"
else
  echo "Unable to fetch balance (account not found or node issue)"
fi

# ── XLM via Horizon (Stellar) API ────────────────────────────────────────────
echo -n "XLM [$XLM_ADDR] : "
XLM_JSON=$(curl -s "https://horizon.stellar.org/accounts/$XLM_ADDR")
XLM_BALANCE=$(echo "$XLM_JSON" | jq -e '.balances[]? | select(.asset_type=="native") | .balance' 2>/dev/null)

if [[ -n "$XLM_BALANCE" ]]; then
  printf "%.7f XLM\n" "$XLM_BALANCE"
else
  echo "Account not found or no balance"
fi

echo "✅ Done"
