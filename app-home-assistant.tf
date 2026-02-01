# =============================================================================
# Home Assistant - Smart Home
# =============================================================================

data "authentik_property_mapping_provider_scope" "home_assistant" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-profile",
  ]
}

resource "authentik_provider_oauth2" "home_assistant" {
  name               = "Home Assistant"
  client_id          = "home-assistant"
  client_type        = "confidential"
  authorization_flow = data.authentik_flow.default_authorization.id
  invalidation_flow  = data.authentik_flow.default_invalidation.id
  
  access_token_validity  = "hours=1"
  refresh_token_validity = "days=30"
  
  property_mappings = data.authentik_property_mapping_provider_scope.home_assistant.ids
  
  # TODO: Update to your domain
  allowed_redirect_uris = [
    { matching_mode = "strict", url = "https://home.your-tailnet.ts.net/auth/external/callback" },
  ]
  
  signing_key = data.authentik_certificate_key_pair.generated.id
}

resource "authentik_application" "home_assistant" {
  name              = "Home Assistant"
  slug              = "home-assistant"
  protocol_provider = authentik_provider_oauth2.home_assistant.id
  
  meta_description = "Smart Home Control"
  meta_launch_url  = "https://home.your-tailnet.ts.net"  # TODO: Update
  
  group = "Home"
}

output "home_assistant_client_id" {
  value = authentik_provider_oauth2.home_assistant.client_id
}

output "home_assistant_client_secret" {
  value     = authentik_provider_oauth2.home_assistant.client_secret
  sensitive = true
}
