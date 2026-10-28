import os
import re
import glob

paths = glob.glob('lib/screens/**/*.dart', recursive=True)

for path in paths:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if 'Colors.black' not in content:
        continue
        
    lines = content.split('\n')
    new_lines = []
    
    for line in lines:
        if 'Colors.black' in line:
            # Replace Colors.black variations
            line = line.replace('Colors.black87', '(Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white)')
            line = line.replace('Colors.black54', '(Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)')
            line = line.replace('color: Colors.black', 'color: Theme.of(context).colorScheme.onSurface')
            
            # Basic const removal on same line
            line = re.sub(r'\bconst\s+Text\(', 'Text(', line)
            line = re.sub(r'\bconst\s+TextStyle\(', 'TextStyle(', line)
            line = re.sub(r'\bconst\s+Icon\(', 'Icon(', line)
            line = re.sub(r'\bconst\s+Row\(', 'Row(', line)
            line = re.sub(r'\bconst\s+Column\(', 'Column(', line)
            line = re.sub(r'\bconst\s+Padding\(', 'Padding(', line)
            line = re.sub(r'\bconst\s+SizedBox\(', 'SizedBox(', line)
            line = re.sub(r'\bconst\s+Spacer\(', 'Spacer(', line)
        
        new_lines.append(line)
        
    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(new_lines))

print("Color replacements done.")
