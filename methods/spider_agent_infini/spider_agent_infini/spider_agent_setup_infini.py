from pathlib import Path

_PROJECT_ROOT = Path(__file__).resolve().parent.parent
_REPO_ROOT = _PROJECT_ROOT.parent.parent

JSONL_PATH = str(_REPO_ROOT / "spider2-snow" / "spider2-snow.jsonl")
DATABASE_PATH = str(_REPO_ROOT / "spider2-snow" / "resource" / "databases") + "/"
DOCUMENT_PATH = str(_REPO_ROOT / "spider2-snow" / "resource" / "documents")
INFINI_CREDENTIAL_PATH = str(_PROJECT_ROOT / "infini_credential.json")


def add_database_to_infini():
    pass


if __name__ == "__main__":
    add_database_to_infini()
