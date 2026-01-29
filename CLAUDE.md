# CLAUDE.md - GymTrack Pro iOS Project Guide

> **Purpose:** This file provides context and guidance for Claude Code sessions working on the GymTrack Pro iOS application. Read this file at the start of every session.

---

## 📱 Project Overview

**App Name:** GymTrack Pro  
**Platform:** iOS Native  
**Language:** Swift 5.9+  
**UI Framework:** SwiftUI  
**Data Persistence:** SwiftData  
**Minimum iOS:** 17.0  
**IDE:** Xcode 15+  
**Architecture:** MVVM + Clean Architecture

### What This App Does

GymTrack Pro is a gym workout tracking app that helps users:

- Follow structured workout splits (PPL, Upper/Lower, Bro Split, etc.)
- Log sets, reps, and weights during workouts
- Track progress with charts and personal records
- Maintain workout streaks and stay motivated

---

## 🏗️ Project Structure

```
GymTrackPro/
├── App/
│   ├── GymTrackProApp.swift          # Main app entry, SwiftData container
│   ├── ContentView.swift             # Root view with navigation
│   └── AppState.swift                # Global app state
├── Models/
│   ├── User.swift                    # User profile and preferences
│   ├── WorkoutSplit.swift            # Workout split configuration
│   ├── WorkoutDay.swift              # Individual workout day
│   ├── Exercise.swift                # Exercise definitions
│   ├── PlannedExercise.swift         # Exercises planned for a day
│   ├── WorkoutSession.swift          # Logged workout session
│   ├── ExerciseLog.swift             # Logged exercise in session
│   ├── SetLog.swift                  # Individual set data
│   └── Enums/
│       ├── WeightUnit.swift
│       ├── MuscleGroup.swift
│       ├── Equipment.swift
│       ├── SplitType.swift
│       ├── ExperienceLevel.swift
│       └── FitnessGoal.swift
├── Views/
│   ├── Onboarding/
│   │   ├── SplashView.swift
│   │   ├── WelcomeCarouselView.swift
│   │   ├── UserInfoView.swift
│   │   ├── GoalSelectionView.swift
│   │   ├── SplitSelectionView.swift
│   │   ├── ScheduleCustomizationView.swift
│   │   └── OnboardingCompleteView.swift
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   ├── TodayWorkoutCard.swift
│   │   ├── StreakCard.swift
│   │   └── QuickStatsView.swift
│   ├── Workout/
│   │   ├── ActiveWorkoutView.swift
│   │   ├── ExerciseLogView.swift
│   │   ├── SetInputView.swift
│   │   ├── RestTimerView.swift
│   │   └── WorkoutSummaryView.swift
│   ├── History/
│   │   ├── HistoryView.swift
│   │   ├── CalendarHeatmapView.swift
│   │   └── WorkoutDetailView.swift
│   ├── Progress/
│   │   ├── ProgressView.swift
│   │   ├── ExerciseChartView.swift
│   │   └── PRListView.swift
│   ├── Profile/
│   │   ├── ProfileView.swift
│   │   └── SettingsView.swift
│   └── Components/
│       ├── PrimaryButton.swift
│       ├── SecondaryButton.swift
│       ├── WorkoutCard.swift
│       ├── ExerciseRow.swift
│       ├── SetRow.swift
│       ├── TimerDisplay.swift
│       └── StatCard.swift
├── ViewModels/
│   ├── OnboardingViewModel.swift
│   ├── DashboardViewModel.swift
│   ├── WorkoutViewModel.swift
│   ├── HistoryViewModel.swift
│   ├── ProgressViewModel.swift
│   └── ProfileViewModel.swift
├── Services/
│   ├── DataService.swift             # SwiftData operations
│   ├── WorkoutService.swift          # Workout business logic
│   ├── ExerciseService.swift         # Exercise database operations
│   ├── NotificationService.swift     # Local notifications
│   ├── HealthKitService.swift        # Apple Health integration
│   └── CloudSyncService.swift        # CloudKit sync (Phase 3)
├── Utilities/
│   ├── Extensions/
│   │   ├── Color+Theme.swift
│   │   ├── Date+Formatting.swift
│   │   ├── Double+Formatting.swift
│   │   └── View+Modifiers.swift
│   ├── Constants.swift
│   ├── Formatters.swift
│   └── OneRepMaxCalculator.swift
├── Resources/
│   ├── Assets.xcassets/
│   ├── ExerciseData.json             # Seed data for exercises
│   └── Localizable.strings
└── Tests/
    ├── ModelTests/
    ├── ViewModelTests/
    └── ServiceTests/
```

