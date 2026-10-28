import os
import glob
import re

paths = glob.glob('lib/screens/**/*.dart', recursive=True)
count = 0
for path in paths:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    styles = re.findall(r'TextStyle\([^)]*\)', content)
    count += len(styles)

print(f"Total inline TextStyles found: {count}")
