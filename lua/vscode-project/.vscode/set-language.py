import json
import os
import sys


lang = sys.argv[1] if len(sys.argv) > 1 else "en"
settings_path = os.path.join(os.getcwd(), ".vscode", "settings.json")

settings = {}
if os.path.exists(settings_path):
    with open(settings_path, "r", encoding="utf-8") as f:
        settings = json.load(f)

settings["ethosDeployTemplate.deploy.language"] = lang

os.makedirs(os.path.dirname(settings_path), exist_ok=True)
with open(settings_path, "w", encoding="utf-8") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")

print("Deployment language set to:", lang)
