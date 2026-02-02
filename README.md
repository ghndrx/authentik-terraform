# Authentik Terraform Configuration

Infrastructure as Code for Authentik identity provider - manage applications, providers, and SSO via Terraform.

## Features

- **OAuth2/OIDC Applications**: ArgoCD, Grafana
- **Proxy Authentication**: Home Assistant, Immich, Uptime Kuma, *arr stack
- **LDAP Outpost**: For legacy application support
- **Google OAuth Source**: Social login integration
- **Security Policies**: Strong passwords, MFA, brute-force protection
- **RBAC Groups**: Role-based access control for applications

## Quick Start

### 1. Fork/Clone This Repo

```bash
git clone https://github.com/ghndrx/authentik-terraform.git
cd authentik-terraform
```

### 2. Configure GitHub Secrets

Go to **Settings > Secrets and variables > Actions** and add:

| Secret | Description | Example |
|--------|-------------|---------|
| `AUTHENTIK_URL` | Your Authentik server URL | `https://auth.example.com` |
| `AUTHENTIK_TOKEN` | API token from Authentik | `ak-...` |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID | `xxx.apps.googleusercontent.com` |
| `GOOGLE_CLIENT_SECRET` | Google OAuth secret | `GOCSPX-...` |
| `ARGOCD_URL` | ArgoCD URL | `https://argocd.example.com` |
| `GRAFANA_URL` | Grafana URL | `https://grafana.example.com` |
| `HOME_ASSISTANT_URL` | Home Assistant URL | `https://home.example.com` |
| `IMMICH_URL` | Immich URL | `https://photos.example.com` |
| `UPTIME_KUMA_URL` | Uptime Kuma URL | `https://status.example.com` |
| `SONARR_URL` | Sonarr URL | `https://sonarr.example.com` |
| `RADARR_URL` | Radarr URL | `https://radarr.example.com` |
| `PROWLARR_URL` | Prowlarr URL | `https://prowlarr.example.com` |

### 3. Create Authentik API Token

1. Log into Authentik as admin
2. Go to **Directory > Tokens and App passwords**
3. Create a new token with **API Access** intent
4. Copy the token value

### 4. (Optional) Set Up Google OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create OAuth 2.0 credentials
3. Add authorized redirect URI: `https://auth.example.com/source/oauth/callback/google/`

### 5. Deploy

Push to `main` branch to trigger deployment, or run manually:

```bash
# Local development
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan
terraform apply
```

## GitHub Actions Workflow

- **On PR**: Runs `terraform plan` for review
- **On Push to main**: Runs `terraform apply` automatically
- **Manual**: Can trigger via Actions tab

## File Structure

```
├── .github/workflows/deploy.yml  # CI/CD pipeline
├── main.tf                       # Authentik provider & brand config
├── variables.tf                  # All configurable variables
├── security-policies.tf          # Password, MFA, brute-force policies
├── rbac-groups.tf                # RBAC groups and access policies
├── app-*.tf                      # Application configurations
├── ldap-outpost.tf              # LDAP outpost config
├── source-google.tf             # Google OAuth source
└── outputs.tf                   # Useful outputs
```

## Adding New Applications

### OAuth2/OIDC Application

```hcl
# app-myapp.tf
resource "authentik_provider_oauth2" "myapp" {
  name               = "MyApp"
  authorization_flow = data.authentik_flow.default_authorization.id
  client_id          = "myapp"
  client_type        = "confidential"
  
  redirect_uris = [
    "${var.myapp_url}/oauth/callback"
  ]
  
  property_mappings = data.authentik_property_mapping_provider_scope.oauth2.ids
}

resource "authentik_application" "myapp" {
  name              = "MyApp"
  slug              = "myapp"
  protocol_provider = authentik_provider_oauth2.myapp.id
  
  meta_launch_url = var.myapp_url
  meta_icon       = "https://example.com/icon.png"
}
```

### Proxy Authentication

```hcl
resource "authentik_provider_proxy" "myapp" {
  name               = "MyApp Proxy"
  authorization_flow = data.authentik_flow.default_authorization.id
  external_host      = var.myapp_url
  mode               = "forward_single"
}

resource "authentik_application" "myapp" {
  name              = "MyApp"
  slug              = "myapp"
  protocol_provider = authentik_provider_proxy.myapp.id
}
```

## Terraform State

By default, state is stored locally. For production, configure remote backend:

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket = "your-terraform-state"
    key    = "authentik/terraform.tfstate"
    region = "us-east-1"
  }
}
```

## Security Policies (security-policies.tf)

This configuration includes enterprise-grade security controls:

### Password Policy
- Minimum 12 characters
- Requires uppercase, lowercase, digits, and symbols
- **Have I Been Pwned** integration - rejects breached passwords
- **zxcvbn** password strength scoring (requires "strong" level 3/4)
- Password reuse prevention (last 5 passwords)

### Multi-Factor Authentication
- TOTP authenticator apps (Google Authenticator, Authy, etc.)
- WebAuthn/Passkeys (YubiKey, Touch ID, Windows Hello)
- Static recovery codes (10 codes, 12 characters each)
- Configurable enforcement: skip, deny, or force configuration

### Brute Force Protection
- Reputation-based blocking after 5 failed attempts
- Blocks by IP address and username
- Execution logging for audit trail

### To Enable MFA Enforcement:
1. Deploy these policies with `terraform apply`
2. In Authentik UI: Edit your authentication flow
3. Add the `mfa-validation` stage after the password stage
4. Set `not_configured_action` to `deny` for strict enforcement

## RBAC Groups (rbac-groups.tf)

Role-based access control with three predefined groups:

| Group | Purpose | Example Apps |
|-------|---------|--------------|
| Media | Media server access | Sonarr, Radarr, Prowlarr, Plex |
| Infrastructure | DevOps/monitoring | Grafana, ArgoCD, Portainer |
| Home Automation | Smart home | Home Assistant |

Admins automatically have access to all groups. Bind policies to applications:

```hcl
resource "authentik_policy_binding" "grafana_infra_access" {
  target = authentik_application.grafana.uuid
  policy = authentik_policy_expression.infrastructure_access.id
  order  = 0
}
```

## Security Notes

- Never commit `terraform.tfvars` or any file with secrets
- Use GitHub Actions secrets for CI/CD
- API tokens should have minimal required permissions
- Rotate tokens periodically
- Enable execution logging for security audit trails
- Review login events in Authentik's Events log regularly

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| authentik | >= 2024.0 |

## License

MIT