---

## 🎨 Design System

### Color Palette

```swift
// Use these colors consistently throughout the app
Color.gymBackground    // #0F172A - Main background
Color.gymCard          // #1E293B - Card/surface background
Color.gymCardHover     // #334155 - Hover/pressed state
Color.gymPrimary       // #6366F1 - Primary actions (Indigo)
Color.gymPrimaryLight  // #818CF8 - Primary light variant
Color.gymAccent        // #22D3EE - Accent/highlight (Cyan)
Color.gymSuccess       // #10B981 - Success states (Green)
Color.gymWarning       // #F59E0B - Warning states (Amber)
Color.gymText          // #F8FAFC - Primary text (White)
Color.gymTextMuted     // #94A3B8 - Secondary text (Gray)
Color.gymBorder        // #334155 - Border color
```

### Typography

- **Large Titles:** `.largeTitle` with `.bold()`
- **Headings:** `.title2` or `.title3` with `.semibold()`
- **Body:** `.body` regular
- **Captions:** `.caption` with `.gymTextMuted` color
- **Numbers (weights/reps):** `.system(.title, design: .monospaced)`

### Spacing

- Standard padding: 16px
- Card padding: 16-20px
- Section spacing: 24px
- Component gap: 12px

### Corner Radius

- Cards: 16-20px
- Buttons: 12px
- Input fields: 12px
- Small elements: 8px

---

## 📊 Data Models Quick Reference

### Core Relationships

```
User
 └── WorkoutSplit[] (one-to-many)
      └── WorkoutDay[] (one-to-many)
           └── PlannedExercise[] (one-to-many)
                └── Exercise (many-to-one)

User
 └── WorkoutSession[] (one-to-many)
      └── ExerciseLog[] (one-to-many)
           └── SetLog[] (one-to-many)
```

### Key Model Properties

**SetLog** (most frequently created):

```swift
- setNumber: Int
- weight: Double
- reps: Int
- rpe: Int? (1-10)
- isWarmup: Bool
- isDropset: Bool
- timestamp: Date
```

**WorkoutSession**:

```swift
- startTime: Date
- endTime: Date?
- duration: TimeInterval? (computed)
- totalVolume: Double (computed)
```

---

## ⚙️ Key Implementation Patterns

### 1. SwiftData Usage

```swift
// Always inject ModelContext via environment
@Environment(\.modelContext) private var modelContext

// Query data with @Query macro
@Query(sort: \WorkoutSession.startTime, order: .reverse)
private var sessions: [WorkoutSession]

// Insert new objects
let session = WorkoutSession(workoutDay: day)
modelContext.insert(session)

// Save changes (usually automatic, but can force)
try? modelContext.save()
```

### 2. ViewModel Pattern

```swift
@Observable
class SomeViewModel {
    var state: SomeState
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func someAction() async {
        // Perform action
    }
}
```

### 3. Navigation

```swift
// Use NavigationStack with path-based navigation
@State private var path = NavigationPath()

NavigationStack(path: $path) {
    ContentView()
        .navigationDestination(for: WorkoutDay.self) { day in
            ActiveWorkoutView(workoutDay: day)
        }
}
```

### 4. Async Operations

```swift
// Use Task for async work in views
.task {
    await viewModel.loadData()
}

// Use async/await in ViewModels
func loadData() async {
    isLoading = true
    defer { isLoading = false }
    // Load data...
}
```

---

## 🔑 Important Business Logic

### 1RM Calculation (Epley Formula)

```swift
func calculate1RM(weight: Double, reps: Int) -> Double {
    guard reps > 0 else { return 0 }
    if reps == 1 { return weight }
    return weight * (1 + Double(reps) / 30)
}
```

### Volume Calculation

```swift
// Total volume = sum of (weight × reps) for all working sets
var totalVolume: Double {
    sets.filter { !$0.isWarmup }
        .reduce(0) { $0 + ($1.weight * Double($1.reps)) }
}
```

### Streak Calculation

```swift
// Count consecutive days with workouts from today backwards
func calculateStreak(sessions: [WorkoutSession]) -> Int {
    // Group by calendar day, check continuity
}
```

---

## 🚫 Common Pitfalls to Avoid

