# =============================================================================
# Immich - Photo Management
# =============================================================================

data "authentik_property_mapping_provider_scope" "immich" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-profile",
  ]
}

resource "authentik_provider_oauth2" "immich" {
  name               = "Immich"
  client_id          = "immich"
  client_type        = "confidential"
  authorization_flow = data.authentik_flow.default_authorization.id
  invalidation_flow  = data.authentik_flow.default_invalidation.id
  
  access_token_validity  = "hours=1"
  refresh_token_validity = "days=30"
  
  property_mappings = data.authentik_property_mapping_provider_scope.immich.ids
  
  # TODO: Update to your domain
  allowed_redirect_uris = [
    { matching_mode = "strict", url = "https://immich.your-tailnet.ts.net/auth/login" },
    { matching_mode = "strict", url = "https://immich.your-tailnet.ts.net/user-settings" },
    { matching_mode = "strict", url = "app.immich:///oauth-callback" },
  ]
  
  signing_key = data.authentik_certificate_key_pair.generated.id
}

resource "authentik_application" "immich" {
  name              = "Immich"
  slug              = "immich"
  protocol_provider = authentik_provider_oauth2.immich.id
  
  meta_description = "Photo & Video Backup"
  meta_launch_url  = "https://immich.your-tailnet.ts.net"  # TODO: Update
  
  group = "Media"
}

output "immich_client_id" {
  value = authentik_provider_oauth2.immich.client_id
}

output "immich_client_secret" {
  value     = authentik_provider_oauth2.immich.client_secret
  sensitive = true
}
