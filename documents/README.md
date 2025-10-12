# OpenProject Docker Compose - Documentation

This directory contains all design documents, architectural specifications, guides, and project documentation for the OpenProject Docker Compose system.

## 📁 Directory Structure

### 🏗️ **architecture/**
System architecture and design specifications
- `ARCHITECTURE.md` - Comprehensive system architecture and component interactions
- `INTERACTIVE_CONFIG_ARCHITECTURE.md` - Interactive configuration system design

### 🎨 **design/**  
Design specifications and workflow documentation
- `CONFIG_VARIABLE_FLOW.md` - Configuration variable flow and management design

### 📚 **guides/**
User and developer guides  
- `SUBMODULES_GUIDE.md` - Guide for working with Git submodules
- `MANAGER_FOLDERS.md` - Guide to manager component organization

### 🔄 **migration/**
Migration plans and rebuild documentation
- `MIGRATION_PLAN.md` - Comprehensive migration strategy and implementation plan
- `PYTHON_REBUILD.md` - Python rebuild phases and progress tracking

### 📋 **project/**
Project overview and summary documentation
- `PROJECT_OVERVIEW.md` - Complete project overview and component descriptions  
- `MULTI_REPO_SUMMARY.md` - Multi-repository structure and relationships

## 🎯 **Document Categories**

### **For Developers**
- Start with `project/PROJECT_OVERVIEW.md` for system understanding
- Review `architecture/ARCHITECTURE.md` for technical details
- Check `guides/` for development workflows
- Reference `migration/` for current development status

### **For System Administrators**
- Begin with `project/PROJECT_OVERVIEW.md` for deployment context
- Review `guides/SUBMODULES_GUIDE.md` for repository management
- Check `architecture/` for system design understanding

### **For Contributors**
- Read `project/MULTI_REPO_SUMMARY.md` for repository structure
- Study `migration/MIGRATION_PLAN.md` for development roadmap
- Review `design/` for workflow specifications

## 🔗 **Cross-References**

Many documents reference each other. Key relationships:
- `PROJECT_OVERVIEW.md` ↔ `ARCHITECTURE.md` (overview ↔ details)
- `MIGRATION_PLAN.md` ↔ `PYTHON_REBUILD.md` (planning ↔ execution)
- `MULTI_REPO_SUMMARY.md` ↔ `SUBMODULES_GUIDE.md` (structure ↔ workflow)

## 📝 **Maintenance**

This documentation is actively maintained and updated as the system evolves. When making changes:

1. **Update cross-references** if moving or renaming documents
2. **Maintain consistency** across related documents
3. **Update this README** when adding new document categories
4. **Keep architecture and overview docs in sync** with actual implementation

## 🚀 **Getting Started**

**New to the project?** Start here:
1. `project/PROJECT_OVERVIEW.md` - Understand what this system does
2. `architecture/ARCHITECTURE.md` - Learn how it works
3. `guides/SUBMODULES_GUIDE.md` - Set up your development environment
4. `migration/PYTHON_REBUILD.md` - See current development status

The documentation is organized to support both high-level understanding and deep technical implementation details.