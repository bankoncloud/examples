/* Org policy overrides for test project */

module "org_vm_external_ip_access" {
  source          = "terraform-google-modules/org-policy/google"
  version         = "~> 3.0"
  policy_for      = "project"
  project_id      = var.project
  policy_type     = "list"
  enforce         = "false"
  constraint      = "constraints/compute.vmExternalIpAccess"
}