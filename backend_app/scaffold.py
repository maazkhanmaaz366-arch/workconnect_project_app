import os

base_dir = "c:/Users/songh/OneDrive/Desktop/workConnect/backend_app/api"
modules = ["auth", "users", "jobs", "ai", "reviews"]
files = ["__init__.py", "router.py", "schemas.py", "services.py"]

os.makedirs(base_dir, exist_ok=True)
with open(os.path.join(base_dir, "__init__.py"), "w") as f:
    pass

for mod in modules:
    mod_dir = os.path.join(base_dir, mod)
    os.makedirs(mod_dir, exist_ok=True)
    for file in files:
        file_path = os.path.join(mod_dir, file)
        with open(file_path, "w") as f:
            if file == "router.py":
                f.write(f'from fastapi import APIRouter\n\nrouter = APIRouter(prefix="/{mod}", tags=["{mod.capitalize()}"])\n')
            else:
                pass
print("Scaffolding complete.")
