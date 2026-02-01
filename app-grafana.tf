# =============================================================================
# Grafana - Monitoring Dashboards
# =============================================================================

data "authentik_property_mapping_provider_scope" "grafana" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-profile",
  ]
}

resource "authentik_provider_oauth2" "grafana" {
  name               = "Grafana"
  client_id          = "grafana"
  client_type        = "confidential"
  authorization_flow = data.authentik_flow.default_authorization.id
  invalidation_flow  = data.authentik_flow.default_invalidation.id
  
  access_token_validity  = "hours=1"
  refresh_token_validity = "days=30"
  
  property_mappings = data.authentik_property_mapping_provider_scope.grafana.ids
  
  # TODO: Update to your domains
  allowed_redirect_uris = [
    { matching_mode = "strict", url = "https://grafana.your-tailnet.ts.net/login/generic_oauth" },
    { matching_mode = "strict", url = "https://grafana.example.com/login/generic_oauth" },
  ]
  
  signing_key = data.authentik_certificate_key_pair.generated.id
}

resource "authentik_application" "grafana" {
  name              = "Grafana"
  slug              = "grafana"
  protocol_provider = authentik_provider_oauth2.grafana.id
  
  meta_description = "Monitoring & Observability Dashboards"
  meta_launch_url  = "https://grafana.your-tailnet.ts.net"  # TODO: Update
  
  group = "Monitoring"
}

output "grafana_client_id" {
  value = authentik_provider_oauth2.grafana.client_id
}

output "grafana_client_secret" {
  value     = authentik_provider_oauth2.grafana.client_secret
  sensitive = true
}
