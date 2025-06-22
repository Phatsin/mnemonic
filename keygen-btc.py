#!/usr/bin/env python3
# keygen-btc.py  –  derive the first Bitcoin key-pair (m/44'/0'/0'/0/0)

# python -m venv venv && source venv/bin/activate
# pip install bip_utils
# Usage: python keygen-btc.py

from bip_utils import (
    Bip39SeedGenerator, Bip39MnemonicValidator,
    Bip84, Bip84Coins, Bip44Changes,
    WifEncoder
)
from wif_encode import wif_compressed_from_raw, wif_uncompressed_from_raw

# ─── INPUT ─────────────────────────────────────────────────────
print("Enter your 12- or 24-word mnemonic:")
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

# ─── Generate seed & derive Bitcoin wallet (m/84'/0'/0'/0/0) ──
seed = Bip39SeedGenerator(mnemonic).Generate(passphrase)

wallet = (
    Bip84.FromSeed(seed, Bip84Coins.BITCOIN)  # 84'/0'
         .Purpose()
         .Coin()
         .Account(0)                          # 0'
         .Change(Bip44Changes.CHAIN_EXT)      # 0
         .AddressIndex(0)                     # 0
)

# ─── Convert private-key → WIF (mainnet) ──────────────────────
raw_priv = wallet.PrivateKey().Raw().ToBytes()
wif_compressed   = wif_compressed_from_raw(raw_priv, mainnet=True)
wif_uncompressed = wif_uncompressed_from_raw(raw_priv, mainnet=True)

# ─── OUTPUT ───────────────────────────────────────────────────
print("\nDerivation path  : m/44'/0'/0'/0/0")
print("BTC Address      :", wallet.PublicKey().ToAddress())      # 1...
print("Public Key (hex) :", wallet.PublicKey().RawCompressed().ToHex())
print("Private Key (hex):", wallet.PrivateKey().Raw().ToHex())
print("Private Key (WIF, compressed)  :", wif_compressed)
print("Private Key (WIF, uncompressed):", wif_uncompressed)
