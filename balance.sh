#!/usr/bin/env bash
# balance.sh — Query BTC, ETH, SOL, XRP, XLM balances with public APIs
# chmod +x balance.sh && ./balance.sh

# ── ADDRESSES ────────────────────────────────────────────────────────────────
BTC_ADDR="bc1qyepl4nlufak200sxc04k8ynsug4wvksdhzd7x6"
ETH_ADDR="0x5A205785490ec581C15a351355B9aA3340F6EBF3"
SOL_ADDR="7WeSqB1K5PE67sViVUWE4dYTpsdN5FRF3ZjZdWLqTajQ"
XRP_ADDR="rnrqyM7kS6wmC5demJm9vrfdN2vLgS8LfY"
XLM_ADDR="GBK2QM6QR6FYLOSAKM3ASHU4J4H3Q2Q44DM3FN5LGXNPMCOESJTCOPMA"

# ── API KEYS (only ETH needs one) ────────────────────────────────────────────
ETHERSCAN_API_KEY="freekey"

printf "📡 Checking balances …\n\n"

# ── BTC via Blockstream ──────────────────────────────────────────────────────
printf "# ── BTC via Blockstream ──────────────────────────────────────────────────────\n"
printf "BTC [$BTC_ADDR] : "
curl -s "https://blockstream.info/api/address/$BTC_ADDR" |
    jq -r '.chain_stats.funded_txo_sum - .chain_stats.spent_txo_sum' |
    awk '{printf "%.8f\n", $1/100000000}'

