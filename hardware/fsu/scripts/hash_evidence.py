"""Hash FSU evidence pages with the framework's own hashing (src/intake/validator.py).
Usage: python hash_evidence.py <evidence_dir> [out.json]"""
import json
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "..", "src"))
from intake.validator import calculate_hashes  # noqa: E402


def main() -> int:
    ev_dir = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 else "evidence_hashes.json"
    items = []
    for name in sorted(os.listdir(ev_dir)):
        if not name.endswith(".bin"):
            continue
        path = os.path.join(ev_dir, name)
        h = calculate_hashes(path)
        with open(path, "rb") as f:
            head = f.read(8).hex()
        items.append({"file": name, "size": os.path.getsize(path),
                      "sha256": h["sha256"], "md5": h["md5"], "first_bytes": head})
    with open(out, "w") as f:
        json.dump(items, f, indent=2)
    print(json.dumps(items, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
