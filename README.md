
# Application Load Balancer Module

The **application load balancer** module lives to create five (5) types of infrastructure object that in union, can load balance traffic over either **network interfaces**, **ec2 instances**  or **autoscaling groups**. The five objects are

- the **target group** (bucket for forwarding attachments)
- zero or more **tg attachments** to whom traffic is forwarded
- the **application load balancer** bucket itself
- zero or more **listener buckets** in the load balancer bucket
- zero or more **rules** to go in each listener bucket

## Inpus for the Application Load Balancer

In order to create a load balancer you need security groups, subnets and you must specify whether it can be accessible on the internet, rather than just internally.

For internet accessible load balancers you must ensure that the VPC (parent of the subnets) **has an internet gateway** and **a route** to some kind of destination (the most open being 0.0.0.0/0).

## Inpus for Load Balancer Target Group

Currently the target group is hardcoded to HTTPS at port 443.

The health check is hardcoded

- to use **port 443**
- with the **root slash (/) path**
- so that **under 3 seconds** is a **healthy** threshold (green) and **more than 10 seconds** is **unhealthy** (red). In between is amber.
- to **time out** after 5 minutes
- to **check periodically** every 10 seconds
- to use **importantly** the **ip** type

There are two possible values for target type

- **instance** - targets will be specified by **ec2 instance ID** (the default)
- **ip** - targets will be specified by **private IP address** (in IPV4)

**Note that you can't specify targets for a target group using both instance IDs and IP addresses. If the target type is ip, specify IP addresses from the subnets of the virtual private cloud (VPC) for the target group, the RFC 1918 range (10.0.0.0/8, 172.16.0.0/12, and 192.168.0.0/16), and the RFC 6598 range (100.64.0.0/10). Remember that you cannot specify publicly routable IP addresses.**

## Inpus for Network Interface (IP Address) Target Group Attachments

When AWS creates **instance (node) clusters** for the likes of Redis, Postgres, Kubernetes and ElasticSearch, it places ENIs (elastic network interfaces) that expose private IP addresses that load balancers can hook onto.

This method enables SSL termination (using Certificate Manager SSL certificates) whilst connecting to clusters through a load balancer.

The relevant network interfaces are queried for and when returned, we loop over them creating target group attachments that bind the target group to their private intra VPC IP addresses.

The port to use for each attachment is currently hardcoded to 443.

Splat syntax is used to retrieve the list of IP addresses, which are hen passed over for one to one creation of target group attachments.

## Inpus for Load Balancer Listeners

A load balancer listener **keeps an ear out** for incoming traffic **conforming to the specified protocol** and **arriving at the said port**.

AWS impose a limit of 50 listeners per load balancer.

Listeners **mostly forward traffic** on but they can also

- **terminate ssl**
- **reject traffic**
- **redirect traffic** based on path
- **redirect traffic** from http (port 80) to https (port 443)
- route traffic based on **path and/or host**
- **give a fixed response** (like for a heaalth check)

For a listener to terminate SSL, you must provide the ARN of the SSL certificate which is usually kept in certificate manager. However you can also import externally sourced SSLs certificate directly into the load balancer.


## Inpus for Load Balancer Listener Rules

The application load balancer can have many rules meaning we can route traffic to different places based on

- the **request path (url** text after first sole forward slash)
- the **host** that the request came from (info in http headers)


## Load Balancer Access Logs | 5 minutes | 60 minutes | none

We could write load balancer access logs to an S3 bucket every 5 minutes, 60 minutes or indeed never.

### Calculate Access Logs File Size

If the load balancer receives 5,000 requests per seconds how many file lines would result?

        5,000 x 60 x 60
        5,000 x 3,600
        5,000 x 3,600
        3,600,000 x 5
        18,000,000
        18 million lines

Now approximate the byte size of each line and then multiply out to determine roughly how big the file would be if produced

- every **5 minutes**
- every **hour**


<!--
############## Notes from similar decomm'd folder.
############## Notes from similar decomm'd folder.
############## Notes from similar decomm'd folder.
############## Notes from similar decomm'd folder.
############## Notes from similar decomm'd folder.
############## Notes from similar decomm'd folder.
############## Notes from similar decomm'd folder.
############## Notes from similar decomm'd folder.
############## Notes from similar decomm'd folder.
############## Notes from similar decomm'd folder.
############## Notes from similar decomm'd folder.
############## Notes from similar decomm'd folder.
-->


# Traffic (Load Balancer) Module Usage

Give me a **list of subnets and security groups** and I will give you a **single load balancer url** which can be fed into the Route53 Blue/Green DNS switching module.

A level 7 load balancer is created which is happy to terminate SSL and to perform path and host based routing should the need arise.

This load balancer implements the reverse proxy pattern by acting as an SSL certificate presentation agent useful for situations when the backend service either can not or will not perform this function.

