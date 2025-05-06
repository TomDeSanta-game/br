
import os
import subprocess
import sys
def check_gdscript_file(filepath):
    try:
        print(f"Checking: {filepath}")
        result = subprocess.run(
            ["godot", "--headless", "--check-only", filepath],
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            print(f"Error in {filepath}:")
            print(result.stderr)
            return False
        return True
    except Exception as e:
        print(f"Error checking {filepath}: {e}")
        return False
def scan_directory(directory):
    success = True
    for root, dirs, files in os.walk(directory):
        if 'addons' in dirs:
            dirs.remove('addons')
        for file in files:
            if file.endswith('.gd'):
                filepath = os.path.join(root, file)
                if not check_gdscript_file(filepath):
                    success = False
    return success
if __name__ == "__main__":
    print("This script would check GDScript files for syntax errors")
    print("However, it requires Godot to be callable from the command line")
    print("Use the Godot editor to check for errors instead")