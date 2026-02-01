# =============================================================================
# Google Workspace Federation
# Allow users to sign in with their Google Workspace accounts
# =============================================================================

# Google OAuth Source
resource "authentik_source_oauth" "google" {
  name                = "Google Workspace"
  slug                = "google"
  authentication_flow = data.authentik_flow.default_authentication.id
  enrollment_flow     = data.authentik_flow.default_enrollment.id
  
  provider_type   = "google"
  consumer_key    = data.sops_file.secrets.data["google_client_id"]
  consumer_secret = data.sops_file.secrets.data["google_client_secret"]
  
  # PKCE method - S256 is recommended
  pkce = "S256"
  
  # User matching - link by email
  user_matching_mode = "email_link"
  
  # Policy engine
  policy_engine_mode = "any"
  
  # Enable for login page
  enabled = true
}

# Note: After applying, the Google login button will appear on the Authentik login page.
# Users with matching emails will be linked; new users will be enrolled.