As such the **ssl certificate id** living inside AWS's certificate manager and the secure url to proxy to are the kingpin parameters of note.

    module loadbalancer_module
    {
        source          = "loadbalancer"
        in_security_group_ids   = [ "${module.security_groups_module.out_default_security_group_ids}" ]
        in_subnet_ids   = "${module.subnets_module.out_subnet_ids}"
        in_environment  = "${var.production}"
    }

The security group must be configured to permit the type of traffic the load balancer is routing. This module produces a very specific load balancer that only deals in SSL and only requires port 443.

## Load Balancer Module Inputs

The load balancer needs to know

- what security groups it can attach itself to
- the subnets that it will post traffic to
- the ID of the **SSL certificate** in Certificate Manager
- the URL to which is will proxy traffic requests
- the S3 bucket (and path) to post the **access logs** to


## Load Balancer Module Output

The load balancer's url is the only noteoworthy output. This is typically consumed by the **blue/green (route53) domain name** switching module.





@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 


# Create VPC and Subnets in Availability Zones

This module's **default behaviour** is to create a VPC and then **create one private and one public subnet per availability zone** in the VPC's region. In Frankfurt 6 subnets would be created as there are 3 availability zones.

No need to specify **which** availability zones. You can request less, the same or more subnets than there are availability zones and this module dishes them out in a fair (round robin) manner.

## Usage

    module vpc_subnets
    {
        source                 = "github.com/devops4me/terraform-aws-vpc-subnets"
        in_vpc_cidr            = "10.245.0.0/16"
        in_num_private_subnets = 6
        in_num_public_subnets  = 3
        in_ecosystem           = "kubernetes-cluster"
    }

    output subnet_ids
    {
        value = "${ module.vpc_subnets.out_subnet_ids }"
    }

    output private_subnet_ids
    {
        value = "${ module.vpc_subnets.out_private_subnet_ids }"
    }

    output public_subnet_ids
    {
        value = "${ module.vpc_subnets.out_public_subnet_ids }"
    }


The most common usage is to specify the VPC Cidr, the number of public / private subnets and the class of ecosystem being built.

## [Examples and Tests](test-vpc.subnets)

**[This terraform module has runnable example integration tests](test-vpc.subnets)**. Read the instructions on how to clone the project and run the integration tests.


## Module Inputs

| Input Variable             | Type    | Description                                                   | Default        |
|:-------------------------- |:-------:|:------------------------------------------------------------- |:--------------:|
| **in_vpc_cidr**            | String  | The VPC's Cidr defining the range of available IP addresses   | 10.42.0.0/16   |
| **in_num_private_subnets** | Integer | Number of private subnets to create across availability zones | 3              |
| **in_num_public_subnets**  | Integer | Number of public subnets to create across availability zones  | 3              |
| **in_subnets_max**         | Integer | 2 to the power of this is the max number of carvable subnets  | 4 (16 subnets) |
| **in_ecosystem**           | String  | the class name of the ecosystem being built here              | eco-system     |

## subnets into availability zones | round robin

You can create **more or less subnets** than there are availability zones in the VPC's region. You can ask for **6 private subnets** in a **3 availability zone region**. The subnets are distributed into the availability zones like dealing a deck of cards.

Every permutation of subnets and availability zones is catered for so you can demand

