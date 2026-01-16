---
name: report
description: Generate or view audit reports from previous vigilo analyses. Lists available reports or exports a specific report in various formats.
---

# /vigilo:report - Report Management

View and manage vigilo audit reports.

## Arguments

- `$ARGUMENTS` - Optional: Report action
  - (empty) - List all available reports
  - `{filename}` - View specific report
  - `export {filename} {format}` - Export report (md/html/pdf)

## Actions

### List Reports

When no arguments provided:
```
Glob(".vigilo/**/*.md")
```

Display:
```
## Available Reports

### Reconnaissance
| Date | File | Summary |
|------|------|---------|
| 2026-01-14 | recon/2026_01_14_1430.md | Pool.sol analysis |

### Audits
| Date | File | Findings |
|------|------|----------|
| 2026-01-14 | audit/2026_01_14_1500.md | 2 High, 3 Medium |
```

### View Report

When filename provided:
```
Read(".vigilo/{filename}")
```

Display the full report content.

### Export Report

When `export {filename} {format}` provided:

For Markdown (default):
- Already in `.md` format, just copy to desired location

For HTML:
```markdown
<!DOCTYPE html>
<html>
<head>
  <title>{report_title}</title>
  <style>
    body { font-family: system-ui; max-width: 800px; margin: 0 auto; padding: 2rem; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    .critical { color: #dc2626; }
    .high { color: #ea580c; }
    .medium { color: #ca8a04; }
    .low { color: #16a34a; }
  </style>
</head>
<body>
{converted_content}
</body>
</html>
```

## Output

Reports are stored in:
```
.vigilo/
├── recon/           # Reconnaissance reports
│   └── {timestamp}.md
└── audit/           # Audit reports
    └── {timestamp}.md
```
