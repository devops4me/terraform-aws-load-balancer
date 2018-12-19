
### ################################################### ###
### [[test-module]] testing terraform-aws-load-balancer ###
### ################################################### ###

locals
{
    ecosystem_id = "balancer-test"
}


# = ===
# = Test the modern state-of-the-art AWS application load balancer by creating
# = a number of ec2 instances configured with cloud config and set up to serve
# = web pages using either the HTTP or HTTPS protocols.
# =
# = The ec2 instances are placed in a subnets across each of the region's
# = availability zones and the security group is set to allow the appropriate
# = traffic to pass through.
# = ===
module load-balancer-test
{
    source                = ".."
    in_vpc_id             = "${ module.vpc-network.out_vpc_id }"
    in_subnet_ids         = "${ module.vpc-network.out_subnet_ids }"
    in_security_group_ids = [ "${ module.security-group.out_security_group_id }" ]
    in_ip_addresses       = "${ aws_instance.server.*.private_ip }"
    in_ip_address_count   = 3

    in_front_end          = [ "http" ]
    in_back_end           = [ "https" ]

    in_ecosystem_name     = "${local.ecosystem_id}"
    in_tag_timestamp      = "${ module.resource-tags.out_tag_timestamp }"
    in_tag_description    = "${ module.resource-tags.out_tag_description }"

}


# = ===
# = This module creates a VPC and then allocates subnets in a round robin manner
# = to each availability zone. For example if 8 subnets are required in a region
# = that has 3 availability zones - 2 zones will hold 3 subnets and the 3rd two.
# =
# = Whenever and wherever public subnets are specified, this module knows to create
# = an internet gateway and a route out to the net.
# = ===
module vpc-network
{
    source                 = "github.com/devops4me/terraform-aws-vpc-network"
    in_vpc_cidr            = "10.197.0.0/16"
    in_num_private_subnets = 0
    in_num_public_subnets  = 3

    in_ecosystem_name     = "${local.ecosystem_id}"
    in_tag_timestamp      = "${ module.resource-tags.out_tag_timestamp }"
    in_tag_description    = "${ module.resource-tags.out_tag_description }"
}


# = ===
# = The security group needs to allow ssh for troubleshooting logins
# = and http plus https to test the load balancers viability against
# = a fleet of web servers.
# = ===
module security-group
{
    source         = "github.com/devops4me/terraform-aws-security-group"
    in_ingress     = [ "ssh", "http", "https" ]
    in_vpc_id      = "${ module.vpc-network.out_vpc_id }"

    in_ecosystem_name     = "${local.ecosystem_id}"
    in_tag_timestamp      = "${ module.resource-tags.out_tag_timestamp }"
    in_tag_description    = "${ module.resource-tags.out_tag_description }"
}




output dns_name{ value             = "${ module.load-balancer-test.out_dns_name}" }
output public_ip_addresses{ value  = "${ aws_instance.server.*.public_ip }" }
output private_ip_addresses{ value = "${ aws_instance.server.*.private_ip }" }


## @todo - migrate the below to its own module
## @todo - migrate the below to its own module
## @todo - migrate the below to its own module
## @todo - migrate the below to its own module
## @todo - migrate the below to its own module


# = ===
# = Visit cloud-config.yaml and / or the cloud-init url to
# = understand the setup of the web servers.
# = ===
# = https://cloudinit.readthedocs.io/en/latest/index.html
# = ===
data template_file cloud_config
{
    template = "${file("${path.module}/cloud-config.yaml")}"
}


# = ===
# = Visit cloud-config.yaml and / or the cloud-init url to
# = understand the setup of the web servers.
# = ===
# = https://cloudinit.readthedocs.io/en/latest/index.html
# = ===
resource aws_instance server
{
    count = "3"

    ami                    = "${ data.aws_ami.ubuntu-1804.id }"
    instance_type          = "t2.micro"
    vpc_security_group_ids = [ "${ module.security-group.out_security_group_id }" ]
    subnet_id              = "${ element( module.vpc-network.out_subnet_ids, count.index ) }"
    user_data              = "${ data.template_file.cloud_config.rendered }"

    tags
    {
        Name   = "ec2-0${ ( count.index + 1 ) }-${ local.ecosystem_id }-${ module.resource-tags.out_tag_timestamp }"
        Class = "${ local.ecosystem_id }"
        Instance = "${ local.ecosystem_id }-${ module.resource-tags.out_tag_timestamp }"
        Desc   = "This ec2 instance no.${ ( count.index + 1 ) } for ${ local.ecosystem_id } ${ module.resource-tags.out_tag_description }"
    }

}


/*

 Write AWS AMI extractor terraform module which takes just two imputs

   1 - operating system name
   2 - operating system version

  and returns the AWS AMI ID.

 Set it up and test it for the below n operating systems going right back from 2010 to present day.
 (Also setup alerter schedule for when new versions are released - keep it up-to-date).

 The kickoff operating systems are

   01 - ubuntu server
   02 - windows server
   03 - Container Linux (CoreOS) - Legacy
   04 - Fedora CoreOS
   05 - RedHat CoreOS (for OpenShift platform)
   06 - RHEL (RedHat Enterprise Linux)
   06 - CentOS (RedHat)
   07 - OpenSUSE
   08 - Oracle Linux
   09 - Amazon Linux
   10 - Android
   11 - Mageia
   12 - Gentoo
   13 - Arch Linux
   14 - ClearOS
   15 - Slackware
   16 - Fedora
   17 - Debian
   18 - 
   19 - 
   20 - 
   2 - 


 Advertise the AMI, CloudFront distribution, AWS ElasticSearch, Terraform Jenkins2 Docker Pipeline and SafeDB

*/

data aws_ami ubuntu-1804
{
    most_recent = true

    filter
    {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
    }

    filter
    {
        name   = "virtualization-type"
        values = [ "hvm" ]
    }

    owners = ["099720109477"]
}


/*
 | --
 | -- Remember the AWS resource tags! Using this module, every
 | -- infrastructure component is tagged to tell you 5 things.
 | --
 | --   a) who (which IAM user) created the component
 | --   b) which eco-system instance is this component a part of
 | --   c) when (timestamp) was this component created
 | --   d) where (in which AWS region) was this component created
 | --   e) which eco-system class is this component a part of
 | --
*/
module resource-tags
{
    source = "github.com/devops4me/terraform-aws-resource-tags"
}
