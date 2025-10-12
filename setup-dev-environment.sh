#!/bin/bash

# OpenProject Docker Compose - Development Environment Setup
# This script sets up the complete development environment for all repositories

set -e

echo "🚀 OpenProject Docker Compose - Development Setup"
echo "=================================================="

# Check if we're in the right directory
if [[ ! -f "openproject.code-workspace" ]]; then
    echo "❌ Error: Please run this script from the openproject-docker-compose root directory"
    echo "   (The directory containing openproject.code-workspace)"
    exit 1
fi

echo -e "\n📋 Setup Steps:"
echo "1. Initialize git submodules"
echo "2. Switch submodules to development branches"
echo "3. Install Python dependencies"
echo "4. Set up VS Code workspace"

# Step 1: Initialize submodules
echo -e "\n🔧 Step 1: Initializing git submodules..."
if git submodule status | grep -q "^-"; then
    echo "   Initializing submodules for the first time..."
    git submodule update --init --recursive
else
    echo "   Updating existing submodules..."
    git submodule update --remote --merge
fi

# Step 2: Switch submodules to main branches for development
echo -e "\n🌟 Step 2: Switching submodules to development branches..."
echo "   Config Manager..."
cd external/config-manager && git checkout main && cd ../..
echo "   Deploy Manager..."
cd external/deploy-manager && git checkout main && cd ../..
echo "   Prober..."
cd external/prober && git checkout main && cd ../..

# Step 3: Install Python dependencies
echo -e "\n🐍 Step 3: Setting up Python environment..."

# Check for config-manager dependencies
if [[ -f "external/config-manager/pyproject.toml" ]]; then
    echo "   Installing config-manager dependencies..."
    cd external/config-manager
    if [[ ! -d "venv" ]]; then
        python3 -m venv venv
    fi
    source venv/bin/activate
    pip install -e .[dev]
    pip install -e .
    deactivate
    cd ../..
fi

# Check for main project dependencies
if [[ -f "pyproject.toml" ]]; then
    echo "   Installing main project dependencies..."
    if [[ ! -d "venv" ]]; then
        python3 -m venv venv
    fi
    source venv/bin/activate
    pip install -e .[dev]
    deactivate
fi

# Step 4: VS Code workspace setup
echo -e "\n💻 Step 4: VS Code workspace information..."
echo "   ✅ VS Code workspace configured: openproject.code-workspace"
echo "   ✅ All 4 repositories available as separate folders"
echo "   ✅ Git submodule detection enabled"
echo "   ✅ Python paths configured for all components"

echo -e "\n📚 Available VS Code Tasks:"
echo "   • Run Tests (All Repos)"
echo "   • Format Code (Black - All Repos)" 
echo "   • Lint Code (Flake8 - All Repos)"
echo "   • Update Submodules"
echo "   • Initialize Submodules (First Time Setup)"
echo "   • Switch All Submodules to Main Branch"

echo -e "\n🎉 Setup Complete!"
echo -e "\n📖 Next Steps:"
echo "1. Open VS Code: code openproject.code-workspace"
echo "2. Install recommended extensions when prompted"
echo "3. Use Ctrl+Shift+P → 'Tasks: Run Task' for development tasks"

echo -e "\n🔧 Repository Structure:"
echo "├── openproject-docker-compose (main) - Main orchestration"
echo "├── external/config-manager         - Interactive configuration"
echo "├── external/deploy-manager         - Deployment utilities"
echo "└── external/prober                 - Docker environment probing"

echo -e "\n💡 Development Tips:"
echo "• Each external/ directory is a separate git repository"
echo "• Make changes in external/ directories and commit to their respective repos"
echo "• Use 'Update Submodules' task to sync latest changes"
echo "• Switch submodules to main branch for development (automated above)"