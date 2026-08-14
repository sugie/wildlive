# Human Prompt

- Source language: Japanese
- Published language: English
- Translation: Faithful English translation of the prompt actually provided to the AI agent. No summary, no beautification, no added or removed requirements. Code, commands, file paths, URLs, identifiers, and error messages are kept in their original form. Structure (headings, numbering, constraints) is preserved.

---

# WildLive UI-First Milestone 001

## Show the first title screen on the iOS Simulator

WildLive development starts here in UI-first mode.

The goal of this task is very simple.

> **Actually display WildLive's first title screen on the iOS Simulator using Xcode + Swift + SwiftUI.**

Do not build API, DB, server, authentication, or production infrastructure this time.

We build "something visible" first.

---

# 1. Development direction for this task

Going forward, WildLive is developed in this order:

`UI → Interaction → Game Experience → Domain/API → Infrastructure`

We will no longer proceed in the traditional

`Infrastructure → Database → API → UI`

order.

In this project, humans look at real screens first and check

* whether it is acceptable
* whether it looks game-like
* whether the world view matches
* whether it makes you want to operate it

as we proceed.

Do not implement the backend ahead of time while the UI has not settled.

---

# 2. Goal of Milestone 001

The success condition this time is only one.

**Launch the iOS Simulator and have the WildLive title screen appear.**

Go far enough that the app can actually be launched on the iOS Simulator — not just verifiable by screenshot.

---

# 3. Technologies

The iOS client uses:

* Xcode
* Swift
* SwiftUI
* iOS Simulator

React Native, Flutter, and Web UI are not used this time.

Since we only display a title screen, in principle do not use any external UI framework or third-party package.

Standard SwiftUI is enough.

---

# 4. Investigate the repository first

Do not immediately start creating files.

First, check the current repository.

At minimum:

* `git status`
* `git branch -vv`
* the root directory layout
* whether `apps/` exists
* whether an iOS-related directory exists
* `.xcodeproj`
* `.xcworkspace`
* Swift sources
* any existing mobile application
* README
* CLAUDE.md
* AGENTS.md
* AUTONOMY.md
* repository governance
* existing naming conventions

If an iOS application already exists, use it — do not create a duplicate.

If none exists, create a minimal native iOS application for WildLive.

---

# 5. Git

Do not change `main` directly.

Check the current repository policy and create a branch dedicated to this milestone.

Candidate:

`ai/011-ios-title-screen`

However, if it collides with the existing task-numbering / branch-naming convention, the repository's current rule takes precedence.

---

# 6. iOS app placement

Absent an existing rule, assume the following structure:

`apps/ios/`

Place the native WildLive iOS application there.

However, if a mobile-application standard layout is already defined in the repository, prefer that.

Do not add pointless directory structure.

---

# 7. Minimal app

Make it a minimal SwiftUI application.

At most, you need something like:

* App entry point
* Title screen View

You do NOT need:

* network layer
* repository layer
* database
* API client
* authentication
* dependency-injection framework
* complex architecture
* MVVM framework
* Redux
* state-management library
* analytics
* push notifications
* persistence
* game engine

Write only the code the goal requires.

---

# 8. Title screen

Create the first title screen.

This is not the final design.

It is Version 0 for a human to

**"see WildLive's first screen on an actual iPhone."**

At minimum, show:

## Title

Large:

`WildLive`

## Subtitle

Small:

`AI Made Live MMO`

Or, if the repository already has an official tagline, prefer that.

Do not unilaterally decide a new marketing message.

## Start button

At the bottom, or centre-bottom:

`START`

Show a button.

You do not need to make the button start the game.

However, make it a tappable SwiftUI `Button`.

On tap, printing to the console temporarily is fine.

---

# 9. World view

WildLive is not an ordinary business application.

Build it **as a game title screen**.

However, for this Version 0 excessive design is unnecessary.

For now:

* full screen
* dark background
* large "WildLive" logo text
* game-like negative space
* START button

is enough.

The important point is not the polish of the decoration; it is that the

**minimum screen that "feels like a game is about to start" when seen on an iPhone**

is achieved.

---

# 10. Background

You do not need to look up or generate external image assets.

Express it with SwiftUI only in Version 0.

For example:

* black
* deep dark colour
* gradient

is fine.

Do not obtain copyrighted image material without permission.

Do not build an asset pipeline this time.

The background image and the real title logo are for a later milestone.

---

# 11. Safe area

Use the full iPhone screen for the title screen.

While considering SwiftUI safe areas as needed, arrange the layout so it does not look unnatural in the presence of:

* Dynamic Island
* status bar
* home indicator

Do not hardcode pixel coordinates for a specific iPhone.

---

# 12. Portrait

Milestone 001 assumes portrait orientation.

You do not need to build landscape support this time.

---

# 13. Accessibility / Dynamic Type

Since this is Version 0, over-engineering is not needed, but do not break the standard SwiftUI text / button semantics.

Do not draw text with Canvas drawing pointlessly.

---

# 14. iOS target

Check the currently installed Xcode and iOS Simulator.

Check the available simulator runtime and device, and choose a realistic deployment target that can actually build/run.

Do not hardcode a latest version by guess.

You may use, as needed:

`xcodebuild -version`

`xcrun simctl list devices available`

`xcrun simctl list runtimes`

---

# 15. If no Xcode project exists

If no iOS project exists in the repository yet, create a minimal native iOS project.

However, do not newly introduce any of the following for this task alone:

* CocoaPods
* React Native
* Flutter
* Tuist
* XcodeGen
* Bazel

Use an existing project-generation tool only if the repository already uses one.

The goal is not to design project tooling; it is:

