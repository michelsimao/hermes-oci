from __future__ import annotations

import os

import httpx

from agent.web_search_provider import WebSearchProvider


class Crawl4AIProvider(WebSearchProvider):
    """Self-hosted Crawl4AI extract backend (HTTP mode).

    Talks to the local crawl4ai_server.py (FastAPI) over HTTP.
    Configured via web.extract_backend: crawl4ai in config.yaml.
    """

    @property
    def name(self) -> str:
        return "crawl4ai"

    @property
    def display_name(self) -> str:
        return "Crawl4AI (self-hosted)"

    def is_available(self) -> bool:
        # Cheap check only — no network calls.
        base = os.getenv("CRAWL4AI_BASE_URL", "http://127.0.0.1:8000")
        return bool(base)

    def supports_search(self) -> bool:
        return False

    def supports_extract(self) -> bool:
        return True

    def extract(self, urls, **kwargs):
        base = os.getenv("CRAWL4AI_BASE_URL", "http://127.0.0.1:8000")
        results = []
        for url in urls if isinstance(urls, (list, tuple)) else [urls]:
            try:
                resp = httpx.post(
                    f"{base}/crawl",
                    json={"url": url, "bypass_cache": True},
                    timeout=60,
                )
                resp.raise_for_status()
                data = resp.json()
                markdown = data.get("markdown", "")
                results.append(
                    {
                        "url": url,
                        "title": "",
                        "content": markdown,
                        "raw_content": markdown,
                        "metadata": {},
                    }
                )
            except Exception as exc:  # noqa: BLE001
                results.append(
                    {
                        "url": url,
                        "title": "",
                        "content": "",
                        "raw_content": "",
                        "metadata": {},
                        "error": str(exc),
                    }
                )
        return results
