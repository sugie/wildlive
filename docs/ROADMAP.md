# Roadmap

This roadmap is intentionally lightweight.

## Phase 0 — Project foundation

- [x] Public GitHub repository
- [x] Initial project documentation
- [x] AI development rules
- [ ] Branch protection
- [ ] Pull Request template
- [ ] Basic CI policy

## Phase 1 — Docker development environment

- [ ] Laravel 13
- [ ] PHP 8.5
- [ ] PostgreSQL
- [ ] Docker Compose
- [ ] PHPUnit
- [ ] application health endpoint
- [ ] database health verification
- [ ] reproducible local startup
- [ ] CI test execution

## Phase 2 — Game specification

- [ ] confirm first playable loop
- [ ] define progression
- [ ] define hunter model
- [ ] define region model
- [ ] define species / rarity model
- [ ] define expedition resolution rules
- [ ] define economy boundaries

## Phase 3 — Domain / DB design

- [ ] minimal ER model
- [ ] migrations
- [ ] integrity constraints
- [ ] concurrency rules
- [ ] World First transaction design

## Phase 4 — REST API design

- [ ] player / zoo endpoints
- [ ] hunter endpoints
- [ ] expedition endpoints
- [ ] species / discovery endpoints
- [ ] error contract
- [ ] authentication direction
- [ ] OpenAPI contract when stable

## Phase 5 — First playable

One complete vertical slice:

`Player -> Hunter -> Expedition -> Wait -> Resolve -> Animal -> Zoo`

## Phase 6 — Multiplayer

- [ ] World First
- [ ] Hunter Contract
- [ ] Cooperative Expedition
- [ ] Shared World Event
- [ ] Zoo visit / public profile

## Phase 7 — Autonomous development

- [ ] issue creation assistance
- [ ] AI implementation
- [ ] independent AI review
- [ ] risk classification
- [ ] low-risk auto-merge policy
- [ ] deployment automation

## Phase 8 — Build in public

- [ ] development metrics
- [ ] AI-generated development log
- [ ] X posting policy
- [ ] automated X posting
- [ ] game-world reports

## Phase 9 — Cloud

Target:

- Sakura Cloud AppRun
- Sakura Cloud PostgreSQL appliance
- GitHub Actions CI/CD
- secret management
- monitoring / rollback
