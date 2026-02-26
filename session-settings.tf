# =============================================================================
# Session Security Settings
# Controls session duration, idle timeout, and remember-me functionality
# =============================================================================

# -----------------------------------------------------------------------------
# User Login Stage - Session Duration Configuration
# Overrides default session settings for the custom MFA flow
# -----------------------------------------------------------------------------
resource "authentik_stage_user_login" "secure_login" {
  name = "secure-user-login"
  
  # Session duration - how long until session expires
  session_duration = var.session_duration
  
  # Remember me offset - duration for "remember me" checkbox
  remember_me_offset = var.remember_me_duration
  
  # Terminate other sessions on login (optional - enhances security)
  # Set to true to prevent concurrent sessions
  terminate_other_sessions = false
  
  # Network binding mode - bind session to IP for extra security
  # Options: no_binding, bind_asn, bind_asn_network, bind_asn_network_ip
  # Warning: bind_asn_network_ip may cause issues with mobile users
  network_binding = "bind_asn"
  
  # Geo-IP binding - bind session to geographic location
  # Options: no_binding, bind_continent, bind_continent_country, bind_continent_country_city
  geoip_binding = "bind_continent_country"
}

# -----------------------------------------------------------------------------
# Output for reference
# -----------------------------------------------------------------------------
output "secure_login_stage_id" {
  description = "ID of the secure login stage with session controls"
  value       = authentik_stage_user_login.secure_login.id
}
