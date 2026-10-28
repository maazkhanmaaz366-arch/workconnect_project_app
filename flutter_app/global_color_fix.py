import os
import glob
import re

paths = glob.glob('lib/screens/**/*.dart', recursive=True)

for path in paths:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Scaffold and AppBar background fixes
    content = content.replace('backgroundColor: kSurfaceColor,', '')
    content = content.replace('backgroundColor: kSurfaceColor', '')
    content = content.replace('color: kSurfaceColor', 'color: Theme.of(context).scaffoldBackgroundColor')
    
    # White background fixes (Containers, Cards, etc)
    content = content.replace('backgroundColor: Colors.white,', '')
    content = content.replace('backgroundColor: Colors.white', '')
    # Be careful not to replace text color 'color: Colors.white' with cardColor. We only want background colors.
    content = re.sub(r'(decoration:\s*BoxDecoration\([^)]*)color:\s*Colors\.white', r'\1color: Theme.of(context).cardColor', content)
    content = re.sub(r'Container\([^)]*color:\s*Colors\.white', r'Container(color: Theme.of(context).cardColor', content)

    # Missing back button fix: AppBar foreground color
    content = content.replace('foregroundColor: Colors.white,', '')

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

print("Colors globally fixed.")
