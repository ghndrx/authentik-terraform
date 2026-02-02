# =============================================================================
# Security Policies for Authentik
# Provides password requirements, MFA, and brute-force protection
# =============================================================================

# -----------------------------------------------------------------------------
# Password Policy - Strong requirements with breach checking
# -----------------------------------------------------------------------------
resource "authentik_policy_password" "strong_password" {
  name          = "strong-password-policy"
  error_message = "Password does not meet security requirements"
  
  # Minimum length
  length_min = 12
  
  # Character requirements
  amount_digits    = 1
  amount_lowercase = 1
  amount_uppercase = 1
  amount_symbols   = 1
  
  # Enable Have I Been Pwned checking
  check_have_i_been_pwned = true
  hibp_allowed_count      = 0  # Reject any password found in breaches
  
  # Enable zxcvbn password strength checking
  check_zxcvbn         = true
  zxcvbn_score_threshold = 3  # Require "strong" passwords (0-4 scale)
  
  check_static_rules = true
  execution_logging  = true
}

# -----------------------------------------------------------------------------
# Unique Password Policy - Prevent password reuse
# -----------------------------------------------------------------------------
resource "authentik_policy_unique_password" "no_reuse" {
  name             = "no-password-reuse"
  num_historical_passwords = 5  # Remember last 5 passwords
  execution_logging = true
}

# -----------------------------------------------------------------------------
# Password Expiry Policy - Force periodic password changes (optional)
# Uncomment to enable password expiration
# -----------------------------------------------------------------------------
# resource "authentik_policy_expiry" "password_expiry" {
#   name    = "password-expiry-90-days"
#   days    = 90
#   deny_only = false
#   execution_logging = true
# }

# -----------------------------------------------------------------------------
# Reputation Policy - Brute force protection
# Blocks IPs/usernames after repeated failed attempts
# -----------------------------------------------------------------------------
resource "authentik_policy_reputation" "brute_force_protection" {
  name           = "brute-force-protection"
  check_ip       = true
  check_username = true
  threshold      = 5  # Block after 5 failed attempts
  execution_logging = true
}

# -----------------------------------------------------------------------------
# TOTP Setup Stage - Allow users to configure MFA
# -----------------------------------------------------------------------------
resource "authentik_stage_authenticator_totp" "totp_setup" {
  name   = "totp-setup"
  digits = "6"
  friendly_name = "Authenticator App (TOTP)"
}

# WebAuthn/Passkeys Setup Stage
resource "authentik_stage_authenticator_webauthn" "webauthn_setup" {
  name              = "webauthn-setup"
  friendly_name     = "Security Key / Passkey"
  user_verification = "preferred"
  resident_key_requirement = "preferred"  # Support passkeys
}

# Static Recovery Codes Setup
resource "authentik_stage_authenticator_static" "static_setup" {
  name          = "static-recovery-codes"
  friendly_name = "Recovery Codes"
  token_count   = 10
  token_length  = 12
}

# -----------------------------------------------------------------------------
# MFA Validation Stage - Require MFA during authentication
# Configure with "deny" to require MFA, or "configure" to prompt setup
# -----------------------------------------------------------------------------
resource "authentik_stage_authenticator_validate" "mfa_validation" {
  name = "mfa-validation"
  
  # Options: skip, deny, configure
  # - skip: Don't require MFA if not configured
  # - deny: Block login if MFA not configured (after enabling, users need MFA)
  # - configure: Force users to set up MFA if not configured
  not_configured_action = "configure"
  
  # Supported authenticator types
  device_classes = [
    "totp",      # Authenticator apps
    "webauthn",  # Security keys / Passkeys
    "static",    # Recovery codes
  ]
  
  # Link to setup stages for "configure" action
  configuration_stages = [
    authentik_stage_authenticator_totp.totp_setup.id,
    authentik_stage_authenticator_webauthn.webauthn_setup.id,
    authentik_stage_authenticator_static.static_setup.id,
  ]
  
  # Re-authenticate after 12 hours even if "remember this device" is used
  last_auth_threshold = "hours=12"
  
  # WebAuthn settings
  webauthn_user_verification = "preferred"
}

# -----------------------------------------------------------------------------
# Expression Policy - Admin-only access for sensitive apps
# Example: Bind this to admin-only applications
# -----------------------------------------------------------------------------
resource "authentik_policy_expression" "admin_only" {
  name       = "admin-only-access"
  expression = <<-EOT
    return ak_is_group_member(request.user, name="Admins")
  EOT
  execution_logging = true
}

# Expression Policy - Require MFA for app access
resource "authentik_policy_expression" "require_mfa_configured" {
  name       = "require-mfa-configured"
  expression = <<-EOT
    from authentik.stages.authenticator.models import Device
    
    # Check if user has any MFA device configured
    devices = Device.objects.filter(user=request.user, confirmed=True)
    return devices.exists()
  EOT
  execution_logging = true
}

# -----------------------------------------------------------------------------
# GeoIP Policy - Block logins from suspicious locations (optional)
# Requires GeoIP database configured in Authentik
# Uncomment to enable
# -----------------------------------------------------------------------------
# resource "authentik_policy_geoip" "block_high_risk_countries" {
#   name = "block-high-risk-countries"
#   asns = []
#   countries = []  # Add country codes to block, e.g., ["RU", "CN", "KP"]
#   execution_logging = true
# }

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "password_policy_id" {
  description = "ID of the strong password policy"
  value       = authentik_policy_password.strong_password.id
}

output "mfa_validation_stage_id" {
  description = "ID of the MFA validation stage - bind to authentication flow"
  value       = authentik_stage_authenticator_validate.mfa_validation.id
}

output "admin_policy_id" {
  description = "ID of the admin-only policy - bind to sensitive applications"
  value       = authentik_policy_expression.admin_only.id
}
