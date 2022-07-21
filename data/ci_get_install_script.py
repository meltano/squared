import sys
import json

data = json.load(sys.stdin)
my_job = sys.argv[1]

script = set()
for job in data.get('jobs'):
    if my_job == job.get('job_name'):
        for task in job.get('tasks'):
            plugins = task.split(' ')
            for index, plugin in enumerate(plugins):
                if ':' in plugin:
                    plugin = plugin.split(':')[0]
                    script.add(f'meltano install transformer {plugin};')
                elif plugin.startswith('tap-'):
                  script.add(f'meltano install extractor {plugin};')
                elif plugin.startswith('target-'):
                  script.add(f'meltano install loader {plugin};')
                elif len(plugins) > 2 and index not in (0, len(plugins)-1):
                  script.add(f'meltano install mapper {plugin};')
print(' '.join(script))