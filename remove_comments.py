#!/usr/bin/env python3
import os
import re
import sys

def remove_comments_from_file(filename):
    print(f"Processing: {filename}")
    with open(filename, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    # Remove single line comments (lines starting with #)
    content = re.sub(r'^\s*#.*$', '', content, flags=re.MULTILINE)
    
    # Remove inline comments (everything after # on a line)
    content = re.sub(r'#.*$', '', content, flags=re.MULTILINE)
    
    # Remove C-style single-line comments (everything after // on a line)
    content = re.sub(r'//.*$', '', content, flags=re.MULTILINE)
    
    # Clean up excess whitespace from removed comments
    content = re.sub(r'\n\s*\n\s*\n', '\n\n', content)
    content = re.sub(r'\s+$', '', content, flags=re.MULTILINE)
    
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Removed comments from: {filename}")

def process_directory(directory):
    for root, dirs, files in os.walk(directory):
        # Skip addons directory
        if 'addons' in dirs:
            dirs.remove('addons')
        
        for file in files:
            if file.endswith('.gd'):
                filepath = os.path.join(root, file)
                remove_comments_from_file(filepath)

if __name__ == "__main__":
    project_root = "."
    if len(sys.argv) > 1:
        project_root = sys.argv[1]
    
    print(f"Removing comments from GDScript files in {project_root}")
    process_directory(project_root)
    print("Done!") 