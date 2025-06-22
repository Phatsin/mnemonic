# wif_encode.py
import hashlib, base58

def _base58check(payload: bytes) -> str:
    checksum = hashlib.sha256(hashlib.sha256(payload).digest()).digest()[:4]
    return base58.b58encode(payload + checksum).decode()

def wif_compressed_from_raw(raw_priv: bytes, mainnet=True) -> str:
    version = b'\x80' if mainnet else b'\xef'
    payload = version + raw_priv + b'\x01'
    return _base58check(payload)

def wif_uncompressed_from_raw(raw_priv: bytes, mainnet=True) -> str:
    version = b'\x80' if mainnet else b'\xef'
    payload = version + raw_priv
    return _base58check(payload)
