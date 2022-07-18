from plugin_getter import PluginNames
from cli_scraper import CliPageScraper


class SeedRun:
    TAP_URL="https://hub.meltano.com/singer/api/v1/taps.json"
    TARGET_URL="https://hub.meltano.com/singer/api/v1/targets.json"
    PAGE_HTML="https://docs.meltano.com/reference/command-line-interface.html"

    def run_scraping(self, page_html=PAGE_HTML):
        cli_scraping = CliPageScraper(page_html)
        return cli_scraping
    
    def run_plugin_getter(self, tap_url=TAP_URL, target_url=TARGET_URL):
        plugin_getter = PluginNames(tap_url, target_url)
        return plugin_getter