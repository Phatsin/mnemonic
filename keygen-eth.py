# python -m venv venv && source venv/bin/activate
# pip install bip_utils
# Usage: python keygen-eth.py

from bip_utils import (
    Bip39SeedGenerator,
    Bip39MnemonicValidator,
    Bip44,
    Bip44Coins,
    Bip44Changes
)
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

# ------------------------------------------------------------------
# 🗝️  DERIVE ETH WALLET m/44'/60'/0'/0/0
wallet = (
    Bip44.FromSeed(seed_bytes, Bip44Coins.ETHEREUM)
         .Purpose()                  # 44'
         .Coin()                     # 60' for Ethereum
         .Account(0)                 # 0'
         .Change(Bip44Changes.CHAIN_EXT)  # 0
         .AddressIndex(0)           # 0
)

# ------------------------------------------------------------------
# 🧾 OUTPUT
print("Derivation path  : m/44'/60'/0'/0/0")
print("ETH Address       :", wallet.PublicKey().ToAddress())  # Starts with 0x
print("Public Key (hex)  :", wallet.PublicKey().RawUncompressed().ToHex())
print("Private Key (hex) :", wallet.PrivateKey().Raw().ToHex())
