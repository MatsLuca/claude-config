---
type: regex
target: {source: file, path: CLAUDE.md}
pattern: '^## Aktueller Stand \((?!2026-08-01)\d{4}-\d\d-\d\d\)'
flags: m
match: contains
weight: 1
---
