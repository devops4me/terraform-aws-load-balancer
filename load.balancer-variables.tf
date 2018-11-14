
################ ################################################# ########
################ Module [[[load balancers]]] Input Variables List. ########
################ ################################################# ########

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
