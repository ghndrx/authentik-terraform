# =============================================================================
# Kubeflow - ML Platform Dashboard
# =============================================================================

data "authentik_property_mapping_provider_scope" "kubeflow" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-profile",
  ]
}

resource "authentik_provider_oauth2" "kubeflow" {
  name               = "Kubeflow"
  client_id          = "kubeflow"
  client_type        = "confidential"
  authorization_flow = data.authentik_flow.default_authorization.id
  invalidation_flow  = data.authentik_flow.default_invalidation.id
  
  access_token_validity  = "hours=1"
  refresh_token_validity = "days=30"
  
  property_mappings = data.authentik_property_mapping_provider_scope.kubeflow.ids
  
  allowed_redirect_uris = [
    { matching_mode = "strict", url = "https://kubeflow.walleye-frog.ts.net/oauth2/callback" },
  ]
  
  signing_key = data.authentik_certificate_key_pair.generated.id
}

resource "authentik_application" "kubeflow" {
  name              = "Kubeflow"
  slug              = "kubeflow"
  protocol_provider = authentik_provider_oauth2.kubeflow.id
  
  meta_description = "ML Training Platform"
  meta_launch_url  = "https://kubeflow.walleye-frog.ts.net"
  
  group = "DevOps"
}

output "kubeflow_client_id" {
  value = authentik_provider_oauth2.kubeflow.client_id
}

output "kubeflow_client_secret" {
  value     = authentik_provider_oauth2.kubeflow.client_secret
  sensitive = true
}
