# =============================================================================
# RBAC Groups and Application Permissions
# Defines user groups and their application access
# =============================================================================

# -----------------------------------------------------------------------------
# Core Groups (extend from main.tf)
# -----------------------------------------------------------------------------

# Media group - access to Sonarr, Radarr, Prowlarr, etc.
resource "authentik_group" "media" {
  name = "Media"
  parent = authentik_group.users.id
}

# Infrastructure group - access to monitoring, CI/CD tools
resource "authentik_group" "infrastructure" {
  name = "Infrastructure"
  parent = authentik_group.users.id
}

# Home Automation group - Home Assistant access
resource "authentik_group" "home_automation" {
  name = "Home Automation"
  parent = authentik_group.users.id
}

# -----------------------------------------------------------------------------
# Group-based Access Policies
# Bind these to applications to restrict access
# -----------------------------------------------------------------------------

resource "authentik_policy_expression" "media_access" {
  name       = "media-group-access"
  expression = <<-EOT
    return ak_is_group_member(request.user, name="Media") or ak_is_group_member(request.user, name="Admins")
  EOT
  execution_logging = true
}

resource "authentik_policy_expression" "infrastructure_access" {
  name       = "infrastructure-group-access"
  expression = <<-EOT
    return ak_is_group_member(request.user, name="Infrastructure") or ak_is_group_member(request.user, name="Admins")
  EOT
  execution_logging = true
}

resource "authentik_policy_expression" "home_automation_access" {
  name       = "home-automation-group-access"
  expression = <<-EOT
    return ak_is_group_member(request.user, name="Home Automation") or ak_is_group_member(request.user, name="Admins")
  EOT
  execution_logging = true
}

# -----------------------------------------------------------------------------
# Example: Bind policy to an application
# Uncomment and modify for your applications
# -----------------------------------------------------------------------------
# resource "authentik_policy_binding" "sonarr_media_access" {
#   target = authentik_application.sonarr.uuid
#   policy = authentik_policy_expression.media_access.id
#   order  = 0
# }
#
# resource "authentik_policy_binding" "grafana_infra_access" {
#   target = authentik_application.grafana.uuid
#   policy = authentik_policy_expression.infrastructure_access.id
#   order  = 0
# }

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "media_group_id" {
  description = "ID of the Media group"
  value       = authentik_group.media.id
}

output "infrastructure_group_id" {
  description = "ID of the Infrastructure group"
  value       = authentik_group.infrastructure.id
}

output "home_automation_group_id" {
  description = "ID of the Home Automation group"
  value       = authentik_group.home_automation.id
}
