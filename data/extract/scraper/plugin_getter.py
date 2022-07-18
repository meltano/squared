import requests, json
import pandas as pd
import os.path

#potentially might not have to use this (anonymous event provides consolidated list of commands)

class PluginNames:
    
    def __init__(self, tap_url, target_url):
        self = self
        self.tap_url = tap_url
        self.target_url = target_url 

    def pull_data(self):
        self.read_tap_text()
        self.get_tap_names()
        self.tap_seed()
        self.read_target_text()
        self.get_target_names()
        self.target_seed()

    def read_tap_text(self, tap_url):
        tap_requests = requests.get(tap_url)
        tap_text = tap_requests.text
        meltano_taps = json.loads(tap_text)
        return meltano_taps
    
    def get_tap_names(self, meltano_taps):
        meltano_tap_list = [meltano_tap['singer_name'].split('-')[1] for meltano_tap in meltano_taps]
        return meltano_tap_list

    def tap_seed(self, meltano_tap_list):
        tap_df = pd.DataFrame({'tap_names':meltano_tap_list})
        return tap_df.to_csv(os.path.join('Seeds','tap_names.csv'))

    def read_target_text(self, target_url):
        target_requests = requests.get(target_url)
        target_text = target_requests.text
        meltano_targets = json.loads(target_text)
        return meltano_targets

    def get_target_names(self, meltano_targets):
        meltano_target_list = [meltano_target['label'] for meltano_target in meltano_targets]
        return meltano_target_list
    
    def target_seed(self, meltano_target_list):
        target_df = pd.DataFrame({'target_names':meltano_target_list})
        return target_df.to_csv(os.path.join('Seeds','target_names.csv'))
    


