import os
import glob
import re

paths = glob.glob('lib/screens/**/*.dart', recursive=True)

mappings = [
    (r'(?<!const\s)TextStyle\(fontSize:\s*32,\s*fontWeight:\s*FontWeight\.bold\)', r'Theme.of(context).textTheme.headlineLarge'),
    (r'(?<!const\s)TextStyle\(fontSize:\s*28,\s*fontWeight:\s*FontWeight\.bold\)', r'Theme.of(context).textTheme.headlineMedium'),
    (r'(?<!const\s)TextStyle\(fontSize:\s*24,\s*fontWeight:\s*FontWeight\.bold\)', r'Theme.of(context).textTheme.headlineSmall'),
    (r'(?<!const\s)TextStyle\(fontSize:\s*20,\s*fontWeight:\s*FontWeight\.bold\)', r'Theme.of(context).textTheme.titleLarge'),
    (r'(?<!const\s)TextStyle\(fontSize:\s*18,\s*fontWeight:\s*FontWeight\.bold\)', r'Theme.of(context).textTheme.titleMedium'),
    (r'(?<!const\s)TextStyle\(fontSize:\s*16,\s*fontWeight:\s*FontWeight\.bold\)', r'Theme.of(context).textTheme.titleSmall'),
    (r'(?<!const\s)TextStyle\(fontSize:\s*16\)', r'Theme.of(context).textTheme.bodyLarge'),
    (r'(?<!const\s)TextStyle\(fontSize:\s*14\)', r'Theme.of(context).textTheme.bodyMedium'),
    (r'(?<!const\s)TextStyle\(fontSize:\s*12\)', r'Theme.of(context).textTheme.labelSmall'),
]

# also do the ones with const
const_mappings = [
    (r'const\s+TextStyle\(fontSize:\s*32,\s*fontWeight:\s*FontWeight\.bold\)', r'Theme.of(context).textTheme.headlineLarge'),
    (r'const\s+TextStyle\(fontSize:\s*28,\s*fontWeight:\s*FontWeight\.bold\)', r'Theme.of(context).textTheme.headlineMedium'),
    (r'const\s+TextStyle\(fontSize:\s*24,\s*fontWeight:\s*FontWeight\.bold\)', r'Theme.of(context).textTheme.headlineSmall'),
    (r'const\s+TextStyle\(fontSize:\s*20,\s*fontWeight:\s*FontWeight\.bold\)', r'Theme.of(context).textTheme.titleLarge'),
    (r'const\s+TextStyle\(fontSize:\s*18,\s*fontWeight:\s*FontWeight\.bold\)', r'Theme.of(context).textTheme.titleMedium'),
    (r'const\s+TextStyle\(fontSize:\s*16,\s*fontWeight:\s*FontWeight\.bold\)', r'Theme.of(context).textTheme.titleSmall'),
    (r'const\s+TextStyle\(fontSize:\s*16\)', r'Theme.of(context).textTheme.bodyLarge'),
    (r'const\s+TextStyle\(fontSize:\s*14\)', r'Theme.of(context).textTheme.bodyMedium'),
    (r'const\s+TextStyle\(fontSize:\s*12\)', r'Theme.of(context).textTheme.labelSmall'),
]

for path in paths:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    original = content

    for pattern, replacement in const_mappings + mappings:
        content = re.sub(pattern, replacement, content)

    # We need to strip const from parent Text if we used Theme.of
    if content != original:
        content = re.sub(r'const\s+(Text\([^)]*Theme\.of\(context\))', r'\1', content)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

print("Typography centralized.")
