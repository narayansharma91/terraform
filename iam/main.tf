
locals {
  service_accounts = flatten([
    for service_account_cat in keys(var.service_accounts) : [
      for index, service_account in var.service_accounts[service_account_cat] : [
        {
          name         = service_account.name
          display_name = lookup(service_account, "display_name", ""),
          roles        = service_account.roles
        }
      ]
    ]
  ])

  service_accounts_emails = { for service_account in google_service_account.service_accounts :
    service_account.account_id => service_account
  }

  service_accounts_roles = flatten([for service_account in local.service_accounts : [
    for role in service_account.roles : [
      {
        email = local.service_accounts_emails[service_account.name].email,
        role  = role
        id    = local.service_accounts_emails[service_account.name].id
      }
    ]
  ]])

  user_roles = [for index, role in var.iam_roles : {
    role  = role.role
    index = index
    members = [for member in var.iam_roles[index].members :
      "user:${member}"
    ]
  }]

}

resource "google_service_account" "service_accounts" {
  count        = length(local.service_accounts)
  account_id   = local.service_accounts[count.index].name
  display_name = local.service_accounts[count.index].display_name
}


resource "google_service_account_iam_binding" "service-account-binding" {
  count              = length(local.service_accounts_roles)
  service_account_id = local.service_accounts_roles[count.index].id
  role               = local.service_accounts_roles[count.index].role

  members = [
    "serviceAccount:${local.service_accounts_roles[count.index].email}"
  ]
}

resource "google_project_iam_member" "service-accounts" {
  project = var.project
  count   = length(local.service_accounts_roles)
  role    = local.service_accounts_roles[count.index].role
  member  = "serviceAccount:${local.service_accounts_roles[count.index].email}"
}

resource "google_project_iam_binding" "iam_users" {
  count   = length(local.user_roles)
  role    = local.user_roles[count.index].role
  members = local.user_roles[count.index].members
}