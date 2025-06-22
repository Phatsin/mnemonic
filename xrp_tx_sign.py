#!/usr/bin/env python3
"""
## OFFLINE SIGNING SCRIPT ##
xrp_tx_sign.py
Reads 'xrp_tx_template.json' → signs using a secret key (family seed) → writes signed transaction to 'xrp_signed_blob.txt'
Use this script in an offline environment for secure signing of XRP transactions.
"""

from xrpl.core.keypairs import derive_keypair, sign
from xrpl.core.addresscodec import classic_address_to_xaddress
from xrpl.models.transactions import Transaction
import json, getpass, sys

# 1) Load the unsigned transaction template from JSON file
with open("xrp_tx_template.json") as f:
    tx_dict = json.load(f)

# 2) Prompt user to enter the family seed (XRP secret), which must start with 's'
#    Note: If using a mnemonic, you must derive the seed externally beforehand
secret = getpass.getpass("XRP secret / family-seed (e.g. s████): ").strip()
if not secret.startswith("s"):
    print("❌  Invalid secret: must start with 's'")
    sys.exit(1)

# Derive public and private keys from the secret
pub_key, priv_key = derive_keypair(secret)

# 3) Inject the derived public key into the transaction and sign it
tx_dict["SigningPubKey"] = pub_key
tx = Transaction.from_dict(tx_dict)
signed_tx = sign(tx, priv_key)

# 4) Write the signed blob (hex format) to file for online submission
with open("xrp_signed_blob.txt", "w") as f:
    f.write(signed_tx)

print("📝  xrp_signed_blob.txt ready  (copy back to online PC)")
