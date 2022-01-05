import os
import pathlib
import shutil

import requests

API_URL = os.environ["SUPERSET__ENV_API_URL"] + "/api/v1/"
ASSETS_PATH = os.path.join(pathlib.Path(__file__).parent.resolve(), "assets")


def get_jwt_token():
    payload = {
        "password": os.environ["SUPERSET__ENV_PASS"],
        "provider": "db",
        "refresh": True,
        "username": os.environ["SUPERSET__ENV_USER"]
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


def rename_subdir(dir_path):
    path_name = os.listdir(dir_path)[0]
    orig_path_name = os.path.join(dir_path, path_name)
    new_path_name = os.path.join(dir_path, "export")
    if os.path.isdir(new_path_name):
        shutil.rmtree(new_path_name)
    os.rename(orig_path_name, new_path_name)


def export_assets_zip(jwt_token, csrf_token, asset_type, name_key):
    headers = {
        "accept": "application/json",
        "Authorization": f"Bearer {jwt_token}",
        "X-CSRFToken": csrf_token
    }
    resp = requests.get(API_URL + asset_type, headers=headers)
    resp.raise_for_status()
    data = resp.json()
    id_name_map = {i.get("id"): i.get(name_key) for i in data.get("result")}
    for id in data.get("ids"):
        resp = requests.get(
            API_URL + f"{asset_type}/export", headers=headers, params={"q": f"[{id}]"})
        resp.raise_for_status()
        name = id_name_map.get(id)
        filename = f"{name}.zip"
        full_path = os.path.join(ASSETS_PATH, asset_type, filename)
        with open(full_path, "wb") as f:
            print(f"Exporting {asset_type}: {filename}")
            f.write(resp.content)
        dir_name = os.path.join(ASSETS_PATH, asset_type, f"{name}")
        if os.path.exists(dir_name):
            # clear directory if it already exists
            shutil.rmtree(dir_name)
        shutil.unpack_archive(full_path, os.path.join(
            ASSETS_PATH, asset_type, f"{name}"), "zip")
        rename_subdir(dir_name)
        os.remove(full_path)

def export_databases(jwt_token, csrf_token):
    export_assets_zip(jwt_token, csrf_token, "database", "database_name")

def export_charts(jwt_token, csrf_token):
    export_assets_zip(jwt_token, csrf_token, "chart", "slice_name")
    remove_chart_extras()


def remove_chart_extras():
    base_path = os.path.join(ASSETS_PATH, "chart")
    for chart_name in os.listdir(base_path):
        export_path = os.path.join(base_path, chart_name, "export")
        if not os.path.exists(export_path):
            continue
        for filename in os.listdir(export_path):
            full_path = os.path.join(export_path, filename)
            if filename != "charts" and os.path.isdir(full_path):
                shutil.rmtree(full_path)

def clear_assets():
    for path_name in os.listdir(ASSETS_PATH):
        for asset_name in os.listdir(os.path.join(ASSETS_PATH, path_name)):
            if not asset_name.startswith("."):
                # skip .gitkeep files
                asset_path = os.path.join(ASSETS_PATH, path_name, asset_name)
                if os.path.isdir(asset_path):
                    shutil.rmtree(asset_path)
                else:
                    os.remove(asset_path)

def export_assets_yaml(jwt_token, csrf_token, asset_type, name_key):
    headers = {
        "accept": "application/json",
        "Authorization": f"Bearer {jwt_token}",
        "X-CSRFToken": csrf_token
    }
    resp = requests.get(API_URL + asset_type, headers=headers)
    resp.raise_for_status()
    data = resp.json()
    id_name_map = {i.get("id"): i.get(name_key) for i in data.get("result")}
    for id in data.get("ids"):
        resp = requests.get(
            API_URL + f"{asset_type}/export", headers=headers, params={"q": f"[{id}]"})
        resp.raise_for_status()
        name = id_name_map.get(id)
        filename = f"{name}.yaml"
        full_path = os.path.join(ASSETS_PATH, asset_type, filename)
        with open(full_path, "wb") as f:
            print(f"Exporting {asset_type}: {filename}")
            f.write(resp.content)

jwt_token = get_jwt_token()
csrf_token = get_csrf_token(jwt_token)
clear_assets()
export_assets_yaml(jwt_token, csrf_token, "dashboard", "dashboard_title")
export_charts(jwt_token, csrf_token)
export_databases(jwt_token, csrf_token)
