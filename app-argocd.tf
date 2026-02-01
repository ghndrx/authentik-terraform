# =============================================================================
# ArgoCD - GitOps Continuous Delivery
# =============================================================================

data "authentik_property_mapping_provider_scope" "argocd" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-profile",
  ]
}

resource "authentik_provider_oauth2" "argocd" {
  name               = "ArgoCD"
  client_id          = "argocd"
  client_type        = "confidential"
  authorization_flow = data.authentik_flow.default_authorization.id
  invalidation_flow  = data.authentik_flow.default_invalidation.id
  
  access_token_validity  = "hours=1"
  refresh_token_validity = "days=30"
  
  property_mappings = data.authentik_property_mapping_provider_scope.argocd.ids
  
  # ArgoCD callback URLs - TODO: Update to your domains
  allowed_redirect_uris = [
    { matching_mode = "strict", url = "https://argo.your-tailnet.ts.net/auth/callback" },
    { matching_mode = "strict", url = "https://argocd.example.com/auth/callback" },
  ]
  
  signing_key = data.authentik_certificate_key_pair.generated.id
}

resource "authentik_application" "argocd" {
  name              = "ArgoCD"
  slug              = "argocd"
  protocol_provider = authentik_provider_oauth2.argocd.id
  
  meta_description = "GitOps Continuous Delivery"
  meta_launch_url  = "https://argocd.your-tailnet.ts.net"  # TODO: Update
  
  group = "DevOps"
}

output "argocd_client_id" {
  value = authentik_provider_oauth2.argocd.client_id
}

output "argocd_client_secret" {
  value     = authentik_provider_oauth2.argocd.client_secret
  sensitive = true
}
