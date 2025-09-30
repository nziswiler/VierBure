# Vier Bure - Architecture Documentation

## Overview
The Vier Bure app is a SwiftUI-based scoreboard application built following MVVM architecture and modern iOS development best practices.

## Architecture

### MVVM Pattern
- **Models**: Pure data structures in the `Models/` folder
- **ViewModels**: Business logic and state management in `ViewModels/`
- **Views**: UI components organized by responsibility in `Views/`

### Project Structure
```
VierBure/
├── Models/
│   ├── RoundScore.swift
│   ├── Player.swift
│   └── GameConstants.swift
├── ViewModels/
│   └── ScoreboardViewModel.swift
├── Services/
│   └── GameDataManager.swift
├── Utilities/
│   └── ScoreValidator.swift
├── Views/
│   ├── ScoreboardView.swift
│   ├── Components/
│   │   ├── ScoreCell.swift
│   │   ├── ScoreTextField.swift
│   │   ├── CustomKeyboard.swift
│   │   ├── KeyboardButton.swift
│   │   ├── KeyboardConfiguration.swift
│   │   ├── HeaderRow.swift
│   │   ├── ScoreTable.swift
│   │   ├── ScoreRow.swift
│   │   ├── RoundControls.swift
│   │   └── TotalsRow.swift
│   ├── Sheets/
│   │   ├── NamesSheet.swift
│   │   └── PlayerCountSheet.swift
│   └── Extensions/
│       └── ViewExtensions.swift
├── ContentView.swift
└── VierBureApp.swift
```

## Key Design Decisions

### 1. Separation of Concerns
- **Models**: Pure data with computed properties and helper methods
- **ViewModels**: Handle business logic, validation, and data persistence
- **Views**: Focus only on UI presentation and user interaction

### 2. Data Persistence
- Protocol-based `GameDataManagerProtocol` for testability
- JSON encoding/decoding for complex game state
- UserDefaults for simple data like player names
- Auto-save functionality with debouncing to prevent excessive writes

### 3. Input Validation
- Centralized validation logic in `ScoreValidator`
- Type-safe validation results with proper error handling
- Input bounds checking and sanitization

### 4. Performance Optimizations
- `LazyVStack` for efficient list rendering
- `@Published` properties with granular updates
- Debounced auto-save to prevent excessive I/O
- Proper use of `@MainActor` for UI updates

### 5. Accessibility
- Comprehensive VoiceOver support
- Semantic accessibility labels and hints
- Proper accessibility traits and grouping
- Keyboard navigation support

### 6. Error Handling
- Structured error types with localized descriptions
- Graceful degradation for data corruption
- User-friendly error messages

## Benefits of This Architecture

### Maintainability
- Clear separation of responsibilities
- Small, focused files that are easy to understand
- Consistent naming conventions and patterns

### Testability
- Protocol-based dependencies allow for easy mocking
- ViewModels can be tested independently of UI
- Pure functions in validators and utilities

### Scalability
- Modular component structure supports easy feature additions
- Reusable UI components can be shared across views
- Clear data flow makes it easy to add new features

### Performance
- Efficient state management minimizes unnecessary updates
- Lazy loading and proper SwiftUI practices
- Debounced operations prevent excessive work

### Accessibility
- Built-in accessibility support throughout the app
- Consistent accessibility patterns
- Proper semantic markup

## Future Enhancements
- Unit tests for ViewModels and utilities
- UI tests for critical user flows
- Additional game modes or scoring systems
- Export functionality for game results
- iCloud sync for cross-device gameplay