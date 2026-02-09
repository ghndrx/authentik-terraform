# =============================================================================
# Custom Authentication Flow with MFA
# Creates a secure authentication flow that requires MFA
# =============================================================================

# -----------------------------------------------------------------------------
# Custom Authentication Flow - With MFA Enforcement
# -----------------------------------------------------------------------------
resource "authentik_flow" "mfa_authentication" {
  name        = "mfa-authentication-flow"
  title       = "Welcome! Please sign in."
  slug        = "mfa-authentication-flow"
  designation = "authentication"
  
  # Background and styling
  background = "/static/dist/assets/images/flow_background.jpg"
  
  # Policy behavior
  policy_engine_mode = "all"
  
  # Compatibility mode for older clients
  compatibility_mode = true
}

# -----------------------------------------------------------------------------
# Stage: User Identification
# First stage - user enters username/email
# -----------------------------------------------------------------------------
data "authentik_stage" "identification" {
  name = "default-authentication-identification"
}

resource "authentik_flow_stage_binding" "identification" {
  target = authentik_flow.mfa_authentication.uuid
  stage  = data.authentik_stage.identification.id
  order  = 10
}

# -----------------------------------------------------------------------------
# Stage: Password Authentication
# Second stage - user enters password
# -----------------------------------------------------------------------------
data "authentik_stage" "password" {
  name = "default-authentication-password"
}

resource "authentik_flow_stage_binding" "password" {
  target = authentik_flow.mfa_authentication.uuid
  stage  = data.authentik_stage.password.id
  order  = 20
}

# -----------------------------------------------------------------------------
# Stage: MFA Validation
# Third stage - require MFA (TOTP, WebAuthn, or recovery code)
# Uses the mfa_validation stage from security-policies.tf
# -----------------------------------------------------------------------------
resource "authentik_flow_stage_binding" "mfa" {
  target = authentik_flow.mfa_authentication.uuid
  stage  = authentik_stage_authenticator_validate.mfa_validation.id
  order  = 30
  
  # Optional: Evaluate on plan to check user context
  evaluate_on_plan = true
  
  # Re-evaluate policies each time
  re_evaluate_policies = true
}

# -----------------------------------------------------------------------------
# Stage: User Login (Session Creation)
# Final stage - create user session after successful auth
# -----------------------------------------------------------------------------
data "authentik_stage" "user_login" {
  name = "default-authentication-login"
}

resource "authentik_flow_stage_binding" "login" {
  target = authentik_flow.mfa_authentication.uuid
  stage  = data.authentik_stage.user_login.id
  order  = 40
}

# -----------------------------------------------------------------------------
# Policy Binding: Reputation Check (Anti-Brute Force)
# Bound to the flow, checks reputation before allowing auth
# -----------------------------------------------------------------------------
resource "authentik_policy_binding" "reputation_check" {
  target = authentik_flow.mfa_authentication.uuid
  policy = authentik_policy_reputation.brute_force_protection.id
  order  = 0
  
  # Fail closed - if policy errors, deny access
  negate  = false
  timeout = 30
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "mfa_authentication_flow_id" {
  description = "ID of the MFA authentication flow"
  value       = authentik_flow.mfa_authentication.uuid
}

output "mfa_authentication_flow_slug" {
  description = "Slug of the MFA authentication flow - use in brand configuration"
  value       = authentik_flow.mfa_authentication.slug
}
