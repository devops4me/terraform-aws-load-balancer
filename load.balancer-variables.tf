
################ ################################################# ########
################ Module [[[load balancers]]] Input Variables List. ########
################ ################################################# ########

### ###################### ###
### [[variable]] in_vpc_id ###
### ###################### ###

variable in_vpc_id {}


### ########################### ###
### [[variable]] in_s_group_ids ###
### ########################### ###

variable "in_s_group_ids"
{
    description = "ID of security group that constrains the flow of load balancer traffic."
    type        = "list"
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
    description = "Here nips is a list of network interface ip addresses."
    type    = "list"
}


### ################################ ###
### [[variable]] in_ip_address_count ###
### ################################ ###

variable in_ip_address_count
{
    description = "This load balancer module needs to know beforehand (due to a Terraform quirk) the number of IP addresses to that will be sent."
}


### ######################### ###
### [[variable]] in_ecosystem ###
### ######################### ###

variable in_ecosystem
{
    description = "The name of the class of ecosystem being built like kubernetes-cluster or rabbit-mq"
    default     = "eco-system"
}
