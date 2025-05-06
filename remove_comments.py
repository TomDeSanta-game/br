
import os
import re
import sys
def remove_comments_from_file(filename):
    print(f"Processing: {filename}")
    with open(filename, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    if filename.endswith('.gd'):
        content = re.sub(r'^\s*
        content = re.sub(r'
        content = re.sub(r'//.*$', '', content, flags=re.MULTILINE)
    elif filename.endswith('.py'):
        content = re.sub(r'^\s*
        content = re.sub(r'
        content = re.sub(r'', '', content)
        content = re.sub(r"", '', content)
    content = re.sub(r'\n\s*\n\s*\n', '\n\n', content)
    content = re.sub(r'\s+$', '', content, flags=re.MULTILINE)
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Removed comments from: {filename}")
def process_directory(directory):
    for root, dirs, files in os.walk(directory):
        if 'addons' in dirs:
            dirs.remove('addons')
        for file in files:
            if file.endswith('.gd') or file.endswith('.py'):
                filepath = os.path.join(root, file)
                remove_comments_from_file(filepath)
if __name__ == "__main__":
    project_root = "."
    if len(sys.argv) > 1:
        project_root = sys.argv[1]
    print(f"Removing comments from GDScript and Python files in {project_root}")
    process_directory(project_root)
    print("Done!")