**Display a SwiftUI app on the Simulator.**

---

# 16. Build

Actually build.

If possible, check from the CLI using `xcodebuild`.

Do not stop after only writing source code.

At minimum, confirm

**BUILD SUCCEEDED**

---

# 17. iOS Simulator

Pick an available iPhone Simulator.

Absent a good reason for a specific model, use a currently installed, relatively new, standard iPhone Simulator.

Boot the Simulator, install the built WildLive app, and launch it.

You may use, as needed:

* `xcrun simctl boot`
* `xcrun simctl install`
* `xcrun simctl launch`

The final state must be

**the WildLive title screen displayed on the iOS Simulator.**

---

# 18. Screenshot

Once the Simulator display is correct, take a confirmation screenshot.

Save it into the location the repository policy explicitly designates, only if such a location exists.

Otherwise, take it as a temporary file and do not commit it to the repository.

Do not build a new documentation system just to keep a screenshot.

---

# 19. START button

Do not build the post-START game screen this time.

Verifying that the tap works is enough.

For example, printing

`START tapped`

to the console in a DEBUG build is fine.

Do not transition to a new screen.

The next screen is decided by the human after they check the title screen.

---

# 20. Do not build any API

Do not implement any of the following this time:

* Laravel connection
* HTTP API
* REST
* GraphQL
* WebSocket
* authentication API
* user registration
* login
* PostgreSQL connection
* pgvector connection
* server health check

The WildLive PostgreSQL 17 environment exists, but

**Milestone 001 does not use it.**

---

# 21. Do not touch production infrastructure

Do not access or change any of the following this time:

* production server
* API server
* PostgreSQL Cluster
* PgBouncer
* DNS
* firewall
* AppRun
* Sakura Cloud
* production credentials

Keep this task entirely local on the Mac.

---

# 22. Do not build a data model

Because we determine required data after seeing the UI, do not design the DB schema or API schema first.

Also not needed:

* users table
* players table
* characters table
* world table
* session table
* migration
* OpenAPI
* JSON schema

We will design from the UI backwards when needed.

---

# 23. Do not over-engineer architecture

This is a title screen only.

Do not create a mountain of abstractions on the grounds that

"this will become a large MMO in the future".

Follow YAGNI strictly.

What is needed is the

**minimum code to display a title screen with SwiftUI.**

---

# 24. Tests

At minimum, confirm:

* the Xcode project is recognised correctly
* the build succeeds
* Simulator install succeeds
* Simulator launch succeeds

You do not need to build a large unit-test infrastructure this time.

If a test target already exists, confirm that it is not broken.

---

# 25. Human UI review is the next gate

Milestone 001 does not automatically advance.

Once the title screen is displayed, end this milestone there.

After that, a human looks at the real screen.

The human will check

* title position
* fonts
* background
* START button
* atmosphere
* world view

and issue revision instructions.

That is, this time

**do not try to finish the title screen on your own.**

The goal is to present Version 0.

---

# 26. AI development archive

If the WildLive repository already has AI session / report / ADR / public development governance, follow that existing rule for recording this task.

However, do not let documentation creation become larger than the UI milestone itself.

The main goal this time is:

**Display the title screen on the Simulator.**

Follow existing governance, and keep documentation to the necessary minimum.

---

# 27. X posting

If the repository already has an automatic X development-posting workflow, follow that existing governance.

Do not post to X manually.

Because this is Version 0 before UI review, if it is not already covered by the repository policy as an auto-post-on-merge target, do not add a new posting mechanism.

---

# 28. Commit / Push / PR

First, go up to the local implementation and Simulator display confirmation.

Since the immediate goal is UI review, **do not merge without permission before the human checks the screen.**

If a branch / commit is required by existing repository governance, a local commit is fine.

However, do not perform

* push
* Pull Request creation
* merge

until the human confirms the UI.

---

# 29. Forbidden

The following are forbidden this time:

* React Native adoption
* Flutter adoption
* Web application conversion
* Unity adoption
* Unreal Engine adoption
* third-party UI framework adoption
* API implementation
* PostgreSQL connection
* backend implementation
* authentication
* game server
* networking
* database schema creation
* production infrastructure change
* unnecessary architecture
* unnecessary dependency
* unnecessary abstraction
* large refactoring
* unrelated changes to existing code
* push / PR / merge before UI review

---

# 30. Final report

When Milestone 001 is complete, report:

## 1. Repository state

* branch
* commit
* working tree

## 2. iOS project

* project path
* target name
* bundle identifier
* deployment target
* Swift version
* SwiftUI confirmed

## 3. Xcode

* Xcode version

## 4. Simulator

* device
* iOS runtime version

## 5. Build

The actual command executed and its result.

`BUILD SUCCEEDED`.

## 6. Launch

Whether Simulator install / launch succeeded.

## 7. Screen

What is actually displayed:

* WildLive
* subtitle
* START button

## 8. Screenshot

screenshot path.

State whether it was committed to the repository or is only a temporary file.

## 9. Files changed

The list of files added / changed this time.

## 10. Backend / Infrastructure

Confirm that none of the following was touched:

* API
* PostgreSQL
* production infrastructure

## 11. Remaining issues

Only truly needed issues for the human to check the title screen.

---

# End condition for this task

Stop when the following is true:

> **WildLive launches on the iOS Simulator and the title screen is actually displayed.**

Then wait for human UI review.

Do not proceed on your own to the next game screen, API, DB, or server implementation.

---

The most important principle of WildLive development this time is

**Build something visible first.**

The first step is

**Displaying WildLive's title screen on the iPhone Simulator.**

Focus only on that.
