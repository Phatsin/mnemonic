#!/usr/bin/env python3
# keygen-xlm.py  –  derive Stellar account-0  (m/44'/148'/0')

# Setup:
#   python -m venv venv && source venv/bin/activate
#   pip install bip_utils stellar-sdk

from bip_utils import (
    Bip39MnemonicValidator, Bip39SeedGenerator,
    Bip32Slip10Ed25519
)
from stellar_sdk import Keypair
import sys

# ────────── INPUT ──────────────────────────────────────────────
mnemonic   = input("Enter your 12/24-word mnemonic: ").strip()
passphrase = input("Passphrase (blank = none): ")

# ────────── VALIDATION ─────────────────────────────────────────
try:
    Bip39MnemonicValidator().Validate(mnemonic)
except ValueError as e:
    print(f"\n❌ Invalid mnemonic: {e}")
    sys.exit(1)

# ────────── BIP-39 SEED ───────────────────────────────────────
seed = Bip39SeedGenerator(mnemonic).Generate(passphrase)

# ────────── DERIVE m/44'/148'/0' (hardened-only path) ─────────
path = "m/44'/148'/0'"
ctx  = Bip32Slip10Ed25519.FromSeedAndPath(seed, path)

# ────────── STELLAR KEYPAIR ───────────────────────────────────
priv_raw = ctx.PrivateKey().Raw().ToBytes()          # 32-byte ed25519 seed
kp       = Keypair.from_raw_ed25519_seed(priv_raw)

# ────────── OUTPUT ────────────────────────────────────────────
print(f"\nPath   : {path}")
print("Public :", kp.public_key)
print("Secret :", kp.secret)