printf "\n"
# ── ETH via Cloudflare Ethereum Gateway ──────────────────────────────────────
printf "# ── ETH via Cloudflare Ethereum Gateway ──────────────────────────────────────\n"
printf "ETH [$ETH_ADDR] : "
BAL_HEX=$(curl -s -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":1,"method":"eth_getBalance","params":["'"$ETH_ADDR"'", "latest"]}' \
    https://cloudflare-eth.com | jq -r '.result')

BAL_DEC=$(printf "%f" "$(printf "ibase=16; ${BAL_HEX#0x}" | bc)")
printf "%.6f\n" "$(printf "$BAL_DEC / 1e18" | bc -l)"

printf "\n"
# ── ETH & ERC-20 Tokens via Ethplorer ────────────────────────────────────────
printf "# ── ETH & ERC-20 Tokens via Ethplorer ────────────────────────────────────────\n"
printf "ETH [$ETH_ADDR] : "
# Use Ethplorer API (apiKey=freekey is usable for testing)
ETHPLORER_JSON=$(curl -s "https://api.ethplorer.io/getAddressInfo/$ETH_ADDR?apiKey=$ETHERSCAN_API_KEY")

# 1. Fetch ETH balance (Native coin)
BAL_ETH=$(printf "$ETHPLORER_JSON" | jq -r '.ETH.balance')
printf "%.6f\n" "$BAL_ETH"

# 2. (The part you wanted) Loop to fetch "all tokens"
# Filter for tokens with a balance > 0

printf "$ETHPLORER_JSON" | jq -r '
    .tokens[]? | 
    select(.balance and .balance > 0) |
    [
      .tokenInfo.symbol,
      (.balance / pow(10; (.tokenInfo.decimals | tonumber)))
    ] | @tsv
' | while IFS=$'\t' read -r symbol balance; do
    printf "↳ %-20s : %s\n" "$symbol" "$balance"
done

printf "\n"
# ── SOL (Native) via Solana RPC ──────────────────────────────────────────────
printf "# ── SOL (Native) via Solana RPC ──────────────────────────────────────────────\n"

# Download Solana Token List (one time)
if [ ! -f solana.tokenlist.json ]; then
    curl -s https://raw.githubusercontent.com/solana-labs/token-list/main/src/tokens/solana.tokenlist.json > solana.tokenlist.json
fi

# Function to find token name from mint address
get_token_info() {
    MINT="$1"

    RESULT=$(jq -r --arg MINT "$MINT" '
        [(.tokens[] | select(.address == $MINT) |
        "\(.symbol) (\(.name))")][0]
        ' solana.tokenlist.json)

    if [ -z "$RESULT" ] || [ "$RESULT" == "null" ]; then
        printf "UNKNOWN"
    else
        printf "$RESULT"
    fi
}

printf "SOL [$SOL_ADDR] : "
curl -s "https://api.mainnet-beta.solana.com" \
    -H "Content-Type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getBalance\",\"params\":[\"$SOL_ADDR\"]}" |
    jq -r '.result.value' |
    awk '{printf "%.9f\n", $1/1000000000}'

# Fetch all SPL token accounts
curl -s "https://api.mainnet-beta.solana.com" \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc":"2.0",
        "id":1,
        "method":"getTokenAccountsByOwner",
        "params":[
            "'$SOL_ADDR'",
            {"programId": "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"},
            {"encoding": "jsonParsed"}
        ]
    }' | jq -c '.result.value[]' | while read account; do
    
    MINT=$(printf $account | jq -r '.account.data.parsed.info.mint')
    AMOUNT=$(printf $account | jq -r '.account.data.parsed.info.tokenAmount.uiAmountString')
    
    # Skip if balance is 0
    if [ "$AMOUNT" != "0" ] && [ "$AMOUNT" != "0.0" ]; then
        TOKEN_INFO=$(get_token_info "$MINT" | tr -d '\n\r')
        printf "↳ %-20s : %s\n" "$TOKEN_INFO" "$AMOUNT"
    fi
done

printf "\n"
# ── XRP via Ripple API ───────────────────────────────────────────────────────
printf "# ── XRP via Ripple API ───────────────────────────────────────────────────────\n"

NODE="https://s1.ripple.com:51234/"

printf "XRP [$XRP_ADDR] : "

# 1. Fetch XRP balance (Native coin)
read -r -d '' INFO_PAYLOAD <<-EOF
{"method": "account_info", "params":[{"account":"$XRP_ADDR","ledger_index":"validated","strict":true}]}
EOF

resp=$(curl -s -X POST -H "Content-Type: application/json" \
    --data "$INFO_PAYLOAD" "$NODE")

bal=$(printf "$resp" | jq -r '.result.account_data.Balance' 2>/dev/null)

if [[ "$bal" =~ ^[0-9]+$ ]]; then
    bal_xrp=$(printf "scale=6; $bal/1000000" | bc)
    printf "$bal_xrp XRP\n"
else
    printf "Account not found (or not activated)\n"
fi

# 2. Fetch other coin balances (Trust Lines)
read -r -d '' LINES_PAYLOAD <<-EOF
{"method": "account_lines", "params":[{"account":"$XRP_ADDR","ledger_index":"validated"}]}
EOF

LINES_RESP=$(curl -s -X POST -H "Content-Type: application/json" \
    --data "$LINES_PAYLOAD" "$NODE")

printf "$LINES_RESP" | jq -r '
    .result.lines[]? |
    select(.balance != "0") |
    # ส่งข้อมูลดิบ 2 ค่า (Currency Code และ Balance)
    "\(.currency) \(.balance)"' |

while read -r currency balance; do
    symbol=$currency
    # Check if "currency" is a 40-character Hex code
    if [[ ${#currency} -eq 40 && "$currency" != *[^0-9A-Fa-f]* ]]; then
        # If yes, convert Hex to ASCII and trim null characters
        symbol=$(printf "$currency" | xxd -r -p | tr -d '\0')
    fi

    printf "↳ %-20s : %s\n" "$symbol" "$balance"
done

printf "\n"
# ── XLM via Horizon (Stellar) API ────────────────────────────────────────────
printf "# ── XLM via Horizon (Stellar) API ────────────────────────────────────────────\n"
printf "XLM [$XLM_ADDR] : "

# 1. Fetch data from Horizon API (one time)
XLM_JSON=$(curl -s "https://horizon.stellar.org/accounts/$XLM_ADDR")

# 2. Check if there is balance data
if ! printf "$XLM_JSON" | jq -e '.balances' > /dev/null; then
    printf "Account not found or no balance data."
else
    # 3. Fetch and display XLM (Native) first
    NATIVE_AMOUNT=$(printf "$XLM_JSON" | jq -r '.balances[] | select(.asset_type == "native") | .balance')
    
    if [[ -z "$NATIVE_AMOUNT" || "$NATIVE_AMOUNT" == "null" ]]; then
        printf "0.0000000"
    else
        printf "%.7f\n" "$NATIVE_AMOUNT"
    fi

    # 4. Fetch and display other tokens
    printf "$XLM_JSON" | jq -c '.balances[] | select(.asset_type != "native")' | while read balance_entry; do
      
    BALANCE=$(printf "$balance_entry" | jq -r '.balance')

    # Skip if balance is 0
    # if [[ "$BALANCE" == "0" || "$BALANCE" == "0.0000000" ]]; then
    #     continue
    # fi

    # Fetch the token name (asset_code)
    ASSET_CODE=$(printf "$balance_entry" | jq -r '.asset_code')

    printf "↳ %-20s : %s\n" "$ASSET_CODE" "$BALANCE"

    done
fi

printf "\n"
printf "✅ Done"
