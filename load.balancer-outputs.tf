
################ ################################################# ########
################ Module [[[load balancer]]] Output Variables List. ########
################ ################################################# ########

output out_dns_name         { value = "${ aws_alb.alb.dns_name }" }
output out_load_balancer_id { value = "${ aws_alb.alb.id       }" }
