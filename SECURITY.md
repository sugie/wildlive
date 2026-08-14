# Security Policy

WildLive is an experimental public repository.

## Reporting security issues

Do not disclose exploitable vulnerabilities in public issues.

Contact the repository owner privately through GitHub where possible.

## Security rules for contributors and AI agents

Never commit:

- `.env` files containing real values
- database passwords
- API keys
- cloud credentials
- X / social-media credentials
- OAuth secrets
- private keys
- production hostnames that are intended to remain private

All secrets must be supplied through an external secret-management mechanism.

Production-sensitive changes require explicit human review.
