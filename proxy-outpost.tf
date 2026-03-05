# =============================================================================
# Proxy Outpost - Standalone Forward Auth Service
# Replaces embedded outpost to resolve 404 "no value given for required property pk" errors
# =============================================================================

resource "authentik_outpost" "proxy" {
  name = "Standalone Proxy Outpost"
  type = "proxy"
  
  # Attach all proxy providers
  protocol_providers = [
    authentik_provider_proxy.uptime_kuma.id,
    authentik_provider_proxy.sonarr.id,
    authentik_provider_proxy.radarr.id,
    authentik_provider_proxy.prowlarr.id,
  ]
  
  config = jsonencode({
    authentik_host          = var.authentik_host
    authentik_host_insecure = var.authentik_host_insecure
    log_level               = var.outpost_log_level
    
    # Docker labels for integration
    docker_labels = {
      "traefik.enable" = "true"
      "traefik.http.routers.authentik-outpost.rule" = "Host(`${var.brand_domain}`) && PathPrefix(`/outpost.goauthentik.io/`)"
      "traefik.http.routers.authentik-outpost.entrypoints" = "https"
      "traefik.http.services.authentik-outpost.loadbalancer.server.port" = "9000"
    }
  })
  
  # Service connection configuration
  service_connection = var.outpost_service_connection
}

# Docker Compose snippet for deployment
output "proxy_outpost_docker_compose" {
  description = "Docker Compose configuration for proxy outpost"
  value = <<-EOT
    services:
      authentik-proxy-outpost:
        image: ghcr.io/goauthentik/proxy:latest
        container_name: authentik-proxy-outpost
        restart: unless-stopped
        ports:
          - "9000:9000"
          - "9443:9443"
        environment:
          AUTHENTIK_HOST: ${var.authentik_host}
          AUTHENTIK_INSECURE: ${var.authentik_host_insecure}
          AUTHENTIK_TOKEN: <get_from_terraform_output>
        labels:
          - "traefik.enable=true"
          - "traefik.http.routers.authentik-outpost.rule=Host(`${var.brand_domain}`) && PathPrefix(`/outpost.goauthentik.io/`)"
          - "traefik.http.routers.authentik-outpost.entrypoints=https"
          - "traefik.http.services.authentik-outpost.loadbalancer.server.port=9000"
        networks:
          - proxy
    
    networks:
      proxy:
        external: true
  EOT
}

# Output the outpost token (sensitive)
output "proxy_outpost_token" {
  description = "Outpost token for authentication (use in AUTHENTIK_TOKEN env var)"
  value       = authentik_outpost.proxy.config
  sensitive   = true
}
