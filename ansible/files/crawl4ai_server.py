#!/usr/bin/env python3
"""Crawl4AI local HTTP server (lightweight, no Docker).

Exposes a tiny FastAPI service that wraps Crawl4AI's AsyncWebCrawler so the
Hermes plugin (plugins/web/crawl4ai) can call it over HTTP.

Endpoints:
  POST /crawl  { "url": "https://...", "bypass_cache": true }
        -> { "url": ..., "markdown": "...", "success": true }
  GET  /health -> { "status": "ok" }

Run: uvicorn crawl4ai_server:app  (or via systemd unit)
"""
from __future__ import annotations

import os

import importlib

import httpx
import uvicorn
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from crawl4ai import AsyncWebCrawler, BrowserConfig, CrawlerRunConfig, CacheMode

app = FastAPI(title="Crawl4AI Local HTTP")


class CrawlRequest(BaseModel):
    url: str
    bypass_cache: bool = True


def _build_browser_config():
    """Prefer the browserless HTTP strategy when available (no Chromium);
    fall back to headless Playwright otherwise."""
    try:
        mod = importlib.import_module("crawl4ai")
        strategy_cls = getattr(mod, "AsyncHTTPCrawlerStrategy", None)
        if strategy_cls is not None:
            return BrowserConfig(crawler_strategy=strategy_cls())
    except Exception:
        pass
    return BrowserConfig(headless=True, verbose=False)


def _build_run_config(bypass_cache: bool):
    return CrawlerRunConfig(
        cache_mode=CacheMode.BYPASS if bypass_cache else CacheMode.ENABLED,
        word_count_threshold=10,
        exclude_external_links=True,
        remove_overlay_elements=False,
        wait_for_images=False,
        page_timeout=60000,
        mean_delay=0.5,
    )


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/crawl")
async def crawl(req: CrawlRequest):
    if not req.url:
        raise HTTPException(status_code=400, detail="url is required")

    browser_config = _build_browser_config()
    run_config = _build_run_config(req.bypass_cache)
    last_err = None
    for attempt in range(2):
        try:
            async with AsyncWebCrawler(config=browser_config) as crawler:
                result = await crawler.arun(url=req.url, config=run_config)
            if getattr(result, "success", False):
                return {
                    "url": req.url,
                    "markdown": getattr(result, "markdown", "") or "",
                    "success": True,
                }
            last_err = getattr(result, "error_message", "crawl failed")
        except Exception as exc:  # noqa: BLE001
            last_err = str(exc)
        # one retry on transient navigation errors
    raise HTTPException(status_code=502, detail=last_err or "crawl failed")


if __name__ == "__main__":
    host = os.getenv("CRAWL4AI_HOST", "127.0.0.1")
    port = int(os.getenv("CRAWL4AI_PORT", "8000"))
    uvicorn.run(app, host=host, port=port)
