#!/usr/bin/env python3
"""
xrp_tx_prepare.py
ดึง sequence / fee / lastLedgerSequence จากเครือข่าย
แล้วบันทึก “xrp_tx_template.json” เพื่อนำไปเซ็นแบบออฟไลน์
"""

from xrpl.clients import JsonRpcClient
from xrpl.models.transactions import Payment
from xrpl.utils import xrp_to_drops
import json, time, sys

JSON_RPC = "https://s1.ripple.com:51234/"      # main-net public node
SRC_ADDR  = "rXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"  # บัญชีต้นทาง
DST_ADDR  = "rYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY"  # ผู้รับ
AMT_XRP   = 1.5                                # จำนวน XRP ที่จะส่ง

client = JsonRpcClient(JSON_RPC)

# 1) ข้อมูลบัญชี → sequence ปัจจุบัน
acct_info = client.request({"method": "account_info",
                            "params": [{"account": SRC_ADDR,
                                        "ledger_index": "validated"}]}).result
seq = acct_info["account_data"]["Sequence"]

# 2) ค่า fee ( drops ) จากเครือข่าย
fee_info = client.request({"method": "fee"}).result
fee_drops = fee_info["drops"]["minimum_fee"]

# 3) กำหนด last_ledger_sequence = ledger ปัจจุบัน + 4
ledger_current = client.request({"method": "ledger_current"}).result["ledger_current_index"]
last_ledger = ledger_current + 4

# 4) สร้าง Payment object (ยังไม่เซ็น)
tx = Payment(
    account=SRC_ADDR,
    destination=DST_ADDR,
    amount=str(xrp_to_drops(AMT_XRP)),   # “drops” เป็นสตริง
    fee=fee_drops,
    sequence=seq,
    last_ledger_sequence=last_ledger,
    signing_pub_key="",                  # จะเติมตอนออฟไลน์
    txn_signature=""                     # ""
)

with open("xrp_tx_template.json", "w") as f:
    json.dump(tx.to_dict(), f, indent=2)

print("✅  Saved xrp_tx_template.json  (copy to offline PC)")
