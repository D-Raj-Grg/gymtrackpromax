# PLANNING.md - GymTrack Pro

> **Document Purpose:** Strategic planning document outlining the vision, architecture, technology decisions, and tooling requirements for the GymTrack Pro iOS application.

---

## 📍 Table of Contents

1. [Product Vision](#-product-vision)
2. [Goals & Success Metrics](#-goals--success-metrics)
3. [Architecture Overview](#-architecture-overview)
4. [Technology Stack](#-technology-stack)
5. [Required Tools & Setup](#-required-tools--setup)
6. [Third-Party Dependencies](#-third-party-dependencies)
7. [Development Phases](#-development-phases)
8. [Risk Assessment](#-risk-assessment)
9. [Decision Log](#-decision-log)

---

## 🎯 Product Vision

### Vision Statement
> **"Empower every gym-goer to train smarter, track effortlessly, and achieve their fitness goals through intuitive workout logging and insightful progress visualization."**

### Problem We're Solving
Gym enthusiasts struggle with:
- **Memory burden:** Forgetting weights, reps, and exercises from previous sessions
- **Lack of structure:** No clear plan leads to inconsistent training
- **Progress blindness:** Unable to see if they're actually improving
- **Friction in logging:** Existing apps are either too complex or too basic
- **Data loss:** Paper logs get lost; switching apps loses history

### Our Solution
GymTrack Pro provides:
- **Smart workout splits:** Pre-built and customizable training programs
- **Frictionless logging:** Log sets in 2 taps with smart defaults
- **Visual progress:** Charts that clearly show strength gains over time
- **Offline-first:** Works without internet, syncs when available
- **iOS-native experience:** Feels like a first-party Apple app

### Target Users

| Persona | Description | Key Needs |
|---------|-------------|-----------|
| **Beginner Ben** | New to gym, 3 months experience | Guidance, structure, simplicity |
| **Intermediate Irene** | 1-2 years lifting, knows basics | Progress tracking, PR alerts |
| **Advanced Alex** | 3+ years, serious lifter | Customization, detailed analytics |
| **Returning Rachel** | Used to lift, getting back into it | Easy restart, history reference |

### Core Value Propositions
1. **Simplicity:** Log a set in under 3 seconds
2. **Intelligence:** Smart suggestions based on history
3. **Motivation:** Streaks, PRs, and progress visualization
4. **Flexibility:** Works for any training style
5. **Privacy:** Your data stays on your device (with optional cloud backup)

---

## 📊 Goals & Success Metrics

### Business Goals

| Goal | Metric | Target | Timeframe |
|------|--------|--------|-----------|
| User Acquisition | Downloads | 10,000 | 6 months |
| User Retention | Day 7 retention | > 40% | Ongoing |
| User Engagement | Weekly active users | 60% of MAU | Ongoing |
| Revenue (Phase 3) | Pro subscriptions | 5% conversion | Year 1 |
| Quality | App Store rating | 4.5+ stars | Ongoing |

### Technical Goals

| Goal | Metric | Target |
|------|--------|--------|
| Performance | App launch time | < 1 second |
| Stability | Crash-free rate | > 99.5% |
| Responsiveness | UI frame rate | 60 fps constant |
| Data Safety | Zero data loss | 100% |
| Offline Support | Full functionality offline | Yes |

### User Experience Goals

| Goal | Measurement |
|------|-------------|
| Onboarding completion | > 80% complete onboarding |
| Time to first workout | < 3 minutes from install |
| Set logging speed | < 3 seconds per set |
| Feature discoverability | 70% use progress charts within 2 weeks |

---

## 🏛️ Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │   SwiftUI   │  │   SwiftUI   │  │   SwiftUI   │    Views     │
│  │    Views    │  │  Components │  │  Modifiers  │              │
│  └──────┬──────┘  └──────┬──────┘  └─────────────┘              │
│         │                │                                       │
│         ▼                ▼                                       │
│  ┌─────────────────────────────────────────────┐                │
│  │            ViewModels (@Observable)          │                │
│  │   • State management                         │                │
│  │   • UI logic                                 │                │
│  │   • User action handling                     │                │
│  └──────────────────────┬──────────────────────┘                │
└─────────────────────────┼───────────────────────────────────────┘
                          │
┌─────────────────────────┼───────────────────────────────────────┐
│                         ▼         DOMAIN LAYER                   │
│  ┌─────────────────────────────────────────────┐                │
│  │                 Services                     │                │
│  │   • WorkoutService (business logic)         │                │
│  │   • ExerciseService (exercise operations)   │                │
│  │   • ProgressService (analytics/stats)       │                │
│  │   • NotificationService (reminders)         │                │
│  └──────────────────────┬──────────────────────┘                │
│                         │                                        │
│  ┌─────────────────────────────────────────────┐                │
│  │              Domain Models                   │                │
│  │   • Enums, Protocols, Business Rules        │                │
│  └──────────────────────┬──────────────────────┘                │
└─────────────────────────┼───────────────────────────────────────┘
                          │
┌─────────────────────────┼───────────────────────────────────────┐
│                         ▼          DATA LAYER                    │
│  ┌─────────────────────────────────────────────┐                │
│  │              SwiftData Models                │                │
│  │   @Model classes with relationships          │                │
│  └──────────────────────┬──────────────────────┘                │
│                         │                                        │
│         ┌───────────────┼───────────────┐                       │
│         ▼               ▼               ▼                       │
│  ┌───────────┐   ┌───────────┐   ┌───────────┐                 │
│  │  SQLite   │   │ CloudKit  │   │ UserDef.  │                 │
│  │ (SwiftDa) │   │  (Sync)   │   │ (Prefs)   │                 │
│  └───────────┘   └───────────┘   └───────────┘                 │
└─────────────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────┼───────────────────────────────────────┐
│                         ▼       EXTERNAL SERVICES                │
│  ┌───────────┐   ┌───────────┐   ┌───────────┐                 │
│  │ HealthKit │   │   Local   │   │  StoreKit │                 │
│  │           │   │  Notifs   │   │   (IAP)   │                 │
│  └───────────┘   └───────────┘   └───────────┘                 │
└─────────────────────────────────────────────────────────────────┘
```

### Architecture Pattern: MVVM + Clean Architecture

**Why MVVM?**
- Native SwiftUI compatibility with `@Observable`
- Clear separation of UI and business logic
- Testable ViewModels
- Apple's recommended pattern for SwiftUI

**Clean Architecture Principles Applied:**
- **Dependency Rule:** Inner layers don't know about outer layers
- **Separation of Concerns:** Each layer has a single responsibility
- **Testability:** Business logic isolated from UI and frameworks

### Data Flow

```
User Action → View → ViewModel → Service → SwiftData → Database
                                    ↓
                              CloudKit Sync (optional)
                                    ↓
User Feedback ← View ← ViewModel ← Service ← SwiftData ← Database
```

### Navigation Architecture

```swift
// Tab-based navigation with nested NavigationStacks
TabView {
    NavigationStack { DashboardView() }
        .tabItem { Label("Home", systemImage: "house") }
    
    NavigationStack { WorkoutView() }
        .tabItem { Label("Workout", systemImage: "dumbbell") }
    
    NavigationStack { HistoryView() }
        .tabItem { Label("History", systemImage: "clock") }
    
    NavigationStack { ProgressView() }
        .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
    
    NavigationStack { ProfileView() }
        .tabItem { Label("Profile", systemImage: "person") }
}
```

---

## 🛠️ Technology Stack

### Core Technologies

| Layer | Technology | Version | Purpose |
|-------|------------|---------|---------|
| **Language** | Swift | 5.9+ | Primary development language |
| **UI Framework** | SwiftUI | iOS 17+ | Declarative UI |
| **Data Persistence** | SwiftData | iOS 17+ | Local database |
| **Reactive** | Observation | iOS 17+ | State management |
| **Charts** | Swift Charts | iOS 16+ | Data visualization |
| **Notifications** | UserNotifications | iOS 10+ | Rest timer alerts |

### Apple Frameworks Used

| Framework | Purpose | Phase |
|-----------|---------|-------|
| **SwiftUI** | All UI components | 1 |
| **SwiftData** | Data persistence | 1 |
| **Swift Charts** | Progress visualization | 1 |
| **UserNotifications** | Rest timer, reminders | 1 |
| **WidgetKit** | Home screen widgets | 2 |
| **ActivityKit** | Live Activities | 2 |
| **CloudKit** | Cloud sync & backup | 3 |
| **HealthKit** | Apple Health integration | 3 |
| **WatchKit** | Apple Watch app | 3 |
| **AppIntents** | Siri Shortcuts | 3 |
| **StoreKit 2** | In-app purchases | 3 |

### Why These Choices?

#### SwiftUI over UIKit
✅ **Pros:**
- Declarative syntax = less boilerplate
- Built-in state management
- Easy animations
- Better previews
- Future-proof (Apple's direction)

⚠️ **Considerations:**
- iOS 17 minimum (acceptable for new app)
- Some complex layouts need workarounds

#### SwiftData over Core Data
✅ **Pros:**
- Modern Swift-native API
- Less boilerplate than Core Data
- Automatic CloudKit integration
- Works with `@Observable`

⚠️ **Considerations:**
- iOS 17+ only (acceptable)
- Newer framework (less community resources)

#### No External Dependencies (Phase 1)
✅ **Pros:**
- Faster app launch
- No dependency management issues
- Smaller app size
- Full control over code

---

## 🔧 Required Tools & Setup

### Development Environment

| Tool | Version | Required | Purpose |
|------|---------|----------|---------|
| **macOS** | Sonoma 14.0+ | ✅ | Development OS |
| **Xcode** | 15.0+ | ✅ | IDE |
| **iOS Simulator** | iOS 17+ | ✅ | Testing |
| **Physical iPhone** | iOS 17+ | Recommended | Real device testing |
| **Apple Developer Account** | Any tier | ✅ | TestFlight, App Store |

### Xcode Setup Requirements

```bash
# 1. Install Xcode from Mac App Store or Apple Developer portal

# 2. Install Command Line Tools
xcode-select --install

# 3. Accept license
sudo xcodebuild -license accept

# 4. Verify installation
xcodebuild -version
# Expected: Xcode 15.x, Build version xxxxx
```

### Project Configuration

#### Capabilities to Enable (Xcode → Signing & Capabilities)

| Capability | Phase | Purpose |
|------------|-------|---------|
| **Push Notifications** | 1 | Rest timer notifications |
| **Background Modes** | 1 | Timer continues in background |
| **HealthKit** | 3 | Apple Health sync |
| **CloudKit** | 3 | iCloud sync |
| **Sign in with Apple** | 3 | Authentication |
| **In-App Purchase** | 3 | Pro subscription |

#### Info.plist Entries Required

```xml
<!-- Notifications -->
<key>NSUserNotificationsUsageDescription</key>
<string>GymTrack Pro uses notifications to alert you when rest time is complete.</string>

<!-- HealthKit (Phase 3) -->
<key>NSHealthShareUsageDescription</key>
<string>GymTrack Pro reads your body weight to track progress.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>GymTrack Pro saves your workouts to Apple Health.</string>

<!-- Camera (optional, for progress photos) -->
<key>NSCameraUsageDescription</key>
<string>GymTrack Pro uses the camera for progress photos.</string>
```

### Recommended VS Code Extensions (for non-Xcode editing)

| Extension | Purpose |
|-----------|---------|
| Swift | Syntax highlighting |
| SwiftLint | Linting |
| Markdown All in One | Documentation |

### Git Configuration

```bash
# .gitignore essentials for iOS project
*.xcuserstate
*.xcuserdatad/
DerivedData/
.DS_Store
*.ipa
*.dSYM.zip
Pods/
```

---

## 📦 Third-Party Dependencies

### Phase 1: Zero External Dependencies
**Philosophy:** Use Apple frameworks exclusively for MVP to ensure stability and reduce complexity.

### Phase 2+: Potential Dependencies

| Package | Purpose | When to Add |
|---------|---------|-------------|
| **None planned** | — | — |

### Why No Dependencies?

1. **SwiftUI + SwiftData** cover UI and data needs
2. **Swift Charts** handles visualization
3. **Observation** handles state management
4. **Smaller app size** (typically 5-10MB vs 30MB+)
5. **Faster build times**
6. **No version conflicts**
7. **No supply chain security concerns**

### If Dependencies Become Necessary

Use **Swift Package Manager (SPM)** exclusively:
```swift
// Package.swift or Xcode: File → Add Package Dependencies
dependencies: [
    .package(url: "https://github.com/...", from: "1.0.0")
]
```

**Evaluation Criteria for Adding Dependencies:**
- [ ] Does Apple provide a native alternative?
- [ ] Is it actively maintained (commits in last 3 months)?
- [ ] Does it have > 1000 GitHub stars?
- [ ] Is the license compatible (MIT, Apache 2.0)?
- [ ] Does the benefit outweigh the added complexity?

---

## 📅 Development Phases

### Phase 1: MVP (v1.0) — 8-10 weeks

#### Milestone 1.1: Foundation (Week 1-2) ✅
- [x] Xcode project setup with SwiftData
- [x] Data models implementation
- [x] Color theme and design system
- [x] Basic navigation structure
- [x] Exercise seed data (JSON)

#### Milestone 1.2: Onboarding (Week 3-4) ✅
- [x] Splash screen with animation
- [x] Welcome carousel (3 slides)
- [x] User info collection
- [x] Goal selection
- [x] Split selection
- [x] Schedule customization
- [x] Completion celebration

#### Milestone 1.3: Core Workout (Week 5-6) ✅
- [x] Dashboard view
- [x] Today's workout card
- [x] Active workout view
- [x] Set logging interface
- [x] Rest timer with notifications
- [x] Workout completion summary

#### Milestone 1.4: History & Progress (Week 7-8) ✅
- [x] History list view
- [x] Calendar heatmap
- [x] Workout detail view
- [x] Progress charts (Swift Charts)
- [x] PR tracking and display

#### Milestone 1.5: Polish & Testing (Week 9-10) ✅
- [x] Profile/settings view
- [x] Haptic feedback throughout
- [x] Loading and error states
- [x] Empty states
- [ ] TestFlight beta
- [ ] Bug fixes from beta feedback

### Phase 2: Enhanced (v1.5) — 6-8 weeks
- Custom split builder
- Custom exercise creation
- Widgets (WidgetKit)
- Live Activities
- Spotlight search
- Data export
- Siri Shortcuts (basic)

### Phase 3: Advanced (v2.0) — 8-12 weeks
- CloudKit sync
- HealthKit integration
- Apple Watch app
- Pro subscription (StoreKit 2)
- Advanced analytics
- Social features (SharePlay)

---

## ⚠️ Risk Assessment

### Technical Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| SwiftData bugs/limitations | Medium | High | Fallback to Core Data if critical issues |
| iOS 17 adoption too low | Low | Medium | Monitor adoption rates; iOS 17 is at 70%+ |
| Performance issues with large datasets | Low | Medium | Implement pagination, lazy loading |
| CloudKit sync conflicts | Medium | Medium | Design conflict resolution strategy early |

### Product Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Feature creep delays MVP | High | High | Strict scope control; MVP-only features first |
| Poor user retention | Medium | High | Focus on core loop; iterate based on analytics |
| Competition releases similar features | Medium | Low | Focus on UX quality, not feature quantity |

### Mitigation Strategies

1. **Weekly scope reviews** — Ensure we're building MVP features only
2. **Early TestFlight** — Get user feedback at Week 6
3. **Analytics from Day 1** — Understand user behavior
4. **Modular architecture** — Easy to swap components if needed

---

## 📝 Decision Log

Record significant technical and product decisions here.

| Date | Decision | Rationale | Alternatives Considered |
|------|----------|-----------|------------------------|
| Jan 2026 | iOS 17+ minimum | SwiftData requires iOS 17; 70%+ adoption | iOS 16 with Core Data |
| Jan 2026 | SwiftUI only (no UIKit) | Faster development; future-proof | Hybrid approach |
| Jan 2026 | SwiftData over Core Data | Modern API; less boilerplate | Core Data, Realm, SQLite |
| Jan 2026 | No external dependencies (Phase 1) | Reduce complexity; Apple frameworks sufficient | Various SPM packages |
| Jan 2026 | MVVM architecture | SwiftUI native pattern; testable | MVC, TCA, Redux |
| Jan 2026 | Dark mode only (initially) | Matches gym environment; faster development | Light + Dark |
| Jan 2026 | Freemium model | Lower barrier to entry; sustainable | Paid upfront, Ads |

---

## 📎 Related Documents

| Document | Purpose |
|----------|---------|
| `CLAUDE.md` | AI assistant guidance for development sessions |
| `gym_tracker_prd_swift.md` | Full product requirements document |
| `figma_make_prompts.md` | UI design prompts for Figma |
| `README.md` | Project overview and setup instructions |
| `CHANGELOG.md` | Version history (create at v1.0) |

---

## ✅ Planning Checklist

Before starting development, ensure:

- [x] Vision and goals defined
- [x] Architecture documented
- [x] Technology stack selected
- [x] Development tools identified
- [x] Dependencies evaluated
- [x] Phases and milestones planned
- [x] Risks assessed
- [x] Xcode project created
- [x] Git repository initialized
- [ ] Apple Developer account ready
- [x] Design assets prepared (app icon, colors)

---

*Document Version: 1.0*  
*Created: January 2026*  
*Last Updated: January 2026*  
*Next Review: After Phase 1 completion*
