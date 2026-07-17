import shutil
import os

source = "sergak web bot/logo.png"
dest = "logo.png"

if os.path.exists(source):
    shutil.copy(source, dest)
    print(f"Logo copied from {source} to {dest}")
else:
    print(f"Source file {source} not found")