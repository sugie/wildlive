# ADR-0001: Development Workflow

- Status: Accepted
- Date: 2026-08-14

## Context

WildLive is intended to be developed substantially by autonomous AI agents.

A traditional long-lived `develop` branch would add coordination overhead and make continuous autonomous work less transparent.

## Decision

Use a GitHub-Flow-style process.

`main` is the only long-lived integration branch and must remain deployable.

All changes use short-lived branches and Pull Requests.

Branch conventions:

- `ai/<issue-number>-<description>`
- `human/<issue-number>-<description>`
- `hotfix/<issue-number>-<description>`

Pull Requests require:

- relevant tests
- risk classification
- agent / reviewer information
- disclosure of human intervention

Security-sensitive or production-sensitive changes require human approval.

## Consequences

Advantages:

- simple branch topology
- clear AI development history
- easy automation
- smaller merge windows
- PR history becomes part of the public experiment

Costs:

- CI quality becomes important
- feature flags may eventually be needed for incomplete features
- `main` protection must be configured carefully
