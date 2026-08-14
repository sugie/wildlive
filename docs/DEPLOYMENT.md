# Deployment Direction

## Target cloud

Sakura Cloud

### Application

AppRun

### Database

PostgreSQL appliance

## Desired future path

```text
GitHub
  -> Pull Request
  -> CI
  -> merge to main
  -> build
  -> deploy to AppRun
  -> connect to managed PostgreSQL
```

## Requirements before production

- secrets outside the repository
- environment separation
- database backup policy
- rollback procedure
- migration policy
- monitoring
- health checks
- deployment audit trail
- least-privilege credentials

Do not provision production resources merely because this document names them.
