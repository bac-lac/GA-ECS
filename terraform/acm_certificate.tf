resource "aws_acm_certificate" "baclacgcca" {
  private_key       = "decodebase64(${var.CERT_PRIVATE_KEY})"
  certificate_body  = "decodebase64(${var.CERT_BODY})"
  #certificate_chain = "decodebase64(${var.CERT_CHAIN})"

  lifecycle {
    create_before_destroy = true
  }
}