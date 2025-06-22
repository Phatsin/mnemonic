# python -m venv venv && source venv/bin/activate
# pip install bip_utils
# Usage: python keygen-xrp.py

from bip_utils import (
    Bip39SeedGenerator,
    Bip39MnemonicValidator,
    Bip44,
    Bip44Coins,
    Bip44Changes
)
from xrpl.core.addresscodec import encode_seed
import sys

# ------------------------------------------------------------------
# 🔑 INPUT
print("Enter your 12 or 24-word mnemonic:")
mnemonic = input("> ").strip()

print("Enter passphrase (leave blank if none):")
passphrase = input("> ")

# ─── Validate mnemonic ────────────────────────────────────────
try:
    Bip39MnemonicValidator().Validate(mnemonic)
except ValueError as e:
    print(f"\n❌ Invalid mnemonic: {e}")
    print("    • Check spelling for each word")
    print("    • Ensure you have exactly 12 or 24 words\n")
    sys.exit(1)

# ------------------------------------------------------------------
# 🌱 GENERATE SEED
seed_bytes = Bip39SeedGenerator(mnemonic).Generate(passphrase)
entropy16 = seed_bytes[:16]    

# ------------------------------------------------------------------
# 🗝️  DERIVE XRP WALLET  m/44'/144'/0'/0/0
wallet = (
    Bip44.FromSeed(seed_bytes, Bip44Coins.RIPPLE)   # 44' / 144'
         .Purpose()                                 # 44'
         .Coin()                                    # 144'
         .Account(0)                                # 0'
         .Change(Bip44Changes.CHAIN_EXT)            # 0  (non-hardened for Ripple)
         .AddressIndex(0)                           # 0
)

# ─── Convert private → family-seed ────────────
family_seed = encode_seed(entropy16, "ed25519")

print("Derivation path  : m/44'/144'/0'/0/0")
print("XRP Address      :", wallet.PublicKey().ToAddress())          # r... (classic)
print("XRP Secret       :", family_seed)
print("Public Key (hex) :", wallet.PublicKey().RawCompressed().ToHex())
print("Private Key (hex):", wallet.PrivateKey().Raw().ToHex())
