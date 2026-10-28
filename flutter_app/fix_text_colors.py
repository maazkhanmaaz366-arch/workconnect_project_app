import os
import glob
import re

paths = glob.glob('lib/screens/**/*.dart', recursive=True)

for path in paths:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Replace color: kPrimaryColor with color: Theme.of(context).colorScheme.primary
    # Specifically inside TextStyle, Icon, and CircularProgressIndicator
    
    # regex to match color: kPrimaryColor
    content = re.sub(r'color:\s*kPrimaryColor', r'color: Theme.of(context).colorScheme.primary', content)
    
    # BottomNavigationBar in dashboard: replace selectedItemColor: kPrimaryColor
    # The regex above will catch it: selectedItemColor: Theme.of(context).colorScheme.primary
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

print("Text colors fixed.")
