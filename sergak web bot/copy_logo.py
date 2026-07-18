import shutil
src = r"C:\Users\ki770\.gemini\antigravity\brain\3f347020-3a97-4525-8fab-d2f3ec5cbda7\media__1779065817343.png"
dst = r"c:\Users\ki770\OneDrive\Desktop\py_files\sergak_website\logo.png"
try:
    shutil.copy(src, dst)
    print("Logo copied successfully!")
except Exception as e:
    print(f"Error copying file: {e}")
