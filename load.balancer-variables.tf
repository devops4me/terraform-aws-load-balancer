
################ ################################################# ########
################ Module [[[load balancers]]] Input Variables List. ########
################ ################################################# ########

# = ===
# = The collections map of common configuration for load balancer
# = front end listeners and back-end targets.
# = ===

/*
 | --
 | -- On the front end a load balancer listens to http and/or https traffic
 | -- whilst on the back-end, its tentacles latch onto target groups.
 | --
 | -- We vertically read the front-end and back-end configuration.
 | --
 | --    in_front_end         = [ "web",    "etcd", "ssl"    ]
 | --    in_back_end          = [ "rabbit", "etcd", "rmqssl" ]
 | --
 | -- In this example (reading column-wise)
 | --
 | --   1> listen to http (port 80) traffic and send to rabbitmq (port 15672)
 | --   2> listen to etcd (port 2379) traffic and send to etcd (port 2379)
 | --   3> listen to HTTPS (port 443) traffic and send to rabbit (ssl) on 15671
 | --
*/

variable commons
{
    description = "Common load balancer front end listener and backend target configurations."
    type = "map"

    default
    {

	# < ~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~ >
	# < ~~~ protocol, port, health url and description ~~~ >
	# < ~~~ ------------------------------------------ ~~~ >

        web    = [ "HTTP",     80, "/",       "http port 80"        ]
        ssl    = [ "HTTPS",   443, "/",       "ssl (tls) port 443"  ]
        etcd   = [ "HTTP",   2379, "/health", "etcd port 2379"      ]
        rabbit = [ "HTTP",  15672, "/#",      "rabbitmq port 15672" ]
        rmqssl = [ "HTTPS", 15671, "/#",      "rmq ssl port 15671"  ]

        amqp   = [ "TCP",   5672,  "/",       "amqp port 5672"      ]

    }

}


### ######################## ###
### [[variable]] in_lb_class ###
### ######################## ###

variable in_lb_class
{
    description = "Either application for a layer 7 load balancer or network for a layer 4 load balancer."
    default     = "application"
}


### ######################### ###
### [[variable]] in_front_end ###
### ######################### ###

variable in_front_end
{
    description = "The front end listener configuration for this load balancer."
    type        = "list"
    default     = [ "web" ]
}


### ######################## ###
### [[variable]] in_back_end ###
### ######################## ###

variable in_back_end
{
    description = "The back end target configuration for this load balancer."
    type        = "list"
    default     = [ "web" ]
}


### ########################### ###
### [[variable]] in_is_internal ###
### ########################### ###

variable in_is_internal
{
    description = "If true the load balancer can be accessed externally and has a public IP address."
    default     = true
}


### ###################### ###
### [[variable]] in_vpc_id ###
### ###################### ###

variable in_vpc_id {}


### ################################# ###
### [[variable]] in_security_group_id ###
### ################################# ###

variable "in_security_group_id"
{
    description = "ID of security group that constrains the flow of load balancer traffic."
}


### ########################## ###
### [[variable]] in_subnet_ids ###
### ########################## ###

variable "in_subnet_ids"
{
    description = "IDs of subnets the network interfaces are attached to."
    type = "list"
}


### ############################ ###
### [[variable]] in_ip_addresses ###
### ############################ ###

variable in_ip_addresses
{
    description = "The list of IP addresses (public or private) that the load balancer will round robin spray."
    type    = "list"
}


### ################################ ###
### [[variable]] in_ip_address_count ###
### ################################ ###

variable in_ip_address_count
{
    description = "Due to a Terraform quirk the count value must be known beforehand (at compile time so to speak)."
}


### ######################### ###
### [[variable]] in_ecosystem ###
### ######################### ###

variable in_ecosystem
{
    description = "The name of the class of ecosystem being built like kubernetes-cluster or rabbit-mq"
    default     = "eco-system"
}
