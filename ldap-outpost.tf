# =============================================================================
# LDAP Provider and Outpost for TrueNAS
# Allows LDAP-based authentication against Authentik
# =============================================================================

# LDAP Provider
resource "authentik_provider_ldap" "truenas" {
  name        = "TrueNAS LDAP"
  base_dn     = "dc=ldap,dc=example,dc=com"  # TODO: Update to your domain
  bind_flow   = data.authentik_flow.default_authentication.id
  unbind_flow = data.authentik_flow.default_invalidation.id
  
  # Bind mode - direct means users bind with their own credentials
  bind_mode = "direct"
  
  # Search mode
  search_mode = "direct"
  
  # MFA support (optional)
  mfa_support = false
}

# Application for LDAP
resource "authentik_application" "truenas_ldap" {
  name              = "TrueNAS LDAP"
  slug              = "truenas-ldap"
  protocol_provider = authentik_provider_ldap.truenas.id
  
  meta_description = "LDAP authentication for TrueNAS"
  
  group = "Infrastructure"
}

# LDAP Outpost (standalone container needed for LDAP)
resource "authentik_outpost" "ldap" {
  name               = "LDAP Outpost"
  type               = "ldap"
  protocol_providers = [authentik_provider_ldap.truenas.id]
  
  config = jsonencode({
    authentik_host          = "https://authentik.example.com"  # TODO: Update
    authentik_host_insecure = false
    log_level               = "info"
  })
}

output "ldap_base_dn" {
  value = "dc=ldap,dc=example,dc=com"  # TODO: Update to match above
}
