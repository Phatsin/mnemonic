# 🔐 BIP‑39 Mnemonic Generator (Bash)

Generate 12 or 24‑word BIP‑39 mnemonics entirely in **Bash**.  
Supports an optional passphrase and derives the final 512‑bit seed with PBKDF2‑HMAC‑SHA512.

## 🔐 Secure by Design

✅ Generates real, wallet‑grade mnemonics and seeds.  
🛡️ Run the script on an **air‑gapped or offline machine** for maximum security.

## ✨ Features

- BIP‑39 compliant 12 **or** 24‑word generation  
- SHA‑256 entropy checksum  
- Optional passphrase (the “25th word”)  
- 512‑bit seed derivation (PBKDF2‑HMAC‑SHA512, 2048 rounds)  
- Minimal dependencies — Bash, `openssl`, `xxd`, `curl`, `python3`  
- No Internet access required after the word‑list is cached

## 🚀 Usage

```bash
chmod +x mnemonic.sh

# Generate 12-word mnemonic (default)
./mnemonic.sh

# Generate 24-word mnemonic
./mnemonic.sh -w 24
```

You’ll be prompted for an **optional passphrase**.  
Output includes:

* Raw entropy (hex / binary)  
* Mnemonic words  
* Final seed (512‑bit hex)

## 🧪 Optional Solana Derivation (`keygen-sol.py`)

Use these scripts to derive real wallet addresses from your BIP‑39 mnemonic and optional passphrase.

### 🔹 Solana (`keygen-sol.py`)
```bash
python3 -m venv venv
source venv/bin/activate
pip install bip_utils
sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
python keygen-sol.py
```

### 🔸 XRP (keygen-xrp.py)
```bash
python3 -m venv venv
source venv/bin/activate
pip install bip_utils
pip install xrpl-py
python keygen-xrp.py
```

`keygen-xxx.py` reads your mnemonic & passphrase, derives the path  
`m/44'/501'/0'/0'/0'`, and prints the first Solana address, public & private key.

## ⚠️ Warning

This tool can create real wallets. **Handle any generated mnemonic/seed with extreme care.**

Never share your mnemonic, passphrase, or seed. Loss or exposure = loss of funds.  
Use this script **at your own risk**.

---

Created for developers, tinkerers & self‑custody enthusiasts 🛠️
