# Changelog

All notable changes to this project will be documented in this file.

## [3.0.0] - 2026-01-13

### Added
- **Robust CLI Detection**: Scripts now verify that binaries can actually execute (not just exist), detecting broken installations
- **Auto-Repair**: Automatically reinstalls broken/corrupted CLI tools
- **macOS Legacy Protection**: Blocks Node.js installation via Homebrew on macOS < 13 to prevent long compilation failures
- **Permission Warnings**: Proactive detection and warning when npm global installs require sudo
- **Cache Cleanup**: Automatic npm cache cleanup on errors to prevent corruption
- **Version Extraction**: Display actual version numbers for installed tools

### Changed
- **Complete UX Overhaul**: New 4-phase flow (Diagnosis → Plan → Execute → Validate)
- **Cleaner Output**: Silent installation with progress indicators, errors shown only when needed
- **User-Friendly Messages**: Replaced technical jargon with clear status indicators (Detectado, Instalado, Ausente, Quebrado)
- **README Links**: Help messages now point to GitHub documentation instead of showing raw flags
- **Improved Diagnostics**: Clear separation between system state and planned actions

### Fixed
- False positives for "installed" tools that don't actually run
- Redundant flag suggestions in output
- Confusing messages mixing state with action

## [2.0.1] - 2026-01-13

- Docs: use release URLs for install/uninstall commands and add supply chain guidance.
