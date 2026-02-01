# =============================================================================
# Uptime Kuma - Status Monitoring
# Uses proxy authentication (UK doesn't support native OIDC login)
# =============================================================================

resource "authentik_provider_proxy" "uptime_kuma" {
  name               = "Uptime Kuma Proxy"
  authorization_flow = data.authentik_flow.default_authorization.id
  invalidation_flow  = data.authentik_flow.default_invalidation.id
  mode               = "forward_single"
  
  external_host         = "https://uptime.example.com"  # TODO: Update
  access_token_validity = "hours=24"
}

resource "authentik_application" "uptime_kuma" {
  name              = "Uptime Kuma"
  slug              = "uptime-kuma"
  protocol_provider = authentik_provider_proxy.uptime_kuma.id
  
  meta_description = "Service Status Monitoring"
  meta_launch_url  = "https://uptime.example.com"  # TODO: Update
  
  group = "Monitoring"
}

# Note: Configure your reverse proxy (nginx/traefik/cloudflare) 
# to use Authentik forward auth before proxying to Uptime Kuma
# 
# With disableAuth=true in UK, Authentik handles all authentication
