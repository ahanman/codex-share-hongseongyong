"""Use the receiving user's operating-system credential vault."""
import keyring

SERVICE = "Codex Seedance Direct - BytePlus ModelArk"
ACCOUNT = "BYTEPLUS_MODELARK_API_KEY"


def read_key() -> str:
    return keyring.get_password(SERVICE, ACCOUNT) or ""


def save_key(value: str) -> None:
    keyring.set_password(SERVICE, ACCOUNT, value)
