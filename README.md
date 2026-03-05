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
├── authentication-flow.tf        # Custom MFA authentication flow
├── security-policies.tf          # Password, MFA, brute-force policies
├── rbac-groups.tf                # RBAC groups and access policies
├── session-settings.tf           # Session security & network binding
├── app-*.tf                      # Application configurations
├── proxy-outpost.tf              # Standalone proxy outpost config
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

## Deploying the Proxy Outpost

The proxy outpost handles forward authentication for applications that don't support OIDC natively. 

### Why Standalone Outpost?

The embedded outpost (running within Authentik) can experience issues like:
- 404 errors: "no value given for required property pk"
- Configuration complexity
- Resource contention

A **standalone proxy outpost** runs as a separate container and provides:
- ✅ Better isolation and reliability
- ✅ Independent scaling
- ✅ Easier debugging
- ✅ More flexible deployment options

### Deployment Steps

1. **Apply Terraform Configuration**
   ```bash
   terraform apply
   ```
   This creates the outpost configuration in Authentik.

2. **Get Docker Compose Configuration**
   ```bash
   terraform output proxy_outpost_docker_compose > docker-compose-proxy-outpost.yml
   ```

3. **Get Outpost Token**
   ```bash
   terraform output -raw proxy_outpost_token
   ```
   Copy this token - you'll need it for the `AUTHENTIK_TOKEN` environment variable.

4. **Deploy the Outpost**
   
   Edit the docker-compose file and replace `<get_from_terraform_output>` with the actual token:
   
   ```bash
   nano docker-compose-proxy-outpost.yml
   # Replace <get_from_terraform_output> with your token
   
   docker compose -f docker-compose-proxy-outpost.yml up -d
   ```

5. **Configure Your Reverse Proxy**

   **For Traefik** (labels are pre-configured in the compose file):
   ```yaml
   # In your app's docker-compose.yml
   labels:
     - "traefik.http.routers.myapp.middlewares=authentik@docker"
     - "traefik.http.middlewares.authentik.forwardauth.address=http://authentik-proxy-outpost:9000/outpost.goauthentik.io/auth/traefik"
     - "traefik.http.middlewares.authentik.forwardauth.trustForwardHeader=true"
     - "traefik.http.middlewares.authentik.forwardauth.authResponseHeaders=X-authentik-username,X-authentik-groups,X-authentik-email,X-authentik-name,X-authentik-uid"
   ```

   **For Caddy**:
   ```
   myapp.example.com {
       forward_auth authentik-proxy-outpost:9000 {
           uri /outpost.goauthentik.io/auth/caddy
           copy_headers X-authentik-username X-authentik-groups X-authentik-email
       }
       reverse_proxy myapp:8080
   }
   ```

   **For Nginx**:
   ```nginx
   location / {
       auth_request /outpost.goauthentik.io/auth/nginx;
       auth_request_set $auth_cookie $upstream_http_set_cookie;
       add_header Set-Cookie $auth_cookie;
       
       proxy_pass http://myapp:8080;
   }
   
   location /outpost.goauthentik.io {
       proxy_pass http://authentik-proxy-outpost:9000;
   }
   ```

6. **Verify the Outpost**
   
   Check the outpost status in Authentik UI:
   - Go to **System > Outposts**
   - "Standalone Proxy Outpost" should show as **Healthy** ✅

### Troubleshooting

- **Outpost not connecting**: Check `AUTHENTIK_TOKEN` is set correctly
- **404 errors**: Verify `AUTHENTIK_HOST` matches your Authentik URL exactly
- **TLS errors**: For self-signed certs, set `AUTHENTIK_INSECURE=true` (dev only)
- **View logs**: `docker logs authentik-proxy-outpost`

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

**Option 1: Use the Custom MFA Authentication Flow (Recommended)**

Set in `terraform.tfvars`:
```hcl
enable_mfa_flow = true
mfa_enforcement = "configure"  # or "deny" for strict enforcement
```

This creates a complete authentication flow with:
- User identification → Password → MFA validation → Session creation
- Brute-force protection policy binding
- Configurable MFA enforcement level

**Option 2: Manual Configuration**
1. Deploy these policies with `terraform apply`
2. In Authentik UI: Edit your authentication flow
3. Add the `mfa-validation` stage after the password stage
4. Set `not_configured_action` to `deny` for strict enforcement

### MFA Enforcement Levels

| Level | Behavior |
|-------|----------|
| `skip` | MFA optional, no prompt if not configured |
| `configure` | Prompts users to set up MFA on login (recommended for rollout) |
| `deny` | Blocks login if MFA not configured (use after users have set up MFA) |

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
