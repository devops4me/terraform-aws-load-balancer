
/*
 | --
 | -- Listeners are the front-end (ears) whilst target groups are the
 | -- back-end of our load balancer setup.
 | --
 | -- This highly reusable module allows one t configure any number of
 | -- listeners and targets each with words like "etcd" and "rabbitmq".
 | --
 | -- At its architectural heart the application load balancer is designed
 | -- to separate interface from implementation and it does this serenely
 | -- either working at network layer 4 (network load balancer) or layer 7
 | -- for application load balancers.
 | --
*/
resource aws_alb alb
{
    name               = "${ var.in_ecosystem_name }-${ var.in_tag_timestamp }"
    security_groups    = [ "${var.in_security_group_ids}" ]
    subnets            = [ "${var.in_subnet_ids}" ]
    internal           = "${ var.in_is_internal ? "true" : "false" }"
    load_balancer_type = "${var.in_lb_class}"

    enable_deletion_protection = false
    idle_timeout               = 60
    ip_address_type            = "ipv4"

    tags
    {
        Name = "${var.in_lb_class}-load-balancer-${ var.in_ecosystem_name }-${ var.in_tag_timestamp }"
        Class = "${ var.in_ecosystem_name }"
        Instance = "${ var.in_ecosystem_name }-${ var.in_tag_timestamp }"
        Desc   = "This ${ var.in_is_internal ? "in" : "ex" }ternal ${var.in_lb_class} load balancer for ${ var.in_ecosystem_name } ${ var.in_tag_description }"
    }

}


/*
 | --
 | -- Listeners are the front-end (ears) of our load balancer setup which
 | -- is designed to separate interface from implementation.
 | --
 | -- We can demand a "ssl" front end listener (with an SSL certificate)
 | -- accepting connections on port 443 and route its traffic to a
 | -- plaintext etcd key-value store listening on port 2379.
 | --
 | -- This SSL front-end and plaintext HTTP back-end can be achieved
 | -- because the application load balancer (alb) operates at the network
 | -- layer 4 (in contrast to NLB operating at layer 7).
 | --
*/
resource aws_alb_listener http_listener
{
    count = "${ length( var.in_front_end ) }"

    load_balancer_arn = "${ aws_alb.alb.arn }"
    port              = "${ element( var.protocols[ var.in_front_end[ count.index ] ], 1 ) }"
    protocol          = "${ element( var.protocols[ var.in_front_end[ count.index ] ], 0 ) }"

    default_action
    {
        target_group_arn = "${ element( aws_alb_target_group.alb_targets.*.arn, count.index ) }"
        type = "forward"
    }
}


/*
 | --
 | -- Target groups are the back-end of our load balancer which is designed
 | -- to separate interface from implementation.
 | --
 | -- Setting "rabbitmq" at the back-end and "web" at the front end means
 | -- that clients can call http://rabbitmq.example.com/api and it will be
 | -- translated to http://rabbitmq.example.com:15672/api
 | --
 | -- The interface (for this example) is on port 80 and is separated from
 | -- the implementation on port 15672.
 | --
*/
resource aws_alb_target_group alb_targets
{
    count       = "${ length( var.in_back_end ) }"
    name        = "${ substr( var.in_lb_class, 0, 3 ) }-${ var.in_ecosystem_name }-${ var.in_tag_timestamp }"
    protocol    = "${ element( var.protocols[ var.in_back_end[ count.index ] ], 0 ) }"
    port        = "${ element( var.protocols[ var.in_back_end[ count.index ] ], 1 ) }"
    vpc_id      = "${ var.in_vpc_id }"
    target_type = "ip"

    tags
    {
        Name   = "target-group-${ var.in_ecosystem_name }-${ var.in_tag_timestamp }-${ count.index }"
        Class = "${ var.in_ecosystem_name }"
        Instance = "${ var.in_ecosystem_name }-${ var.in_tag_timestamp }"
        Desc   = "This ${ var.in_lb_class } load balancer backend targeting ${ element( var.protocols[ var.in_back_end[ count.index ] ], 2 ) } traffic for ${ var.in_ecosystem_name } ${ var.in_tag_description }"
    }

}


/*
 | --
 | -- This resource relates to an EC2 instance or even a service
 | -- within an instance so if you had a cluster of 10 rabbitmq
 | -- ec2 instances there would be 10 target group attachments.
 | --
 | -- Terraform has a terrible bug which throws an error whenever
 | -- a count value is not known at (let's say) compile time.
 | --
 | -- Error. Count cannot be computed
 | --
 | -- This means that we cannot use the sensible length function on
 | -- a list of private IP addresses to determine the count.
 | --
 | --     count = "${ length( var.in_ip_addresses ) }"
 | --
 | -- We have to break normal form with an unnecessary variable.
 | --
*/
resource aws_lb_target_group_attachment connect
{
    count            = "${ var.in_ip_address_count }"

    target_group_arn = "${ element( aws_alb_target_group.alb_targets.*.arn, 0 ) }"
    target_id        = "${ element( var.in_ip_addresses, count.index ) }"
    port             = "${ element( var.protocols[ var.in_back_end[ 0 ] ], 1 ) }"
}


/*
resource aws_alb_target_group alb_targets
{
    count             = "1"
    name     = "tg-${ var.in_ecosystem_name }"
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
        Name   = "alb-tg-${ var.in_ecosystem_name }-${ var.in_tag_timestamp }"
        Class = "${ var.in_ecosystem_name }"
        Instance = "${ var.in_ecosystem_name }-${ var.in_tag_timestamp }"
        Desc   = "This alb target group for ${ var.in_ecosystem_name } ${ var.in_tag_description }"
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
