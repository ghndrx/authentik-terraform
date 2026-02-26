################################################################################
# Authentik Terraform Variables
#
# Set these via:
# - GitHub Actions secrets (recommended)
# - terraform.tfvars (local dev only - never commit!)
# - Environment variables (TF_VAR_*)
################################################################################

# Authentik Connection
variable "authentik_url" {
  type        = string
  description = "Authentik server URL (e.g., https://auth.example.com)"
}

variable "authentik_token" {
  type        = string
  sensitive   = true
  description = "Authentik API token"
}

# Google OAuth (optional)
variable "google_client_id" {
  type        = string
  default     = ""
  description = "Google OAuth client ID"
}

variable "google_client_secret" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Google OAuth client secret"
}

# Application URLs
variable "argocd_url" {
  type        = string
  default     = ""
  description = "ArgoCD URL for SSO"
}

variable "grafana_url" {
  type        = string
  default     = ""
  description = "Grafana URL for SSO"
}

variable "home_assistant_url" {
  type        = string
  default     = ""
  description = "Home Assistant URL for proxy auth"
}

variable "immich_url" {
  type        = string
  default     = ""
  description = "Immich URL for proxy auth"
}

variable "uptime_kuma_url" {
  type        = string
  default     = ""
  description = "Uptime Kuma URL for proxy auth"
}

variable "sonarr_url" {
  type        = string
  default     = ""
  description = "Sonarr URL for proxy auth"
}

variable "radarr_url" {
  type        = string
  default     = ""
  description = "Radarr URL for proxy auth"
}

variable "prowlarr_url" {
  type        = string
  default     = ""
  description = "Prowlarr URL for proxy auth"
}

variable "portainer_url" {
  type        = string
  default     = ""
  description = "Portainer URL for SSO"
}

variable "proxmox_url" {
  type        = string
  default     = ""
  description = "Proxmox VE URL for SSO (e.g., https://proxmox.example.com:8006)"
}

# LDAP Configuration
variable "ldap_base_dn" {
  type        = string
  default     = "dc=ldap,dc=example,dc=com"
  description = "LDAP base DN"
}

# Security Configuration
variable "enable_mfa_flow" {
  type        = bool
  default     = false
  description = "Use custom MFA authentication flow instead of default"
}

variable "mfa_enforcement" {
  type        = string
  default     = "configure"
  description = "MFA enforcement mode: 'skip' (optional), 'configure' (prompt to set up), 'deny' (required)"
  validation {
    condition     = contains(["skip", "configure", "deny"], var.mfa_enforcement)
    error_message = "MFA enforcement must be one of: skip, configure, deny"
  }
}

# Brand Configuration
variable "brand_domain" {
  type        = string
  default     = "auth.gregh.dev"
  description = "Primary domain for Authentik brand configuration"
}

variable "brand_title" {
  type        = string
  default     = "Greg's Lab"
  description = "Branding title displayed in Authentik UI"
}

# Session Security
variable "session_duration" {
  type        = string
  default     = "hours=24"
  description = "Session duration before requiring re-authentication (e.g., hours=24, days=7)"
}

variable "remember_me_duration" {
  type        = string
  default     = "days=30"
  description = "Duration for 'remember me' sessions"
}
