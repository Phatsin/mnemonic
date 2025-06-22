#!/usr/bin/env python3
"""
xrp_tx_submit.py
Reads a pre-signed XRP transaction blob from file → submits it to the XRPL network → prints the response.
Useful for offline signing workflows or hardware wallet integrations.
"""

from xrpl.clients import JsonRpcClient
import sys, json

# ── XRPL fullnode endpoint (public) ────────────────────────────────
JSON_RPC = "https://s1.ripple.com:51234/"

# ── Read the signed transaction blob from file ─────────────────────
with open("xrp_signed_blob.txt") as f:
    blob = f.read().strip()

# ── Initialize client and submit the transaction ───────────────────
client = JsonRpcClient(JSON_RPC)

# Submit the signed blob using the 'submit' method
resp = client.request({
    "method": "submit",
    "params": [{"tx_blob": blob}]
}).result

# ── Handle any submission errors ───────────────────────────────────
if "error" in resp:
    print(f"❌ Error: {resp['error']}")
    sys.exit(1)

# ── Pretty-print the full JSON response ────────────────────────────
print(json.dumps(resp, indent=2))
