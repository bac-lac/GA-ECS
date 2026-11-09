resource "aws_rolesanywhere_trust_anchor" "ca" {
  name          = "BAC-LAC-CA-${var.ENV}"
  enabled       = true
  source {
    source_type = "CERTIFICATE_BUNDLE"
    source_data {
      x509_certificate_data = trimspace(base64decode(var.ROLESANYWHERE_ROOT_CA_PEM))
    }
  }
}

resource "aws_rolesanywhere_profile" "profile" {
  name          = "goanywhere-profile-${var.ENV}"
  enabled       = true
  role_arns     = [aws_iam_role.roles_anywhere.arn]
}