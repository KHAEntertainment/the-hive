# Manual Directory Restructure Required

**Date**: 2025-01-08  
**Context**: Post-GitHub launch organizational restructure from notes file

## 🚨 Security Restrictions

Claude Code security restrictions prevent moving directories outside the current working directory. The following organizational restructure must be completed manually:

## Required Manual Steps

### Step 1: Rename Research Directory
```bash
# From any terminal (not within Claude Code):
cd "/Users/bbrenner/Documents/Scripting Projects/"
mv thehive thehive-research
```

### Step 2: Move Main Repository to Top-Level
```bash
# Still in Scripting Projects directory:
mv thehive-research/scripts/the-hive ./the-hive
```

### Step 3: Verify New Structure
After completion, you should have:
```
/Users/bbrenner/Documents/Scripting Projects/
├── thehive-research/        # Renamed research directory
│   └── scripts/             # (now empty of main repo)
└── the-hive/                # Main GitHub repository (top-level)
    ├── README.md
    ├── install.sh
    ├── scripts/
    └── ... (all GitHub repo files)
```

## Files to Update After Manual Restructure

### 1. Workspace Configuration
- File: `/Users/bbrenner/Documents/Scripting Projects/thehive/thehive.code-workspace`
- Update folder paths to reflect new structure

### 2. Documentation Systems
- Update any path references in coordination guides
- Update Claude.md files with new paths

### 3. Cross-references
- Update any hardcoded paths in scripts
- Verify git remotes are still correct

## Why This Restructure?

1. **Clean Separation**: Research directory separate from production repo
2. **Top-Level Access**: Main repo no longer nested within research
3. **Workspace Independence**: Both directories accessible in workspace
4. **Professional Organization**: Clear distinction between research and product

## Post-Completion Tasks

Once manual steps are complete, return to Claude Code to:
- Update workspace configuration
- Update documentation systems
- Archive the original notes file
- Test all paths and references

## Status

- ⏳ **Awaiting manual execution**
- 📍 **Current working directory**: `/Users/bbrenner/Documents/Scripting Projects/thehive/scripts/the-hive`
- 🎯 **Goal**: Clean organizational structure for ongoing development