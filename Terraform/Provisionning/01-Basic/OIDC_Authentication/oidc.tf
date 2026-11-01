# The Bastion doesn't read discovery_url at creation: the endpoints come from the discovery document, read here.
data "http" "oidc_discovery" {
  url             = var.oidc_discovery_url
  request_headers = { Accept = "application/json" }

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "The discovery document ${var.oidc_discovery_url} returned HTTP ${self.status_code}."
    }
  }
}

locals {
  oidc = jsondecode(data.http.oidc_discovery.response_body)
}

# Connection to the identity provider (OIDC client of the Bastion).
resource "wallix-bastion_externalauth_oidc" "idp" {
  authentication_name = var.oidc_name
  description         = "Automation Showroom: OIDC example"
  timeout             = 30
  client_id           = var.oidc_client_id
  discovery_url       = var.oidc_discovery_url

  # Write-only: sent to the Bastion, never stored in the state. Bump the version to send a new secret.
  client_secret_wo         = var.oidc_client_secret
  client_secret_wo_version = var.oidc_client_secret_version

  claim_customization {
    username    = var.oidc_claims.username
    group       = var.oidc_claims.group
    email       = var.oidc_claims.email
    displayname = var.oidc_claims.displayname
  }

  oidc_advanced_attributes {
    issuer                                = local.oidc.issuer
    scope                                 = var.oidc_scopes
    authorization_endpoint                = local.oidc.authorization_endpoint
    token_endpoint                        = local.oidc.token_endpoint
    userinfo_url_endpoint                 = try(local.oidc.userinfo_endpoint, null)
    jwks_uri                              = local.oidc.jwks_uri
    id_token_signing_alg_values_supported = local.oidc.id_token_signing_alg_values_supported
  }
}

# Login choice shown on the Bastion login page; users of this domain authenticate on the identity provider.
resource "wallix-bastion_authdomain_oidc" "idp" {
  domain_name          = var.authdomain.domain_name
  auth_domain_name     = var.authdomain.auth_domain_name
  label                = var.authdomain.label
  default_email_domain = var.authdomain.default_email_domain
  default_language     = var.authdomain.default_language
  external_auths       = [wallix-bastion_externalauth_oidc.idp.authentication_name]
}
