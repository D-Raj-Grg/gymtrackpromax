# Enhanced Workout Selection Experience

> **Purpose:** Implementation plan for improving the workout selection UI in GymTrack Pro

---

## Overview

Improve the workout selection UI with better visual hierarchy, preview sheets, favorites, recent workouts, and muscle group filters.

**User Requirements:**
1. Better Workout List UI with clearer cards and visual hierarchy
2. Enhanced Tab View with sections (Today, Quick Access, All Workouts)
3. Workout Preview Sheet (see exercises before starting)
4. Favorites/Quick Access (pin favorite workouts)
5. Recent Workouts (show recently completed for easy repeat)

---

## MVP Features (Priority Order)

### 1. Workout Preview Sheet
- Tap any workout day → shows preview modal with full exercise list
- Preview includes: workout name, muscle groups, exercises with sets/reps/rest
- Actions: "Start Workout" button, favorite toggle, close

### 2. Better Workout Day Cards
- Enhanced card design with muscle group chips prominently displayed
- Show "last completed" indicator (e.g., "2 days ago")
- Favorite star icon on each card
- Visual hierarchy: TODAY badge, stats row, muscle groups

### 3. Favorites System
- Add `isFavorite: Bool` to WorkoutDay model
- Toggle favorite from card or preview sheet
- Persist favorites across sessions

### 4. Quick Access Section
- New section showing: Favorites + Recent Workouts (last 5 unique)
- Horizontal scrolling cards for quick access
- Badges: "Favorite" (star), "2 days ago" (recent)

### 5. Muscle Group Filter Chips
- Horizontal scrollable filter: All | Chest | Back | Legs | Shoulders | Arms
- Filter the "All Workouts" list by selected muscle groups
- Clear filter by tapping "All"

---

## Files to Modify

### Data Models

1. **`gymtrackpromax/Models/WorkoutDay.swift`**
   ```swift
   // Add property
   var isFavorite: Bool = false

   // Add computed properties
   var daysSinceLastCompleted: Int? {
       guard let lastSession = lastSession else { return nil }
       return Calendar.current.dateComponents([.day], from: lastSession.startTime, to: Date()).day
   }

   var lastCompletedDisplay: String? {
       guard let days = daysSinceLastCompleted else { return nil }
       if days == 0 { return "Today" }
       if days == 1 { return "Yesterday" }
       if days < 7 { return "\(days) days ago" }
       if days < 30 { return "\(days / 7) week\(days / 7 > 1 ? "s" : "") ago" }
       return "\(days / 30) month\(days / 30 > 1 ? "s" : "") ago"
   }
   ```

2. **`gymtrackpromax/Models/User.swift`**
   ```swift
   // Add computed property
   var recentWorkoutDays: [WorkoutDay] {
       let completedSessions = workoutSessions
           .filter { $0.endTime != nil }
           .sorted { $0.startTime > $1.startTime }

       var seen = Set<UUID>()
       var result: [WorkoutDay] = []

       for session in completedSessions {
           guard let day = session.workoutDay else { continue }
           if !seen.contains(day.id) {
               seen.insert(day.id)
               result.append(day)
               if result.count >= 5 { break }
           }
       }
       return result
   }
   ```

3. **`gymtrackpromax/Views/Workout/WorkoutTabView.swift`**
   - Add preview sheet state and binding
   - Add muscle group filter state
   - Reorganize sections: Today → Quick Access → All Workouts (filtered)
   - Replace existing row with WorkoutDayCard component

---

## New Files to Create

### Components (4 files)

1. **`gymtrackpromax/Views/Components/WorkoutDayCard.swift`**
   - Reusable workout card with: name, TODAY badge, muscle chips, stats, favorite button, last completed
   - Tap → callback for preview, favorite toggle → callback

2. **`gymtrackpromax/Views/Components/MuscleGroupFilterChips.swift`**
   - Horizontal scroll of filter chips (All + muscle groups)
   - Binding for selected filters

3. **`gymtrackpromax/Views/Workout/WorkoutPreviewSheet.swift`**
   - Full preview: header with stats, exercise list with details
   - Bottom bar: "Start Workout" primary button
   - Toolbar: Close, Favorite toggle

4. **`gymtrackpromax/Views/Workout/QuickAccessSection.swift`**
   - Section title "Quick Access"
   - Horizontal scroll of QuickAccessCard (favorites first, then recent)
   - Empty state if no favorites/recent

---

## Implementation Order

### Phase 1: Core (Do First)
- [ ] Add `isFavorite` to WorkoutDay model
- [ ] Add computed properties to WorkoutDay (`daysSinceLastCompleted`, `lastCompletedDisplay`)
- [ ] Create WorkoutDayCard component
- [ ] Create WorkoutPreviewSheet
- [ ] Integrate preview sheet into WorkoutTabView

### Phase 2: Enhanced
- [ ] Add `recentWorkoutDays` to User model
- [ ] Create QuickAccessSection
- [ ] Create MuscleGroupFilterChips
- [ ] Full WorkoutTabView refactor with new sections

---

## UI Structure (After Implementation)

```
WorkoutTabView
├── Header (title + split name)
├── Today Section
│   └── Featured TodayWorkoutCard (or rest day)
├── Quick Access Section
│   └── Horizontal scroll: [Favorite cards] [Recent cards]
├── All Workouts Section
│   ├── MuscleGroupFilterChips
│   └── Filtered WorkoutDayCard list
└── Empty states as needed
```

---

## Verification Steps

1. **Build succeeds** with no errors
2. **Workout Preview**: Tap any workout → preview sheet shows → can start from there
3. **Favorites**: Tap star → saves → appears in Quick Access
4. **Recent Workouts**: Complete a workout → appears in Quick Access next time
5. **Filter**: Select "Legs" → only leg workouts shown in All Workouts
6. **Edge cases**:
   - No favorites: Quick Access shows "Star workouts to see them here"
   - No filter matches: Shows "No workouts match filter"
   - Rest day: Shows rest card with option to start any workout

---

## Design Patterns (Follow Existing)

- **Colors**: `Color.gymBackground`, `Color.gymCard`, `Color.gymPrimary`, `Color.gymText`, `Color.gymTextMuted`
- **Spacing**: `AppSpacing.standard` (16), `AppSpacing.section` (24), `AppSpacing.component` (12)
- **Corners**: `AppCornerRadius.card` (16), `AppCornerRadius.button` (12)
- **Haptics**: `HapticManager.buttonTap()`, `HapticManager.selection()`, `HapticManager.lightImpact()`
- **Accessibility**: Labels on all interactive elements

---

*Created: January 2026*
