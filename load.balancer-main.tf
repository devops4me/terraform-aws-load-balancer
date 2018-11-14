
### #################### ###
### [[resource]] aws_alb ###
### #################### ###

resource aws_alb alb
{
    name            = "applb-${ var.in_ecosystem }"
    security_groups = [ "${var.in_security_group_id}" ]
    subnets         = [ "${var.in_subnet_ids}" ]
    internal        = "true"

    enable_deletion_protection  = false
    load_balancer_type          = "application"
    idle_timeout                = 60
    ip_address_type             = "ipv4"  # use either ipv4 or dualstack (must specify subnets with an associated IPv6 CIDR block)

    tags
    {
        Name   = "alb-${ var.in_ecosystem }-${ module.ecosys.out_stamp }"
        Class = "${ var.in_ecosystem }"
        Instance = "${ var.in_ecosystem }-${ module.ecosys.out_stamp }"
        Desc   = "This app load balancer for ${ var.in_ecosystem } ${ module.ecosys.out_history_note }"
    }

}


### ################################# ###
### [[resource]] aws_alb_target_group ###
### ################################# ###

resource aws_alb_target_group alb_targets
{
    count             = "1"
    name     = "tg-${ var.in_ecosystem }"
    protocol = "HTTPS"
    port     = "443"
    vpc_id   = "${ var.in_vpc_id }"
    target_type = "ip"

    health_check
    {
        healthy_threshold   = 3
        unhealthy_threshold = 10
        timeout             = 5
        interval            = 10
        path                = "/_cluster/health"
        port                = 443
        protocol            = "HTTPS"
    }

    tags
    {
        Name   = "alb-tg-${ var.in_ecosystem }-${ module.ecosys.out_stamp }"
        Class = "${ var.in_ecosystem }"
        Instance = "${ var.in_ecosystem }-${ module.ecosys.out_stamp }"
        Desc   = "This alb target group for ${ var.in_ecosystem } ${ module.ecosys.out_history_note }"
    }

}


### ############################# ###
### [[resource]] aws_alb_listener ###
### ############################# ###

resource aws_alb_listener http_listener
{
    count             = "1"
    load_balancer_arn = "${aws_alb.alb.arn}"
    port                = 80
    protocol            = "HTTP"

default_action {
    target_group_arn = "${element(aws_alb_target_group.alb_targets.*.arn, 0)}"
    type = "forward"
  }
}


/*
resource aws_alb_listener https_listener
{
    count             = "1"
    load_balancer_arn = "${aws_alb.alb.arn}"
    port                = 443
    protocol            = "HTTPS"
    certificate_arn     = "arn:aws:iam::<<account-id>>:server-certificate/<<certificate-id>>"
    ssl_policy          = "ELBSecurityPolicy-2016-08"

default_action {
    target_group_arn = "${element(aws_alb_target_group.alb_targets.*.arn, 0)}"
    type = "forward"
  }
}
*/


### ########################################### ###
### [[resource]] aws_lb_target_group_attachment ###
### ########################################### ###

resource aws_lb_target_group_attachment connect
{
    count            = "${ var.in_ip_address_count }"
    target_group_arn = "${element(aws_alb_target_group.alb_targets.*.arn, 0)}"
    target_id        = "${ element( var.in_ip_addresses, count.index ) }"
    port             = 443
}


### ################# ###
### [[module]] ecosys ###
### ################# ###

module ecosys
{
    source = "github.com/devops4me/terraform-aws-stamps"
}
