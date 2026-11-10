resource "aws_acm_certificate" "baclacgcca" {
  private_key       = "base64decode(${var.CERT_PRIVATE_KEY})"
  certificate_body  = "base64decode(${var.CERT_BODY})"
  #certificate_chain = "base64decode(${var.CERT_CHAIN})"

  lifecycle {
    create_before_destroy = true
  }
}