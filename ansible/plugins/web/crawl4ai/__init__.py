try:
    from .provider import Crawl4AIProvider
except ImportError:  # fallback p/ layout interno do repo
    from plugins.web.crawl4ai.provider import Crawl4AIProvider


def register(ctx) -> None:
    """Plugin entry point — registers the Crawl4AI extract backend."""
    ctx.register_web_search_provider(Crawl4AIProvider())
