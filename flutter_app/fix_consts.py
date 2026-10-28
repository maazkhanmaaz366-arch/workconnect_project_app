import os
import glob
import re

paths = glob.glob('lib/screens/**/*.dart', recursive=True)

for path in paths:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace the bad color scheme values from my previous regex
    content = content.replace('.onSurface12', '.onSurface.withOpacity(0.12)')
    content = content.replace('.onSurface26', '.onSurface.withOpacity(0.26)')
    content = content.replace('.onSurface54', '.onSurface.withOpacity(0.54)')
    content = content.replace('.onSurface87', '.onSurface.withOpacity(0.87)')
    
    # Remove consts from arrays or widgets containing Theme.of(context)
    lines = content.split('\n')
    new_lines = []
    
    for i, line in enumerate(lines):
        # Very aggressive const stripper on lines that have Theme.of(context)
        if 'Theme.of(context)' in line:
            line = re.sub(r'\bconst\s+\[BoxShadow', '[BoxShadow', line)
            line = re.sub(r'\bconst\s+BoxShadow', 'BoxShadow', line)
            line = re.sub(r'\bconst\s+BorderSide', 'BorderSide', line)
            line = re.sub(r'\bconst\s+BoxDecoration', 'BoxDecoration', line)
            line = re.sub(r'\bconst\s+Center', 'Center', line)
            line = re.sub(r'\bconst\s+Expanded', 'Expanded', line)
            line = re.sub(r'\bconst\s+Text', 'Text', line)
            line = re.sub(r'\bconst\s+Icon', 'Icon', line)
            line = re.sub(r'\bconst\s+CircleAvatar', 'CircleAvatar', line)
            line = re.sub(r'\bconst\s+Row', 'Row', line)
            
        # Also handle cases where `const Row(` is on the previous line!
        if 'const Row(' in line:
            if i + 1 < len(lines) and 'Theme.of(context)' in lines[i+1]:
                line = line.replace('const Row(', 'Row(')
            if i + 2 < len(lines) and 'Theme.of(context)' in lines[i+2]:
                line = line.replace('const Row(', 'Row(')

        # Same for const [BoxShadow
        if 'const [BoxShadow' in line:
            if i + 1 < len(lines) and 'Theme.of(context)' in lines[i+1]:
                line = line.replace('const [BoxShadow', '[BoxShadow')
                
        # Same for const BoxDecoration
        if 'const BoxDecoration' in line:
            if i + 1 < len(lines) and 'Theme.of(context)' in lines[i+1]:
                line = line.replace('const BoxDecoration', 'BoxDecoration')

        new_lines.append(line)
        
    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(new_lines))

print("Fixed constants.")
