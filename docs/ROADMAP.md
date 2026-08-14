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

Design-level decisions for these items are captured in
[`docs/adr/0002-game-system-foundation.md`](adr/0002-game-system-foundation.md).
Exact formulas, tables, and content lists are still open — see
[`docs/DECISIONS_PENDING.md`](DECISIONS_PENDING.md).

- [x] confirm first playable loop (ADR-0002 §1)
- [x] define progression (ADR-0002 §12–§14)
- [x] define hunter model at design level (ADR-0002 §6–§7)
- [x] define region model at design level (ADR-0002 §8–§9)
- [x] define species / rarity model at design level (ADR-0002 §3–§5, §17)
- [x] define expedition resolution rules at design level (ADR-0002 §10)
- [x] define economy boundaries (ADR-0002 §11–§14, §19)

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

Design-level decisions for the multiplayer surface are in
ADR-0002 §7 and §15. The specific mechanics below are still open:

- [ ] Guild Hunter availability across players (shared scarcity of
  top Hunters — ADR-0002 §7)
- [ ] Zoo visit / public profile (ADR-0002 §15)
- [ ] Zoo Value ranking (ADR-0002 §12, §15)
- [ ] Seasonal Events (ADR-0002 §16)
- [ ] World First — scope still open (see
  [`DECISIONS_PENDING.md`](DECISIONS_PENDING.md))
- [ ] Cooperative Expedition — scope still open

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
