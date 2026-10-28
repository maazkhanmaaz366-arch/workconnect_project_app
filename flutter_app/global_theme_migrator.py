import os
import glob
import re

paths = glob.glob('lib/screens/**/*.dart', recursive=True)

color_mappings = {
    'kPrimaryColor': 'Theme.of(context).colorScheme.primary',
    'kSecondaryColor': 'Theme.of(context).colorScheme.secondary',
    'kSecondaryContainer': 'Theme.of(context).colorScheme.secondaryContainer',
    'kSurfaceColor': 'Theme.of(context).scaffoldBackgroundColor',
    'kSurfaceVariant': 'Theme.of(context).colorScheme.surfaceContainerHighest', # standard m3
}

def strip_const_from_line(line, target_expr):
    if target_expr in line and 'const ' in line:
        # Strip const from standard widgets
        line = re.sub(r'const\s+(Text|Icon|Center|Expanded|BoxShadow|BoxDecoration|Padding|SizedBox|Column|Row|Align|Container|TextStyle|BorderSide|EdgeInsets|BorderRadius)', r'\1', line)
        line = re.sub(r'const\s+\[', '[', line)
    return line

for path in paths:
    with open(path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    new_lines = []
    for line in lines:
        # 1. Purge definitions
        if re.match(r'^const\s+Color\s+k(Primary|Secondary|Surface).*=.*Color\(.*\);', line.strip()):
            continue
        
        original_line = line
        
        # 2. Replace occurrences
        for old_color, new_color in color_mappings.items():
            if old_color in line:
                line = line.replace(old_color, new_color)
                
        # 3. Strip const if we introduced Theme.of
        if 'Theme.of(context)' in line and original_line != line:
            line = strip_const_from_line(line, 'Theme.of(context)')
            
        new_lines.append(line)

    with open(path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)

print("Constants purged and migrated.")
