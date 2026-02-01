# =============================================================================
# Proxy Provider for Arr Stack (Sonarr, Radarr, Prowlarr)
# These apps don't support OIDC natively, use Authentik proxy auth
#
# Note: Each app needs its own provider in Authentik due to 1:1 mapping
# =============================================================================

# Forward auth provider - Sonarr
resource "authentik_provider_proxy" "sonarr" {
  name               = "Sonarr Proxy"
  authorization_flow = data.authentik_flow.default_authorization.id
  invalidation_flow  = data.authentik_flow.default_invalidation.id
  mode               = "forward_single"
  external_host      = "https://sonarr.your-tailnet.ts.net"  # TODO: Update
  access_token_validity = "hours=24"
}

resource "authentik_application" "sonarr" {
  name              = "Sonarr"
  slug              = "sonarr"
  protocol_provider = authentik_provider_proxy.sonarr.id
  meta_description  = "TV Show Automation"
  meta_launch_url   = "https://sonarr.your-tailnet.ts.net"  # TODO: Update
  group             = "Media"
}

# Forward auth provider - Radarr
resource "authentik_provider_proxy" "radarr" {
  name               = "Radarr Proxy"
  authorization_flow = data.authentik_flow.default_authorization.id
  invalidation_flow  = data.authentik_flow.default_invalidation.id
  mode               = "forward_single"
  external_host      = "https://radarr.your-tailnet.ts.net"  # TODO: Update
  access_token_validity = "hours=24"
}

resource "authentik_application" "radarr" {
  name              = "Radarr"
  slug              = "radarr"
  protocol_provider = authentik_provider_proxy.radarr.id
  meta_description  = "Movie Automation"
  meta_launch_url   = "https://radarr.your-tailnet.ts.net"  # TODO: Update
  group             = "Media"
}

# Forward auth provider - Prowlarr
resource "authentik_provider_proxy" "prowlarr" {
  name               = "Prowlarr Proxy"
  authorization_flow = data.authentik_flow.default_authorization.id
  invalidation_flow  = data.authentik_flow.default_invalidation.id
  mode               = "forward_single"
  external_host      = "https://prowlarr.your-tailnet.ts.net"  # TODO: Update
  access_token_validity = "hours=24"
}

resource "authentik_application" "prowlarr" {
  name              = "Prowlarr"
  slug              = "prowlarr"
  protocol_provider = authentik_provider_proxy.prowlarr.id
  meta_description  = "Indexer Manager"
  meta_launch_url   = "https://prowlarr.your-tailnet.ts.net"  # TODO: Update
  group             = "Media"
}

# Note: To use forward auth with Traefik/nginx, configure the embedded outpost
# and add middleware to forward auth requests to Authentik
