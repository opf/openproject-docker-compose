# Git Submodules & VS Code Workspace Guide

## Overview

The OpenProject Python rebuild uses **git submodules** to include external repositories in a single VS Code workspace. This allows you to edit all repos simultaneously while maintaining independent git histories and CI/CD.

---

## Repository Structure

```
/opt/openproject/
├── .git/                           # Main repo git data
├── .gitmodules                     # Submodule configuration
├── openproject.code-workspace      # VS Code multi-root workspace
│
├── external/                       # Git submodules (external repos)
│   ├── config-manager/             # openproject-config-manager repo
│   │   ├── .git/                   # Separate git history
│   │   ├── README.md
│   │   └── src/
│   ├── deploy-manager/             # openproject-deploy-manager repo
│   │   ├── .git/                   # Separate git history
│   │   ├── README.md
│   │   └── src/
│   └── prober/                     # docker-prober-utility repo
│       ├── .git/                   # Separate git history
│       └── src/
│
├── src/openproject/                # Main repo code (maintenance manager)
├── tests/
├── docker-compose.yml
└── pyproject.toml
```

---

## Opening the Workspace

### Method 1: From Command Line

```bash
cd /opt/openproject
code openproject.code-workspace
```

### Method 2: From VS Code

1. Open VS Code
2. File → Open Workspace from File
3. Navigate to `/opt/openproject/openproject.code-workspace`
4. Click "Open"

### What You'll See

VS Code will show **4 workspace folders** in the Explorer:
- **openproject-docker-compose (main)** - Main integration repo
- **config-manager** - Configuration manager repo
- **deploy-manager** - Deployment manager repo
- **prober** - Validation utility repo

---

## Working with Submodules

### Editing Files

1. **Navigate in VS Code Explorer** to any folder
2. **Edit files** as normal (no special workflow)
3. **Save changes** (Ctrl+S / Cmd+S)

### Viewing Git Changes

VS Code Source Control panel will show **separate sections** for each repo:

```
SOURCE CONTROL
├─ openproject-docker-compose (main) - 2 changes
├─ config-manager - 1 change
├─ deploy-manager - 0 changes
└─ prober - 0 changes
```

Each repo tracks changes independently!

### Committing Changes

#### **Method 1: VS Code UI**

1. Click on Source Control panel (Ctrl+Shift+G)
2. Find the repo section with your changes
3. Stage files (click + icon)
4. Write commit message
5. Click ✓ Commit
6. Click "Sync Changes" or "Push" to push to remote

#### **Method 2: Terminal**

**Example: Edit config-manager**

```bash
cd /opt/openproject/external/config-manager
git add src/...
git commit -m "feat: implement discovery engine"
git push origin main
```

**Example: Edit main repo**

```bash
cd /opt/openproject
git add src/...
git commit -m "feat: update CLI"
git push origin feature/python-rebuild
```

### Which Repo Am I Committing To?

**Key Rule**: Your commit goes to the repo where the file lives!

- Files in `external/config-manager/` → Commits to `openproject-config-manager` repo
- Files in `external/deploy-manager/` → Commits to `openproject-deploy-manager` repo
- Files in `external/prober/` → Commits to `docker-prober-utility` repo
- Files in root or `src/` → Commits to `openproject-docker-compose` repo

### Updating Submodules

**Pull latest changes from all submodules:**

```bash
cd /opt/openproject
git submodule update --remote --merge
```

Or use VS Code task: `Ctrl+Shift+P` → `Tasks: Run Task` → `Update Submodules`

**Pull changes in specific submodule:**

```bash
cd /opt/openproject/external/config-manager
git pull origin main
```

### Switching Submodule Branches

```bash
# Switch config-manager to develop branch
cd /opt/openproject/external/config-manager
git checkout develop
git pull origin develop

# Now edits in VS Code will commit to develop branch
```

After switching, update main repo to track the new commit:

```bash
cd /opt/openproject
git add external/config-manager
git commit -m "chore: update config-manager to develop branch"
git push origin feature/python-rebuild
```

---

## Running Tests

### Test All Repos

```bash
# From main repo root
cd /opt/openproject
pytest

# Or use VS Code task: Ctrl+Shift+P → Run Task → Run Tests (All Repos)
```

### Test Specific Repo

```bash
# Test config-manager only
cd /opt/openproject/external/config-manager
pytest

# Test deploy-manager only
cd /opt/openproject/external/deploy-manager
pytest

# Test main repo only
cd /opt/openproject
pytest tests/
```

---

## Code Formatting & Linting

### Format All Code

```bash
cd /opt/openproject
black src tests external/*/src external/*/tests

# Or use VS Code task: Format Code (Black - All Repos)
```

### Lint All Code

```bash
cd /opt/openproject
flake8 src tests external/*/src external/*/tests

# Or use VS Code task: Lint Code (Flake8 - All Repos)
```

### Auto-Format on Save

The workspace is configured to auto-format Python files when you save (Ctrl+S).

---

## CI/CD Behavior

### Each Repo Triggers Its Own CI

**When you push to config-manager:**
```bash
cd /opt/openproject/external/config-manager
git push origin main
```
→ Triggers **openproject-config-manager** CI on GitHub
→ Runs tests in that repo only

