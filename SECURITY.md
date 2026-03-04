# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest  | ✅        |

We track the latest stable Apache Tika release and rebuild images promptly when:
- A new Tika release is published
- Base image CVEs are patched upstream (Eclipse Temurin or Alpine)
- Renovate opens an automated PR updating the version

## Reporting a Vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.**

To report a security issue, please use one of the following private channels:

1. **GitHub Security Advisories**: Navigate to `Security → Advisories → Report a vulnerability` in this repository.
2. **Email**: Send details to the repository maintainer via the email listed in the GitHub profile.

Include the following information where possible:
- Description of the vulnerability
- Steps to reproduce
- Affected versions / image tags
- Potential impact

We aim to respond within **72 hours** and provide a fix within **14 days** for confirmed critical vulnerabilities.

## Vulnerability Scanning

All images are scanned with [Trivy](https://github.com/aquasecurity/trivy) on every release and the results are uploaded to the GitHub Security tab. Images are also signed with [Cosign](https://github.com/sigstore/cosign) using keyless signing (GitHub OIDC) and accompanied by an SPDX SBOM.

To verify an image signature yourself:
```bash
cosign verify ghcr.io/kenchrcum/tika:<tag> \
  --certificate-identity-regexp="https://github.com/kenchrcum/docker-image-tika/.*" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com"
```

To verify the SBOM:
```bash
cosign download sbom ghcr.io/kenchrcum/tika:<tag>
```
