---
type: regex
target: {source: file, path: .git/logs/HEAD}
pattern: 'commit: Stand 20\d\d-\d\d-\d\d \d\d:\d\d'
match: contains
weight: 1
---
