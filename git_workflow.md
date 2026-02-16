# Git Workflow — Pocket Dragon

## Checkpoint Workflow

When you say **"Please commit everything"**, the following steps execute:

### 1. Status Check
```bash
git status
```
Review all staged, unstaged, and untracked changes.

### 2. Secret Scan (CRITICAL — runs before every commit)

The workspace is scanned for:
- `.env` files
- Private key blocks (`-----BEGIN.*PRIVATE KEY-----`)
- API keys / tokens (patterns like `sk-`, `ghp_`, `AKIA`, etc.)
- OAuth secrets
- Cloud credentials (AWS, GCP, Azure)
- Database connection strings with passwords
- Certificate files (`.key`, `.pem`, `.p12`, `.pfx`)

**If secrets are found:**
- Commit is BLOCKED
- Files are listed with warnings
- `.gitignore` updates are recommended
- User must explicitly confirm before proceeding

### 3. Stage Files
```bash
git add <specific files>
```
Files are staged individually — never `git add -A` blindly.

### 4. Commit
```bash
git commit -m "chore(checkpoint): update progress + dashboards"
```

### 5. Push (conditional)
Push only executes if:
- Remote `origin` exists
- Authentication succeeds
- Branch tracking is set up

If push fails, exact next-steps are printed.

## Commit Message Format

```
<type>(<scope>): <short description>

[optional body]
```

### Types
| Type | When |
|------|------|
| `feat` | New gameplay feature or system |
| `fix` | Bug fix |
| `refactor` | Code restructuring, no behavior change |
| `chore` | Tooling, config, project maintenance |
| `art` | Assets: models, textures, audio |
| `docs` | Documentation updates |
| `test` | Adding or updating tests |

### Scope Examples
`battle`, `overworld`, `party`, `ui`, `data`, `save`, `audio`, `checkpoint`

## Safety Warnings

- **Never force-push** (`--force` or `--force-with-lease`) without explicit confirmation
- **Never amend published commits** — create new commits instead
- **Never commit secrets** — the secret scan catches these, but stay vigilant
- **Never skip hooks** (`--no-verify`) without explicit confirmation
- **Never run `git reset --hard`** or `git clean -f` without explicit confirmation

## Branch Strategy (Recommended)

```
main           ← stable checkpoints
  └── dev      ← active development
       └── feature/xyz  ← specific features
```

Currently: single `main` branch (appropriate for solo early development).

## .gitignore Coverage

The `.gitignore` protects against committing:
- Godot editor cache (`.godot/`)
- Secret files (`.env`, `*.key`, `*.pem`, `*.p12`, `*.pfx`)
- Build artifacts
- OS junk files
- Node modules (if any web tooling is added)

See `.gitignore` for the full list.