1. **Don't use `@State` for complex objects** - Use `@Observable` ViewModels instead

2. **Don't forget `@MainActor`** - UI updates must be on main thread

   ```swift
   @MainActor
   func updateUI() { ... }
   ```

3. **Don't hardcode colors** - Always use the theme colors from `Color+Theme.swift`

4. **Don't skip haptic feedback** - Add haptics for:
   - Button taps: `.impact(style: .light)`
   - Set logged: `.notification(type: .success)`
   - PR achieved: `.notification(type: .success)` + stronger

5. **Don't ignore safe areas** - Use `.ignoresSafeArea()` sparingly and intentionally

6. **Don't forget loading states** - Show progress indicators for async operations

7. **Don't use force unwrapping** - Use optional binding or provide defaults

---

## ✅ Code Style Guidelines

### Naming Conventions

- **Views:** `SomethingView.swift` (e.g., `DashboardView.swift`)
- **ViewModels:** `SomethingViewModel.swift`
- **Services:** `SomethingService.swift`
- **Extensions:** `Type+Feature.swift` (e.g., `Color+Theme.swift`)

### File Organization

```swift
// 1. Import statements
import SwiftUI
import SwiftData

// 2. MARK comments for sections
// MARK: - Properties
// MARK: - Body
// MARK: - Subviews
// MARK: - Actions

// 3. Preview at bottom
#Preview {
    SomeView()
}
```

### SwiftUI Best Practices

```swift
// Extract subviews for readability
var body: some View {
    VStack {
        headerSection
        contentSection
        footerSection
    }
}

private var headerSection: some View {
    // ...
}
```

---

## 🧪 Testing Guidelines

### What to Test

1. **Models:** Computed properties, validation logic
2. **ViewModels:** Business logic, state changes
3. **Services:** Data operations, calculations
4. **DO NOT test:** SwiftUI views directly (use previews instead)

### Test Naming

```swift
func test_calculate1RM_withValidInput_returnsCorrectValue() {
    // Arrange, Act, Assert
}
```

---

## 📋 Current Development Phase

**Phase 1 - MVP (v1.0)** ← CURRENT

- [x] Project setup
- [ ] SwiftData models
- [ ] Onboarding flow
- [ ] Dashboard view
- [ ] Active workout logging
- [ ] Rest timer
- [ ] History view
- [ ] Basic progress charts

See PRD for complete roadmap.

---

## 🔧 Common Tasks

### Adding a New Screen

1. Create `SomethingView.swift` in appropriate Views folder
2. Create `SomethingViewModel.swift` if needed
3. Add navigation destination in parent view
4. Add to tab bar if it's a main screen

### Adding a New Model Property

1. Add property to model class
2. SwiftData handles migration automatically for simple additions
3. Update any affected ViewModels
4. Update UI to display/edit the property

### Adding a New Exercise to Database

1. Update `ExerciseData.json`
2. Run seed function on first launch (checks if exercises exist)

---

## 📚 Reference Documents

- **PRD:** `gym_tracker_prd_swift.md` - Full product requirements
- **Figma Prompts:** `figma_make_prompts.md` - UI design prompts
- **Apple Docs:** [SwiftData](https://developer.apple.com/documentation/swiftdata), [SwiftUI](https://developer.apple.com/documentation/swiftui)

---

## 💡 Tips for Claude Code Sessions

1. **Always check this file first** for project context

2. **Reference the PRD** for feature requirements and specifications

3. **Use the established patterns** - Don't introduce new architectural patterns without good reason

4. **Maintain consistency** - Match existing code style and naming

5. **Test in previews** - Use SwiftUI previews to verify UI changes

6. **Consider accessibility** - Add accessibility labels and hints

7. **Think about edge cases:**
   - Empty states (no workouts, no history)
   - Error states (data loading failed)
   - First-time user experience

8. **When in doubt, ask** - Request clarification rather than making assumptions

---

## 🚀 Quick Start Commands

```bash
# Open project in Xcode
open GymTrackPro.xcodeproj

# Build project (Cmd+B in Xcode)
xcodebuild -scheme GymTrackPro -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run tests
xcodebuild test -scheme GymTrackPro -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

---

_Last Updated: January 2026_  
_Project Version: 1.0 (Development)_

- Always read the PLANNING.md at the start of every new conversation
- Check TASKS.md before starting your work
- Mark completed tasks immediately
- Add newly discovered tasks