**When you push to main repo:**
```bash
cd /opt/openproject
git push origin feature/python-rebuild
```
→ Triggers **openproject-docker-compose** CI on GitHub
→ Runs tests in main repo only

### Viewing CI Status

- **Config Manager CI**: https://github.com/JustinCBates/openproject-config-manager/actions
- **Deploy Manager CI**: https://github.com/JustinCBates/openproject-deploy-manager/actions
- **Prober CI**: https://github.com/JustinCBates/docker_prober_utility/actions
- **Main Repo CI**: https://github.com/JustinCBates/openproject-docker-compose/actions

---

## Version Pinning

### How Main Repo Tracks Submodules

The main repo tracks **specific commits** of each submodule:

```bash
cd /opt/openproject
git ls-tree HEAD external/

# Output:
# 160000 commit b34f60a... external/config-manager
# 160000 commit dcdb4ed... external/deploy-manager
# 160000 commit abc1234... external/prober
```

This means:
- Main repo uses config-manager at commit `b34f60a`
- If someone updates config-manager, main repo still uses `b34f60a` until you update it

### Updating Submodule Version

```bash
# Update config-manager to latest
cd /opt/openproject/external/config-manager
git pull origin main  # Now at new commit xyz789

# Update main repo to track new commit
cd /opt/openproject
git add external/config-manager
git commit -m "chore: update config-manager to xyz789"
git push origin feature/python-rebuild
```

---

## Cloning for New Contributors

### Clone with Submodules

```bash
git clone --recurse-submodules https://github.com/JustinCBates/openproject-docker-compose.git
cd openproject-docker-compose
git checkout feature/python-rebuild
```

### Already Cloned? Initialize Submodules

```bash
cd /opt/openproject
git submodule update --init --recursive
```

### Open Workspace

```bash
code openproject.code-workspace
```

---

## Common Workflows

### Scenario 1: Add New Feature to Config Manager

```bash
# 1. Edit files in VS Code (external/config-manager/src/...)
# 2. Save changes

# 3. Commit to config-manager
cd /opt/openproject/external/config-manager
git add src/...
git commit -m "feat: add new feature"
git push origin main

# 4. Update main repo to track new commit (optional, for now)
cd /opt/openproject
git add external/config-manager
git commit -m "chore: update config-manager to latest"
git push origin feature/python-rebuild
```

### Scenario 2: Update Main Repo Only

```bash
# 1. Edit files in VS Code (src/openproject/...)
# 2. Save changes

# 3. Commit to main repo
cd /opt/openproject
git add src/...
git commit -m "feat: update main repo"
git push origin feature/python-rebuild
```

### Scenario 3: Update Dependency in pyproject.toml

```bash
# Edit /opt/openproject/pyproject.toml
# Update version of external repo dependency

cd /opt/openproject
git add pyproject.toml
git commit -m "chore: update config-manager dependency to v0.2.0"
git push origin feature/python-rebuild
```

---

## Troubleshooting

### Submodule Shows as "Modified" But I Didn't Change It

**Cause**: You switched branches in the submodule

**Fix**:
```bash
# Option 1: Update main repo to track new branch/commit
cd /opt/openproject
git add external/config-manager
git commit -m "chore: update submodule ref"

# Option 2: Reset submodule to tracked commit
git submodule update --init
```

### VS Code Shows Wrong Git Repo

**Cause**: Terminal is in wrong directory

**Fix**: Check your current directory
```bash
pwd  # Should be /opt/openproject for main repo
     # Or /opt/openproject/external/config-manager for config-manager
```

### Can't See Submodule Files in VS Code

**Cause**: Submodules not initialized

**Fix**:
```bash
cd /opt/openproject
git submodule update --init --recursive
```

Then reload VS Code (Ctrl+Shift+P → Reload Window)

---

## Best Practices

1. ✅ **Commit to correct repo**: Always check which repo owns the file you're editing
2. ✅ **Push changes promptly**: Each repo's CI needs to run independently
3. ✅ **Update submodules regularly**: Pull latest changes from external repos
4. ✅ **Test before committing**: Run tests in the repo you're changing
5. ✅ **Write clear commit messages**: Each repo has its own history
6. ✅ **Use VS Code tasks**: Automated tasks for common operations

---

## VS Code Extensions (Recommended)

The workspace recommends these extensions (VS Code will prompt to install):

- **Python** - Python language support
- **Pylance** - Fast Python language server
- **Black Formatter** - Auto-format Python code
- **Flake8** - Python linting
- **Mypy** - Type checking
- **GitLens** - Enhanced Git features
- **Git History** - View git log and file history
- **Markdown All in One** - Markdown editing

---

## Summary

✅ **4 repos in 1 workspace** (main, config-manager, deploy-manager, prober)  
✅ **Independent git histories** (each repo commits/pushes separately)  
✅ **Independent CI/CD** (each repo triggers its own tests)  
✅ **Easy navigation** (all code in one VS Code window)  
✅ **Version pinning** (main repo tracks specific commits of submodules)

**Happy coding!** 🚀
