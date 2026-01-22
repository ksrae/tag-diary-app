---
trigger: always_on
---

# Preferred File Editing Tools

## Overview
This rule mandates the use of specialized agentic tools for file modifications instead of fragile shell commands.

## Rules

### 1. No Shell-Based Editing
**Strictly prohibited** to use the following for editing or creating files:
- `echo`
- `sed`
- `awk`
- `printf`
- `cat > filename`
- `<<EOF` heredocs

**Why?**
- Usage of shell redaction allows for escaping issues, special character mismanagement, and encoding errors.
- It often leads to corrupt files or partial writes in complex codebases.

### 2. Preferred Tools
Instead, you **MUST** use the following tools:

#### Standard Editing
- **`replace_file_content`**: For contiguous block replacements.
- **`multi_replace_file_content`**: For multiple non-contiguous edits in a single file.
- **`write_to_file`**: For creating new files.

#### Advanced / Context-Aware Editing (Serena MCP)
Use **Serena MCP** tools for more robust, structural, or regex-based edits:
- **`mcp_serena_replace_content`**: For robust regex-based replacements (safer and more powerful than `sed`).
- **`mcp_serena_replace_symbol_body`**: For replacing entire functions/classes safely.
- **`mcp_serena_insert_before_symbol`** / **`mcp_serena_insert_after_symbol`**: For precise insertions around code entities.
- **`mcp_serena_rename_symbol`**: For safe renaming across the codebase.

### 3. LSP / Symbolic Editing
Always prefer symbolic or structural edits (via Serena tools) over raw text replacement when possible, as this respects the syntax and structure of the code.
