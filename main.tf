# =============================================================================
# Authentik Terraform Configuration
# Update the domain below to match your Authentik instance
# =============================================================================

# Decrypt secrets with SOPS
data "sops_file" "secrets" {
  source_file = "secrets.enc.yaml"
}

provider "authentik" {
  url   = var.authentik_url
  token = data.sops_file.secrets.data["authentik_token"]
}

# =============================================================================
# Data Sources - Existing Resources
# =============================================================================

# Default authentication flow
data "authentik_flow" "default_authentication" {
  slug = "default-authentication-flow"
}

# Default authorization flow (implicit consent)
data "authentik_flow" "default_authorization" {
  slug = "default-provider-authorization-implicit-consent"
}

# Default invalidation flow
data "authentik_flow" "default_invalidation" {
  slug = "default-invalidation-flow"
}

# Default enrollment flow (for social login)
data "authentik_flow" "default_enrollment" {
  slug = "default-source-enrollment"
}

# Get certificate for signing
data "authentik_certificate_key_pair" "generated" {
  name = "authentik Self-signed Certificate"
}

# =============================================================================
# Brand Configuration
# =============================================================================

data "authentik_brand" "default" {
  domain = "authentik-default"
}

# Update brand with proper domain
resource "authentik_brand" "main" {
  domain           = "authentik.example.com"  # TODO: Update to your domain
  default          = false
  branding_title   = "My Lab"                 # TODO: Update to your org name
  branding_logo    = "/static/dist/assets/icons/icon_left_brand.svg"
  branding_favicon = "/static/dist/assets/icons/icon.png"
  
  flow_authentication = data.authentik_flow.default_authentication.id
  flow_invalidation   = data.authentik_flow.default_invalidation.id
}

# =============================================================================
# Groups
# =============================================================================

resource "authentik_group" "admins" {
  name         = "Admins"
  is_superuser = true
}

resource "authentik_group" "users" {
  name = "Users"
}

# =============================================================================
# Applications are defined in applications/*.tf
# =============================================================================
