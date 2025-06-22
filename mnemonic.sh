#!/bin/bash
# mnemonic.sh – Generate a valid 12 or 24-word BIP-39 mnemonic with optional passphrase
# chmod +x mnemonic.sh
# ./mnemonic.sh [-w 12|24]

set -euo pipefail

# ─── Wordlist ───────────────────────────────
WORDLIST="./english.txt"
[[ -f $WORDLIST ]] || curl -sSLo "$WORDLIST" \
    https://raw.githubusercontent.com/bitcoin/bips/master/bip-0039/english.txt

# ─── Parse CLI Argument -w or --words ───────
WORDCOUNT=12
while [[ $# -gt 0 ]]; do
  case $1 in
    -w|--words)
      WORDCOUNT="$2"; shift 2;;
    *) echo "Usage: $0 [-w 12|24]"; exit 1;;
  esac
done

if [[ "$WORDCOUNT" == "24" ]]; then
  ENT_BYTES=32; CS_BITS=8
elif [[ "$WORDCOUNT" == "12" ]]; then
  ENT_BYTES=16; CS_BITS=4
else
  echo "❌ Word count must be 12 or 24"; exit 1
fi

# ─── Generate entropy ───────────────────────
echo "# STEP-1 : Generate $((ENT_BYTES*8))-bit entropy"
ENT_HEX=$(openssl rand -hex "$ENT_BYTES")
echo "Entropy (HEX): $ENT_HEX"
echo

# ─── Convert hex to binary ──────────────────
hex2bin() {
  local out=""
  for ((j=0; j<${#1}; j++)); do
    case ${1:j:1} in
      0) out+=0000;; 1) out+=0001;; 2) out+=0010;; 3) out+=0011;;
      4) out+=0100;; 5) out+=0101;; 6) out+=0110;; 7) out+=0111;;
      8) out+=1000;; 9) out+=1001;; a|A) out+=1010;; b|B) out+=1011;;
      c|C) out+=1100;; d|D) out+=1101;; e|E) out+=1110;; f|F) out+=1111;;
    esac
  done
  echo "$out"
}

ENT_BIN=$(hex2bin "$ENT_HEX")
echo "# STEP-2 : Convert to binary"
echo "Entropy (BIN, ${#ENT_BIN} bits):"
echo "$ENT_BIN"
echo

# ─── SHA-256 checksum ───────────────────────
SHA256_HEX=$(echo -n "$ENT_HEX" | xxd -r -p | openssl dgst -sha256 -hex | awk '{print $2}')

N1=$(printf '%s' "${SHA256_HEX:0:1}" | tr '[:lower:]' '[:upper:]')
N2=$(printf '%s' "${SHA256_HEX:1:1}" | tr '[:lower:]' '[:upper:]')

nibble2bin() {
  case $1 in
    0) echo 0000;; 1) echo 0001;; 2) echo 0010;; 3) echo 0011;;
    4) echo 0100;; 5) echo 0101;; 6) echo 0110;; 7) echo 0111;;
    8) echo 1000;; 9) echo 1001;; A) echo 1010;; B) echo 1011;;
    C) echo 1100;; D) echo 1101;; E) echo 1110;; F) echo 1111;;
  esac
}

if [[ $CS_BITS == 4 ]]; then
  CS_BIN=$(nibble2bin "$N1")
else                   # 24-word → 8-bit checksum
  CS_BIN="$(nibble2bin "$N1")$(nibble2bin "$N2")"
fi

echo "# STEP-3 : Build ${CS_BITS}-bit checksum"
echo "SHA-256(entropy): $SHA256_HEX"
echo "Checksum (BIN):   $CS_BIN"
echo

# ─── Combine entropy and checksum ───────────
FULL_BIN="${ENT_BIN}${CS_BIN}"
echo "# STEP-4 : ${#FULL_BIN}-bit stream (entropy + checksum)"
echo "$FULL_BIN"
echo

# ─── Slice into 11-bit segments ─────────────
declare -a MNEMONIC
WORD_TOTAL=$((WORDCOUNT))
echo "# STEP-5 : Slice 11-bit → index → word"
printf "%-4s %-13s %-7s %s\n" "Idx" "11-bit chunk" "Dec" "Word"
echo

for ((i=0; i<WORD_TOTAL; i++)); do
  SEG=${FULL_BIN:$((i*11)):11}
  IDX=$((2#$SEG))
  WORD=$(sed -n "$((IDX+1))p" "$WORDLIST")
  MNEMONIC[$i]=$WORD
  printf "%-4d %-13s %-7d %s\n" "$i" "$SEG" "$IDX" "$WORD"
done

echo
echo "# STEP-6 : Final $WORDCOUNT-word mnemonic"
MNEMONIC_STR="${MNEMONIC[*]}"
echo "$MNEMONIC_STR"
echo

# ─── Optional Passphrase (menu loop) ────────────────
SUGGESTED_PASS=$(openssl rand -base64 12)

while true; do
  echo "🔐 Suggested passphrase: $SUGGESTED_PASS"
  echo "  1) Use suggested passphrase"
  echo "  2) Enter a custom passphrase"
  echo "  3) No passphrase"
  read -r -n1 -p "Select [1-3] : " CHOICE
  echo
  case "$CHOICE" in
    1)
       PASSPHRASE="$SUGGESTED_PASS"
       echo "(Using suggested passphrase)"
       break
       ;;
    2)
       read -r -p "Enter your passphrase: " PASSPHRASE
       echo "(Using custom passphrase)"
       break
       ;;
    3|"")
       PASSPHRASE=""
       echo "(No passphrase will be used)"
       break
       ;;
    *)
       echo "❌ Invalid choice — please press 1, 2, or 3."
       ;;
  esac
done

# ─── PBKDF2 → Seed ───────────────────────────
echo -e "\n# STEP-7 : Seed 512-bit (PBKDF2-HMAC-SHA512, 2048 rounds)"

SEED=$(python3 -c "
import hashlib, unicodedata, binascii
mnemonic = '''$MNEMONIC_STR'''
passphrase = '''$PASSPHRASE'''
salt = 'mnemonic' + passphrase
mn = unicodedata.normalize('NFKD', mnemonic).encode('utf-8')
salt = unicodedata.normalize('NFKD', salt).encode('utf-8')
seed = hashlib.pbkdf2_hmac('sha512', mn, salt, 2048)
print(binascii.hexlify(seed).decode())
")

echo -e "\nSeed (hex):\n$SEED\n"
