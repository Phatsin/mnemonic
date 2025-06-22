# python3 -m venv venv
# source venv/bin/activate
# pip install bip_utils
# sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
# sh -c "$(curl -sSfL https://release.solana.com/stable/install)"

from bip_utils import Bip39SeedGenerator, Bip44, Bip44Coins, Bip44Changes

mnemonic = "leaf quantum despair setup express filter tail hire real concert buffalo check income hub loop sort toilet tell people seat palace repair neck mail"
passphrase = "test"
seed_bytes = Bip39SeedGenerator(mnemonic).Generate(passphrase)

wallet = (
    Bip44.FromSeed(seed_bytes, Bip44Coins.SOLANA)
    .Purpose()
    .Coin()
    .Account(0)
    .Change(Bip44Changes.CHAIN_EXT)
    .AddressIndex(0)
)

print("Derivation path  : m/44'/501'/0'/0'/0'")
print("Address          :", wallet.PublicKey().ToAddress())
print("Public Key       :", wallet.PublicKey().RawCompressed().ToHex())
print("Private Key      :", wallet.PrivateKey().Raw().ToHex())