import json
import os
import pathlib
import shutil

import requests

API_URL = os.environ["SUPERSET_API_URL"] + "/api/v1/"
ASSETS_PATH = os.path.join(pathlib.Path(__file__).parent.resolve(), "assets")


def get_jwt_token():
    payload = {
        "password": os.environ["SUPERSET_PASS"],
        "provider": "db",
        "refresh": True,
        "username": os.environ["SUPERSET_USER"]
    }
    resp = requests.post(API_URL + "security/login", json=payload)
    return resp.json().get("access_token")


def get_csrf_token(jwt_token):
    headers = {
        "accept": "application/json",
        "Authorization": f"Bearer {jwt_token}",
    }
    resp = requests.get(API_URL + "security/csrf_token", headers=headers)
    return resp.json().get("result")


def build_password_payload(file_path):
    passwords = {}
    if not os.path.isdir(os.path.join(file_path, "export", "databases")):
        return json.dumps(passwords)
    for database_file in os.listdir(os.path.join(file_path, "export", "databases")):
        passwords[f"databases/{database_file}"] = "placeholder"
    return json.dumps(passwords)


def get_zip_file(file_path):
    output_filename = os.path.basename(file_path)
    zip_path = os.path.join(pathlib.Path(
        file_path).parent.resolve(), output_filename)
    shutil.make_archive(zip_path, 'zip', file_path)
    with open(zip_path + ".zip", 'rb') as f:
        content = f.read()
    os.remove(zip_path + ".zip")
    return content


def import_assets_zip(jwt_token, asset_type):
    url_full = f"{API_URL}{asset_type}/import/"
    headers = {
        "Authorization": f"Bearer {jwt_token}",
        "Referer": url_full
    }
    _path = os.path.join(ASSETS_PATH, f"{asset_type}")
    for filename in os.listdir(_path):
        file_path = os.path.join(_path, filename)
        if os.path.isdir(file_path):
            print(f"Importing {asset_type}: {filename}")
            zip_file_obj = get_zip_file(file_path)
            files = {
                "formData": (
                    file_path,
                    zip_file_obj,
                )
            }
            passwords_json = build_password_payload(file_path)
            resp = requests.post(url_full, data={
                                 "passwords": passwords_json, "overwrite": "true"}, files=files, headers=headers)
            resp.raise_for_status()
            print(resp.content)

def import_assets_yaml(jwt_token, asset_type):
    url_full = f"{API_URL}{asset_type}/import/"
    headers = {
        "Authorization": f"Bearer {jwt_token}",
        "Referer": url_full
    }
    _path = os.path.join(ASSETS_PATH, f"{asset_type}")
    for filename in os.listdir(_path):
        file_path = os.path.join(_path, filename)
        if os.path.isfile(file_path) and filename.endswith(".yaml"):
            print(f"Importing {asset_type}: {filename}")
            files = {
                "formData": (
                    file_path,
                    open(file_path, 'rb'),
                )
            }
            resp = requests.post(url_full, files=files, headers=headers)
            resp.raise_for_status()
            print(resp.content)


jwt_token = get_jwt_token()
import_assets_zip(jwt_token, "database")
import_assets_zip(jwt_token, "chart")
import_assets_yaml(jwt_token, "dashboard")
