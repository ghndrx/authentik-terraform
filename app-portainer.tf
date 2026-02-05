# =============================================================================
# Portainer - Container Management
# =============================================================================

data "authentik_property_mapping_provider_scope" "portainer" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-profile",
  ]
}

resource "authentik_provider_oauth2" "portainer" {
  name               = "Portainer"
  client_id          = "portainer"
  client_type        = "confidential"
  authorization_flow = data.authentik_flow.default_authorization.id
  invalidation_flow  = data.authentik_flow.default_invalidation.id
  
  access_token_validity  = "hours=1"
  refresh_token_validity = "days=30"
  
  property_mappings = data.authentik_property_mapping_provider_scope.portainer.ids
  
  allowed_redirect_uris = [
    { matching_mode = "strict", url = "${var.portainer_url}/" },
  ]
  
  signing_key = data.authentik_certificate_key_pair.generated.id
}

resource "authentik_application" "portainer" {
  name              = "Portainer"
  slug              = "portainer"
  protocol_provider = authentik_provider_oauth2.portainer.id
  
  meta_description = "Container Management Platform"
  meta_launch_url  = var.portainer_url
  
  group = "Infrastructure"
}

# Bind Infrastructure group policy to Portainer
resource "authentik_policy_binding" "portainer_infrastructure" {
  target = authentik_application.portainer.uuid
  policy = authentik_policy_expression.infrastructure_access.id
  order  = 0
}

output "portainer_client_id" {
  value = authentik_provider_oauth2.portainer.client_id
}

output "portainer_client_secret" {
  value     = authentik_provider_oauth2.portainer.client_secret
  sensitive = true
}
