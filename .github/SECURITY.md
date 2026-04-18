# Security Policy

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| 1.x     | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Instead, please report them responsibly:

1. Email: **<security-email>**
2. Include a description of the vulnerability, steps to reproduce, and potential impact.
3. You will receive an acknowledgment within **48 hours**.
4. We will work with you to understand and address the issue before any public disclosure.

## Security Best Practices Enforced in This Repo

- OIDC-based CI/CD authentication (no static AWS credentials)
- ECR image scanning on push
- Immutable image tags in ECR
- Non-root container users in all Dockerfiles
- Dependabot enabled for automated dependency patching
- Pre-commit hooks for secret detection
