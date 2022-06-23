from bs4 import BeautifulSoup as bs
import requests
import pandas as pd
import os.path


#potentially might not have to use this (anonymous event provides consolidated list of commands)

class CliPageScraper:
    def __init__(self, page_html):
        self.page_html = page_html
        self.bs = bs(page_html)

    def pull_data(self):
        """Run function that kicks off the class object when it is called"""
        self.read_cli_page()
        self.create_cli_list()
        self.cli_seed()

    def read_cli_page(self):
        """Makes the request to the cli_command page, parses, """
        page = requests.get(self.page_html)
        self.cli_soup = bs(page.content, "html.parser")
        return self.cli_soup
        
    def create_cli_list(self):
        results = self.cli_soup.find(id="toc")
        raw_list = results.text.split('\n')
        cli_list = raw_list[1:-1]
        return cli_list

    def cli_seed(self, cli_list):
        cli_df = pd.DataFrame({'cli_commands':cli_list})
        return cli_df.to_csv(os.path.join('Seeds','cli_names.csv'))

    