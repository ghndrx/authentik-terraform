output "authentik_url" {
  description = "Authentik instance URL"
  value       = var.authentik_url
}

output "admin_group_id" {
  description = "Admin group ID for RBAC"
  value       = authentik_group.admins.id
}

output "users_group_id" {
  description = "Users group ID"
  value       = authentik_group.users.id
}
