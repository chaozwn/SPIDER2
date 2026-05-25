"""Common HTTP client for InfiniSynapse API calls.

Centralizes credential loading, base URL handling, auth headers and request
dispatch so that individual endpoint modules only need to describe the path
and payload.
"""

from __future__ import annotations

import json
import logging
import os
from pathlib import Path
from typing import Any, Mapping
from urllib.parse import quote

import requests

from spider_agent_infini.spider_agent_setup_infini import INFINI_CREDENTIAL_PATH

DEFAULT_TIMEOUT: float = 10.0

logger = logging.getLogger("spider_agent_infini")


def _load_credential(
    credential_path: str | os.PathLike | None = None,
) -> tuple[str, str]:
    """Load (api_url, api_key) from the InfiniSynapse credential JSON file."""
    path = Path(credential_path) if credential_path else INFINI_CREDENTIAL_PATH
    with open(path, "r", encoding="utf-8") as f:
        cred = json.load(f)
    return cred["api_url"].rstrip("/"), cred["api_key"]


class InfiniClient:
    """Thin wrapper around `requests` that injects base URL and Bearer auth."""

    def __init__(
        self,
        credential_path: str | os.PathLike | None = None,
        timeout: float = DEFAULT_TIMEOUT,
    ) -> None:
        self.api_url, self._api_key = _load_credential(credential_path)
        self.timeout = timeout

    def _headers(self, extra: Mapping[str, str] | None = None) -> dict[str, str]:
        headers = {
            "Accept": "application/json",
            "Authorization": f"Bearer {self._api_key}",
        }
        if extra:
            headers.update(extra)
        return headers

    def _url(self, path: str, *path_params: str) -> str:
        encoded = "/".join(quote(str(p), safe="") for p in path_params)
        path = path.rstrip("/")
        if encoded:
            path = f"{path}/{encoded}"
        if not path.startswith("/"):
            path = "/" + path
        return f"{self.api_url}{path}"

    def request(
        self,
        method: str,
        path: str,
        *path_params: str,
        params: Mapping[str, Any] | None = None,
        json_body: Any = None,
        data: Any = None,
        files: Any = None,
        headers: Mapping[str, str] | None = None,
        timeout: float | None = None,
        raise_for_status: bool = True,
    ) -> requests.Response:
        kwargs: dict[str, Any] = {
            "headers": self._headers(headers),
            "params": params,
            "timeout": timeout if timeout is not None else self.timeout,
        }
        if files is not None:
            # multipart/form-data: let requests build the boundary; don't pass json
            kwargs["files"] = files
            if data is not None:
                kwargs["data"] = data
        elif data is not None:
            kwargs["data"] = data
        else:
            kwargs["json"] = json_body
        resp = requests.request(method, self._url(path, *path_params), **kwargs)
        if raise_for_status and resp.status_code >= 400 and resp.status_code != 404:
            resp.raise_for_status()
        return resp

    def get(self, path: str, *path_params: str, **kwargs: Any) -> requests.Response:
        return self.request("GET", path, *path_params, **kwargs)

    def post(self, path: str, *path_params: str, **kwargs: Any) -> requests.Response:
        return self.request("POST", path, *path_params, **kwargs)


def unwrap(body: Any) -> Any:
    """Unwrap nest-admin style `{code, data, message}` payloads."""
    if isinstance(body, dict) and "data" in body:
        return body["data"]
    return body
