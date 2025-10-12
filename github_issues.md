# GitHub Issues for TUI Flow Designer Features

Copy these into GitHub Issues at: https://github.com/JustinCBates/openproject-docker-compose/issues

---

## Issue 1: Hot-reload YAML Flow Editor

**Labels:** `enhancement`, `tui-designer`, `developer-experience`

### Description
Implement file watching and hot-reload functionality for the TUI Flow Designer to enable real-time design iteration.

### Features
- File system watcher (watchdog/inotify) for `.layout.yml` files
- Live preview updates when files change
- Preserve current step position during reload
- Auto-validation on file changes
- Real-time design feedback loop

### Benefits
- Faster design iteration
- Immediate visual feedback
- No need to restart flow for changes
- Improved developer experience

### Technical Notes
- Integrate with existing `run_flow_direct.py` tool
- Use Python `watchdog` library for file monitoring
- Maintain user session state across reloads

---

## Issue 2: Enhanced Design Mode Tools

**Labels:** `enhancement`, `tui-designer`, `testing`, `debugging`

### Description
Extend the direct flow runner with advanced design and testing features.

### Features
- Save/load response sets for consistent testing
- Step-by-step debugging (pause at each step)
- Conditional logic testing (force condition states)
- Response validation preview
- Flow performance metrics
- Export test scenarios

### Benefits
- Comprehensive testing capabilities
- Debug complex conditional flows
- Reproducible test scenarios
- Performance optimization insights

### Technical Notes
- Extend `run_flow_direct.py`
- Add JSON export/import for response sets
- Implement step-by-step execution mode

---

## Issue 3: Visual Flow Designer

**Labels:** `enhancement`, `gui`, `user-experience`, `non-technical-users`

### Description
Create a GUI-based flow designer for non-technical users to build TUI flows visually.

### Features
- Drag-and-drop step creation
- Visual conditional logic builder
- Real-time preview pane
- Step validation indicators
- Export to YAML format
- Import existing layouts

### Benefits
- Accessible to non-developers
- Visual representation of flow logic
- Reduced YAML syntax errors
- Faster prototyping

### Technical Notes
- Consider web-based interface (Flask/FastAPI)
- Alternative: Desktop app (tkinter/PyQt)
- Integration with existing YAML schema

---

## Issue 4: Flow Analytics Dashboard

**Labels:** `enhancement`, `analytics`, `user-experience`, `optimization`

### Description
Analytics and insights system for flow performance and user experience optimization.

### Features
- Step completion rates tracking
- User drop-off point analysis
- Response time analytics
- A/B testing framework
- User experience heatmaps
- Conversion optimization suggestions

### Benefits
- Data-driven flow optimization
- Identify UX pain points
- Improve completion rates
- Better user experience

### Technical Notes
- Require telemetry collection system
- Dashboard interface (web-based)
- Privacy-conscious implementation

---

## Issue 5: TUI Engine Debugging

**Labels:** `bug`, `investigation`, `tui-engine`, `hanging-issue`

### Description
Investigate and fix the hanging issue in the original TUI engine that prevents interactive flow execution.

### Current Issue
- TUI engine hangs at "Preparing form..." stage
- Conditional step processing appears problematic
- YAML structure validation passes, but execution fails

### Investigation Tasks
- Debug conditional step processing logic
- Fix step validation hanging
- Improve error handling and timeouts
- Add debugging instrumentation
- Performance optimization

### Benefits
- Restore full TUI engine functionality
- Enable production-ready interactive flows
- Better error reporting and recovery

### Technical Notes
- Focus on `FormRenderer` class execution
- Investigate conditional logic evaluation
- Add timeout mechanisms and error recovery

---

## Project Milestones

### Phase 1: Core Functionality
- [ ] Issue 5: TUI Engine Debugging
- [ ] Issue 1: Hot-reload YAML Flow Editor

### Phase 2: Enhanced Development
- [ ] Issue 2: Enhanced Design Mode Tools
- [ ] Issue 3: Visual Flow Designer

### Phase 3: Analytics & Optimization
- [ ] Issue 4: Flow Analytics Dashboard

---

## Contributing
These features build upon the TUI Form Designer architecture with separate engine and editor components. All features should maintain backward compatibility with existing `.layout.yml` files.

For implementation details, see:
- `src/tui_form_engine/` - Core engine
- `external/config-manager/run_flow_direct.py` - Direct runner tool
- `external/config-manager/src/openproject_config_manager/collector/config_tui.layout.yml` - Example layout