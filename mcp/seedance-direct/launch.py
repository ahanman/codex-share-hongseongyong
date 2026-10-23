"""Start the pinned Ark MCP with receiver-owned credentials and portable paths."""
import os
from pathlib import Path
import runpy
import sys

from credentials import read_key

ROOT = Path(__file__).resolve().parent
os.chdir(ROOT / "ark-mcp")
os.environ.setdefault("ARK_MCP_ENV_FILE", str(ROOT / "settings.env"))
os.environ.update({
    "MCP_TRANSPORT": "stdio",
    "BYTEPLUS_MODELARK_BASE_URL": "https://ark.ap-southeast.bytepluses.com/api/v3",
    "SEEDANCE_DEFAULT_MODEL": "dreamina-seedance-2-5-260628",
    "SEEDANCE_MODEL_FAMILY": "seedance_2_5",
    "ARK_LOG_LEVEL": "WARNING",
})
if not os.environ.get("BYTEPLUS_MODELARK_API_KEY"):
    try:
        saved_key = read_key()
    except Exception:
        print("Seedance: OS credential storage is unavailable; configure your own API key.", file=sys.stderr)
        saved_key = ""
    if saved_key:
        os.environ["BYTEPLUS_MODELARK_API_KEY"] = saved_key
runpy.run_module("ark_mcp", run_name="__main__")
