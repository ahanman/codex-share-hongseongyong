"""Save a receiver-provided key without writing it into config or terminal output."""
from getpass import getpass
import sys

from credentials import save_key


def main() -> None:
    key = getpass("Your BytePlus ModelArk API key (hidden): ").strip()
    if not key or any(char.isspace() for char in key):
        print("A non-empty API key without whitespace is required.", file=sys.stderr)
        raise SystemExit(1)
    try:
        save_key(key)
    except Exception:
        print("Could not save the API key to OS credential storage.", file=sys.stderr)
        raise SystemExit(1)
    print("Saved to your OS credential storage. Restart Codex to load the MCP tools.")


if __name__ == "__main__":
    main()
