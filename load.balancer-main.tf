
### #################### ###
### [[resource]] aws_alb ###
### #################### ###

resource aws_alb alb
{
    name            = "applb-${ var.in_ecosystem }"
    security_groups = [ "${var.in_security_group_id}" ]
    subnets         = [ "${var.in_subnet_ids}" ]
    internal        = "${ var.in_is_internal ? "true" : "false" }"

    enable_deletion_protection = false
    load_balancer_type         = "application"
    idle_timeout               = 60
    ip_address_type            = "ipv4"  # either ipv4 or dualstack (for both IPv4 and IPv6)

    tags
    {
        Name   = "alb-${ var.in_ecosystem }-${ module.ecosys.out_stamp }-${ var.in_is_internal ? "x" : "o" }"
        Class = "${ var.in_ecosystem }"
        Instance = "${ var.in_ecosystem }-${ module.ecosys.out_stamp }"
        Desc   = "This app load balancer for ${ var.in_ecosystem } ${ module.ecosys.out_history_note }"
    }

}


### ############################# ###
### [[resource]] aws_alb_listener ###
### ############################# ###

resource aws_alb_listener http_listener
{
    count = "${ length( var.in_front_end ) }"

    load_balancer_arn = "${ aws_alb.alb.arn }"
    port              = "${ element( var.commons[ var.in_front_end[ count.index ] ], 1 ) }"
    protocol          = "${ element( var.commons[ var.in_front_end[ count.index ] ], 0 ) }"

    default_action
    {
        target_group_arn = "${ element( aws_alb_target_group.alb_targets.*.arn, count.index ) }"
        type = "forward"
    }
}


### ################################# ###
### [[resource]] aws_alb_target_group ###
### ################################# ###

resource aws_alb_target_group alb_targets
{
    count       = "${ length( var.in_back_end ) }"
    name        = "tg-${ var.in_ecosystem }"
    protocol    = "${ element( var.commons[ var.in_back_end[ count.index ] ], 0 ) }"
    port        = "${ element( var.commons[ var.in_back_end[ count.index ] ], 1 ) }"
    vpc_id      = "${ var.in_vpc_id }"
    target_type = "ip"

    health_check
    {
        healthy_threshold   = 3
        unhealthy_threshold = 10
        timeout             = 5
        interval            = 10
        protocol            = "${ element( var.commons[ var.in_back_end[ count.index ] ], 0 ) }"
        port                = "${ element( var.commons[ var.in_back_end[ count.index ] ], 1 ) }"
        path                = "${ element( var.commons[ var.in_back_end[ count.index ] ], 2 ) }"
    }

    tags
    {
        Name   = "alb-tg-${ var.in_ecosystem }-${ module.ecosys.out_stamp }"
        Class = "${ var.in_ecosystem }"
        Instance = "${ var.in_ecosystem }-${ module.ecosys.out_stamp }"
        Desc   = "This alb http target group for ${ var.in_ecosystem } ${ module.ecosys.out_history_note }"
    }

}


# = ===
# = Note that the port here is always mapped to the port specified
# = in the first backend target group.
# = ===
resource aws_lb_target_group_attachment connect
{
    count            = "${ var.in_ip_address_count }"
    target_group_arn = "${ element( aws_alb_target_group.alb_targets.*.arn, 0 ) }"
    target_id        = "${ element( var.in_ip_addresses, count.index ) }"
    port             = "${ element( var.commons[ var.in_back_end[ 0 ] ], 1 ) }"
}


### ################# ###
### [[module]] ecosys ###
### ################# ###

module ecosys
{
    source = "github.com/devops4me/terraform-aws-stamps"
}

/*
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
