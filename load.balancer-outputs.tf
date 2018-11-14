
################ ################################################# ########
################ Module [[[load balancer]]] Output Variables List. ########
################ ################################################# ########

### ########################## ###
### [[output]] out_dns_name_id ###
### ########################## ###

output out_dns_name
{
    description = "The dns name of the load balancer that should be accessible usually via http and https."
    value       = "${ aws_alb.alb.dns_name }"
}