- **less subnets** than availability zones (so some won't get any)
- a subnet count that is an **exact multiple** of the zone count (equality reigns)
- that **no subnets** (public and/or private) get created
- nothing - and each availability zone will get one public and one private subnet

---

## in_subnets_max | variable

This variable defines the maximum number of subnets that can be carved out of your VPC (you do not need to use them all). It then combines with the VPC Cidr to define the number of **addresses available in each subnet's** pool.

### 2<sup>32 - (in_vpc_cidr + in_subnets_max)</sup> = number of subnet addresses

A **vpc_cidr of 21 (eg 10.42.0.0/21)** and **subnets_max of 5** gives a pool of **2<sup>32-(21+5)</sup> = 64 addresses** in each subnet. (Note it is actually 2 less). We can carve out **2<sup>5</sup> = 32 subnets** as in_subnets_max is 5.

### Dividing VPC Addresses into Subnet Blocks

| vpc cidr  | subnets max | number of addresses per subnet                          | max subnets                 | vpc addresses total                  |
|:---------:|:-----------:|:------------------------------------------------------- |:--------------------------- |:------------------------------------ |
|  /16      |   6         | 2<sup>32-(16+6)</sup> = 2<sup>10</sup> = 1024 addresses | 2<sup>6</sup> = 64 subnets  | 2<sup>32-16</sup> = 65,536 addresses |
|  /16      |   4         | 2<sup>32-(16+4)</sup> = 2<sup>12</sup> = 4096 addresses | 2<sup>4</sup> = 16 subnets  | 2<sup>32-16</sup> = 65,536 addresses |
|  /20      |   8         | 2<sup>32-(20+8)</sup> = 2<sup>4</sup>  = 16 addresses   | 2<sup>8</sup> = 256 subnets | 2<sup>32-20</sup> = 4,096 addresses  |
|  /20      |   2         | 2<sup>32-(20+2)</sup> = 2<sup>10</sup> = 1024 addresses | 2<sup>2</sup> = 4 subnets   | 2<sup>32-20</sup> = 4,096 addresses  |

Check the below formula holds true for every row in the above table.

<pre><code>addresses per subnet * number of subnets = total available VPC addresses</code></pre>

---

## in_subnets_max | in_vpc_cidr

**How many addresses will each subnet contain** and **how many subnets can be carved out of the VPC's IP address pool**? These questions are answered by the vpc_cidr and the subnets_max variable.

The VPC Cidr default is 16 giving 65,536 total addresses and the subnets max default is 4 so **16 subnets** can be carved out with each subnet ready to issue 4,096 addresses.

Clearly the addresses per subnet multiplied by the number of subnets cannot exceed the available VPC address pool. To keep your powder dry, ensure **in_vpc_cidr plus in_subnets_max does not exceed 31**.

## number of subnets constraint

It is unlikely **in_num_private_subnets + in_num_public_subnets** will exceed the maximum number of subnets that can be carved out of the VPC. Usually it is a lot less but be prudent and ensure that **in_num_private_subnets + in_num_public_subnets < 2<sup>in_subnets_max</sup>**


## subnet cidr blocks | cidrsubnet function

You do not need to specify each subnet's CIDR block because they are calculated by passing the VPC Cidr (in_vpc_cidr), the Subnets Max (in_subnets_max) and the present subnet's index (count.index) into Terraform's **cidrsubnet function**.

The behaviour of Terraform's **cidrsubnet function** is involved but slightly outside the scope of this VPC/Subnet module document. Read **[Understanding the Terraform Cidr Subnet Function](http://www.devopswiki.co.uk/wiki/devops/terraform/terraform-cidrsubnet-function)** for a fuller coverage of cidrsubnet's behaviour.

---

## internet gateway and route

This module **senses** whether you wish to **create an internet gateway** (in) and a route (out) to the internet.

If **in_num_public_subnets is greater than zero** it automatically creates an internet gateway and a route along with the public subnets. This behaviour can be switched off by setting **in_ignore_public** to true.


## output variables

Here are the most popular **output variables** exported from this VPC and subnet creating module.

| Exported | Type | Example | Comment |
|:-------- |:---- |:------- |:------- |
**out_vpc_id** | String | vpc-1234567890 | the **VPC id** of the just-created VPC
**out_rtb_id** | String | "rtb-2468013579" | ID of the VPC's default route table
**out_subnet_ids** | List of Strings | [ "subnet-545123498798345", "subnet-83507325124987" ] | list of **all private and public** subnet ids
**out_private_subnet_ids** | List of Strings | [ "subnet-545123498798345", "subnet-83507325124987" ] | list of **private** subnet ids
**out_public_subnet_ids** | List of Strings |  [ "subnet-945873408204034", "subnet-8940202943031" ] | list of **public** subnet ids

## vpc subnets | module tests

**[This terraform module has runnable example integration tests](test-vpc.subnets)**. Read the instructions on how to clone the project and run the unit tests.

## vpc subnets | version | v0.1.0002

**v0.1.0002** is the current stable version of this Terraform module. To avoid say **testing with one version and going into production with another** you can employ the ref tag as shown below.

    module vpc_subnets
    {
        source                 = "github.com/devops4me/terraform-aws-vpc-subnets?ref=v0.1.0002"
        in_vpc_cidr            = "10.245.0.0/16"
        in_num_private_subnets = 6
        in_num_public_subnets  = 3
        in_ecosystem           = "kubernetes-cluster"
    }

Or you can use the version parameter that is more explicit and affords you the opportunity to detail a **[range of versions that are acceptable](https://www.terraform.io/docs/modules/usage.html)** by employing **version constraint syntax**.

    module vpc_subnets
    {
        source       = "github.com/devops4me/terraform-aws-vpc-subnets"
        version      =  "~> v0.1.0"
        in_vpc_cidr  = "10.123.0.0/16"
        in_ecosystem = "kubernetes-cluster"
    }


## Infrastructure Tests | Dockerfile

The quality and viability of this Terraform module is assured via a continuous integration process.

### See 4 Yourself | docker run

Why not see 4 yourself by building and running the test. You simply pass in **[[IAM user credentials]](https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/setup-credentials.html)** as **environment variables** to the docker container and Terraform will use these credentials to create the infrastructure.

```bash
git clone https://github.com/devops4me/terraform-aws-vpc-subnets
cd terraform-aws-vpc-subnets
docker build -t vpc.subnets.image .
```

### The AWS 5 VPC's Limit

The default VPC limit is just 5 and this test needs at least 10 so take yourself to the support section and request extension to say 25 - it will be done automatically in less than 5 minutes.

## Test Automation | Jenkinsfile


### Contributing

Bug reports and pull requests are welcome on GitHub at the https://github.com/devops4me/terraform-aws-vpc-subnets page. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

License
-------

MIT License
Copyright (c) 2006 - 2014

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
