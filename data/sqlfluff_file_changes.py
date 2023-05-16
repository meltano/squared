"""
    This script compares the current branch to main in order to get a list of SQL
    files that changed and should be considered for linting.
"""
import subprocess
import os
import sys

# These could indicate a change to the overall settings
# or version so all files should be considered
SQLFLUFF_FILES = [
    ".sqlfluff",
    ".sqlfluffignore",
    "utilities.meltano.yml",
]


output = subprocess.run(
    ["git", "rev-parse", "--abbrev-ref", "HEAD"],
    capture_output=True,
    text=True
)
branch_name = output.stdout.replace("\n", "")
output = subprocess.run(
    ["git", "rev-parse", "--show-toplevel"],
    capture_output=True,
    text=True
)
base_path = output.stdout.replace("\n", "")
output = subprocess.run(
    ["git", "diff", "--name-status", f"main..{branch_name}"],
    capture_output=True,
    text=True
)
changed_files_raw = output.stdout
changed_files_list = changed_files_raw.split("\n")

changed_files = []
all_flag = False
for changed_file in changed_files_list:
    if not changed_file:
        continue
    action = changed_file.split("\t")[0]
    file_path = changed_file.split("\t")[1]
    if action == "M" and file_path.endswith(".sql"):
        changed_files.append(f"{base_path}/{file_path}")
    if os.path.basename(file_path) in SQLFLUFF_FILES:
        sys.exit(0)

if changed_files:
    print(" ".join(changed_files))
else:
    print("--version")
