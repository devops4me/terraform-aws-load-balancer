
################ ################################################# ########
################ Module [[[load balancers]]] Input Variables List. ########
################ ################################################# ########

# = ===
# = The collections map of common configuration for load balancer
# = front end listeners and back-end targets.
# = ===
variable commons
{
    description = "Common load balancer front end listener and backend target configurations."
    type = "map"

    default
    {

	# < ~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~ >
	# < ~~~ protocol, port and health check location ~~~ >
	# < ~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~ >
        web  = [ "HTTP",   80,   "/"      ]
        ssl  = [ "HTTPS",  443,  "/"      ]
        etcd = [ "HTTP",  2379, "/health" ]

    }

}

### ######################### ###
### [[variable]] in_listeners ###
### ######################### ###

variable in_listeners
{
    description = "The front end listener configuration for this load balancer."
    type        = "list"
    default     = [ "web" ]
}


### ####################### ###
### [[variable]] in_targets ###
### ####################### ###

variable in_targets
{
    description = "The back end target configuration for this load balancer."
    type        = "list"
    default     = [ "web" ]
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
