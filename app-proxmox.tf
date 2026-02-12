# =============================================================================
# Proxmox VE - Virtualization Platform
# =============================================================================
# Proxmox VE is an open source server virtualization platform for KVM/LXC.
# This integration uses OIDC for SSO authentication.
#
# Proxmox CLI setup (run on any cluster node):
#   pveum realm add authentik --type openid \
#     --issuer-url https://authentik.example.com/application/o/proxmox/ \
#     --client-id proxmox \
#     --client-key <client_secret> \
#     --username-claim username \
#     --autocreate 1
#
# See: https://integrations.goauthentik.io/hypervisors-orchestrators/proxmox-ve/
# =============================================================================

data "authentik_property_mapping_provider_scope" "proxmox" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-profile",
  ]
}

resource "authentik_provider_oauth2" "proxmox" {
  name               = "Proxmox VE"
  client_id          = "proxmox"
  client_type        = "confidential"
  authorization_flow = data.authentik_flow.default_authorization.id
  invalidation_flow  = data.authentik_flow.default_invalidation.id
  
  access_token_validity  = "hours=1"
  refresh_token_validity = "days=30"
  
  property_mappings = data.authentik_property_mapping_provider_scope.proxmox.ids
  
  # Proxmox OIDC callback - adjust port if not using 8006
  allowed_redirect_uris = [
    { matching_mode = "regex", url = "https://proxmox.*" },
  ]
  
  # Use 'username' claim - Proxmox requires this instead of email
  sub_mode = "user_username"
  
  signing_key = data.authentik_certificate_key_pair.generated.id
}

resource "authentik_application" "proxmox" {
  name              = "Proxmox VE"
  slug              = "proxmox"
  protocol_provider = authentik_provider_oauth2.proxmox.id
  
  meta_description = "Virtualization & Container Platform"
  meta_launch_url  = var.proxmox_url
  
  group = "Infrastructure"
}

# Bind to Infrastructure group - only infra team can access
resource "authentik_policy_binding" "proxmox_infra" {
  target = authentik_application.proxmox.uuid
  group  = authentik_group.infrastructure.id
  order  = 0
}

output "proxmox_client_id" {
  value = authentik_provider_oauth2.proxmox.client_id
}

output "proxmox_client_secret" {
  value     = authentik_provider_oauth2.proxmox.client_secret
  sensitive = true
}
