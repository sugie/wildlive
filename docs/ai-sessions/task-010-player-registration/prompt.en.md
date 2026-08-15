# Human Prompt

- Source language: Japanese
- Published language: English
- Translation: Faithful English translation of the prompt actually provided to the AI agent. No summary, no beautification, no added or removed requirements. Structure (headings, bullets) is preserved.

---

# WildLive Milestone 002 — Implementation of the first-time player registration flow

## Objective

Take the SwiftUI-authored UI mock as the starting point and implement features one at a time.

This time do not widen the feature set — implement only first-time player registration on initial app launch.

Get to a state where the following full flow works entirely inside the local development environment on the Mac:

iPhone Simulator
→ SwiftUI app
→ local Laravel API
→ local PostgreSQL
→ player registration
→ API response
→ SwiftUI side confirms registration is complete

First complete this single Vertical Slice.

---

## This time's goal

When WildLive is launched for the first time in the iPhone Simulator,

1. The SwiftUI app recognises that the user is "unregistered".
2. It runs the first-time player registration process.
3. It calls the local Docker Laravel API.
4. Laravel validates the input.
5. Laravel writes the player information into PostgreSQL.
6. The Laravel API returns the registration result.
7. The SwiftUI side receives the response.
8. The record is confirmed to actually exist in PostgreSQL.

Get this to make one complete lap.

---

## Development environment

**Client**

* macOS
* Xcode
* SwiftUI
* iPhone Simulator

**Local Server**

Built on Docker.

* Laravel
* PostgreSQL 17
* A configuration that can use pgvector
* API and PostgreSQL are separate services

The SwiftUI app must be able to reach the local Laravel API over HTTP.

---

## About the production environment

The production server already exists in the cloud.

* FrankenPHP
* Laravel
* PostgreSQL 17
* pgvector

An environment where Laravel connects to PostgreSQL is already built.

However, this Milestone does not connect to or deploy to the production environment.

First establish the Client → API → DB round-trip locally.

Structure the same Laravel application so that it can be deployed to production in the future.

---

## Implementation targets

**1. PostgreSQL**

Design the minimum data model required for first-time player registration.

Do not perform excessive future-proof design.

Use Laravel migration to create the necessary tables in local PostgreSQL.

For the ID scheme, choose an appropriate approach with future use in the game system in mind.

**2. Laravel API**

Implement one API for first-time player registration.

Example:

`POST /api/players`

However, if existing API design / naming conventions exist in the repository, prefer those.

At minimum the API should implement:

* Request validation
* Player creation
* PostgreSQL save
* JSON response
* Appropriate HTTP status codes
* Error handling

Prefer Laravel's built-in features. Do not add unnecessary custom frameworks or abstractions.

**3. SwiftUI Client**

Base on the current SwiftUI UI mock.

Make it able to call the player-registration API on first launch.

Prefer Apple's standard APIs for networking. For example:

* URLSession
* Codable
* async/await

Do not add more networking libraries than necessary.

Receive the API response and be able to confirm registration success or failure.

---

## Important: not doing this time

The following will not be implemented this Milestone:

* Ranking
* Guild
* MMO game logic
* Matching
* Chat
* Friends
* Monetisation
* Push Notification
* AI features
* pgvector search features
* Deployment to production
* Connection to production PostgreSQL
* Complex authentication system
* Admin console
* Excessive abstractions for anticipated future features

Do not widen this scope for the reason "we'll need it later".

---

## Testing

Confirm at minimum the following.

**Laravel**

Create a Feature Test for the player-registration API.

Verify:

* A normal request registers successfully
* A record is created in PostgreSQL
* The correct JSON response is returned
* Invalid input is rejected

Do not substitute SQLite. Maintain consistency with the real PostgreSQL environment as far as possible.

**SwiftUI**

From the iPhone Simulator, actually call the local Laravel API and confirm.

Do not treat mock-only communication as "done".

---

## Completion conditions

Done for Milestone 002 is:

1. Laravel + PostgreSQL 17 come up under Docker.
2. Laravel can connect to PostgreSQL.
3. The player registration API works.
4. Laravel-side tests PASS.
5. WildLive can be launched in the iPhone Simulator.
6. SwiftUI can call the local Laravel API.
7. First-time player registration succeeds.
8. An actual Player record is created in PostgreSQL.
9. SwiftUI can receive the registration result.
10. The above procedure is recorded reproducibly in a README or an appropriate development document.

---

## Working policy

Do not start implementing in bulk.

First investigate the current repository:

* Current SwiftUI structure
* Whether Laravel exists and its current structure
* Docker configuration
* PostgreSQL configuration
* Existing migrations
* Existing API design
* Test configuration
* Relationship to Milestone 001

Then decompose the required changes into minimum units.

First present the implementation plan and the target files, confirm there is no conflict with existing design, and only then start implementing.

The purpose this time is not to build a large game foundation. It is:

> "Press a button in the iPhone Simulator / trigger the first-run process → Laravel API → one Player is registered in PostgreSQL → the result is returned to the iPhone"

Complete this minimum End-to-End flow reliably as the top priority.
