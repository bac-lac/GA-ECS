data "aws_lb" "ga_alb"{
  name = "ga-alb-${var.ENV}"
}

resource "aws_lb_listener" "https" {
  load_balancer_arn   = data.aws_lb.ga_alb.arn
  port                = "443"
  protocol            = "HTTPS"
  ssl_policy          = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
  certificate_arn     = aws_acm_certificate.baclacgcca.arn
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Invalid host header."
      status_code  = "400"
    }
  }
}

resource "aws_lb_listener_rule" "admin_portal_rule" {
  listener_arn        = aws_lb_listener.https.arn
  action {
    type              = "forward"
    target_group_arn  = aws_lb_target_group.ga_tg_8001.arn
  }
  condition {
    host_header {
      values          = [upper(var.ENV) == "PROD" ? "goanywhere.bac-lac.gc.ca" : "goanywhere-${var.ENV}.bac-lac.gc.ca"]
    }
  }
  tags = {
    Name = "Admin-${var.ENV}"
  }
}

resource "aws_lb_listener_rule" "internal_admin_portal_rule" {
  listener_arn        = aws_lb_listener.https.arn
  action {
    type              = "forward"
    target_group_arn  = aws_lb_target_group.ga_tg_8001.arn
  }
  condition {
    host_header {
      values          = [upper(var.ENV) == "PROD" ? "ga-internal.bac-lac.gc.ca" : "ga-${var.ENV}-internal.bac-lac.gc.ca"]
    }
  }
  tags = {
    Name = "Internal-Admin-${var.ENV}"
  }
}

resource "aws_lb_target_group" "ga_tg_8001" {
  name        = "ga-tg-${var.ENV}-8001"
  port        = 8001
  protocol    = "HTTPS"
  target_type = "ip"
  vpc_id      = data.aws_vpc.vpc.id
  health_check {
    path      = "/"
    matcher   = "200,302"
    port      = 8001
    protocol  = "HTTPS"
  }
  stickiness {
    enabled   = true
    type      = "lb_cookie"
  }
  tags = {
    Name = "Admin-${var.ENV}"
  }
}

resource "aws_lb_listener_rule" "web_client_rule" {
  listener_arn        = aws_lb_listener.https.arn
  action {
    type              = "forward"
    target_group_arn  = aws_lb_target_group.ga_tg_8443.arn
  }
  condition {
    host_header {
      values          = [upper(var.ENV) == "PROD" ? "transfert-transfer-dev.bac-lac.gc.ca" : "transfert-transfer-${var.ENV}.bac-lac.gc.ca"]
    }
  }
  tags = {
    Name = "Web-Client-${var.ENV}"
  }
}

resource "aws_lb_target_group" "ga_tg_8443" {
  name        = "ga-tg-${var.ENV}-8443"
  port        = 8443
  protocol    = "HTTPS"
  target_type = "ip"
  vpc_id      = data.aws_vpc.vpc.id
  health_check {
    path      = "/"
    matcher   = "200,302"
    port      = 8443
    protocol  = "HTTPS"
  }
  stickiness {
    enabled   = true
    type      = "lb_cookie"
  }
  tags = {
    Name = "Web-client-${var.ENV}"
  }
}


data "aws_lb" "ga_nlb"{
  name = "ga-nlb-${var.ENV}"
}

resource "aws_lb_listener" "sftp" {
  load_balancer_arn   = data.aws_lb.ga_nlb.arn
  port                = "8022"
  protocol            = "TCP"
  default_action {
    type              = "forward"
    target_group_arn  = aws_lb_target_group.ga_tg_8022.arn
  }
  tags = {
    Name = "SFTP-${var.ENV}"
  }
}

resource "aws_lb_target_group" "ga_tg_8022" {
  name        = "ga-tg-${var.ENV}-8022"
  port        = 8022
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.vpc.id
  health_check {
    port      = 8022
    protocol  = "TCP"
  }
  tags = {
    Name = "SFTP-${var.ENV}"
  }
}

resource "aws_lb_listener" "agent" {
  load_balancer_arn   = data.aws_lb.ga_nlb.arn
  port                = "8009"
  protocol            = "TCP"
  default_action {
    type              = "forward"
    target_group_arn  = aws_lb_target_group.ga_tg_8009.arn
  }
  tags = {
    Name = "Agent-${var.ENV}"
  }
}

resource "aws_lb_target_group" "ga_tg_8009" {
  name        = "ga-tg-${var.ENV}-8009"
  port        = 8009
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.vpc.id
  health_check {
    port      = 8009
    protocol  = "TCP"
  }
  tags = {
    Name = "Agent-${var.ENV}"
  }
}