# python3 -m venv venv
# source venv/bin/activate
# pip install bip_utils
# sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
# Usage: python keygen-sol.py

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
# 🗝️  DERIVE ETH WALLET m/44'/501'/0'/0/0
wallet = (

    Bip44.FromSeed(seed_bytes, Bip44Coins.SOLANA)
         .Purpose()                 # 44'
         .Coin()                    # 501'
         .Account(0)                # 0'
         .Change(Bip44Changes.CHAIN_EXT)   # 0'   ← **จบตรงนี้**   
)

# ------------------------------------------------------------------
# 🧾 OUTPUT
print("Derivation path  : m/44'/501'/0'/0'/0'")
print("Address          :", wallet.PublicKey().ToAddress())
print("Public Key       :", wallet.PublicKey().RawCompressed().ToHex())
print("Private Key      :", wallet.PrivateKey().Raw().ToHex())
