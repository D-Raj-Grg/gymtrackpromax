# GymTrack Pro

A native iOS workout tracking app built with SwiftUI and SwiftData.

## Features

- Structured workout splits (PPL, Upper/Lower, Bro Split, Full Body, Arnold Split)
- Set, rep, and weight logging with smart suggestions
- Rest timer with background notifications
- Progress charts and personal record tracking
- Calendar heatmap workout history
- Home screen widgets and Live Activities
- Custom split builder and exercise creation
- Data export (CSV)

## Tech Stack

- **Language:** Swift 5.9+
- **UI:** SwiftUI
- **Data:** SwiftData
- **Charts:** Swift Charts
- **Minimum iOS:** 17.0
- **Architecture:** MVVM + Clean Architecture
- **Dependencies:** None (Apple frameworks only)

## Build

```bash
# Open in Xcode
open gymtrackpromax.xcodeproj

# Build from command line
xcodebuild -scheme gymtrackpromax -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run tests
xcodebuild test -scheme gymtrackpromax -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## Project Structure

```
gymtrackpromax/
  App/           - App entry point, ContentView
  Models/        - SwiftData models and enums
  Views/         - SwiftUI views organized by feature
  ViewModels/    - Observable view models
  Services/      - Business logic and data services
  Utilities/     - Extensions, constants, formatters
  Resources/     - Assets, exercise seed data
```

## Architecture

The app follows MVVM with service-layer separation:

- **Views** observe `@Observable` ViewModels
- **ViewModels** coordinate between Views and Services
- **Services** handle business logic and SwiftData operations
- **Models** are `@Model` classes with computed properties

Data flows: User Action -> View -> ViewModel -> Service -> SwiftData -> Database
