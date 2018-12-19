
# Application Load Balancer Module

### Front End Listeners | Back End Targets

The AWS **application load balancer** module allows us to add one or more **front-end listeners** and one or more **back-end target groups** which can be ec2 instances, private IP addresses, auto-scaling groups or even other load balancers.

Traffic can be routed based on the **front-end** host **(aka host based routing)**, the request URI or the content. It can also be routed based on the **back-end load**, health or a strategy such as round robin delivery.

## Usage

    module load-balancer
    {
        source               = "github.com/devops4me/terraform-aws-load-balancer"
        in_vpc_id            = "${ module.vpc-network.out_vpc_id }"
        in_subnet_ids        = "${ module.vpc-network.out_public_subnet_ids }"
        in_security_group_id = "${ module.security-group.out_security_group_id }"
        in_ip_addresses      = "${ aws_instance.server.*.private_ip }"
        in_ip_address_count  = 3
        in_front_end         = [ "http"  ]
        in_back_end          = [ "etcd" ]
        in_ecosystem         = "${ local.ecosystem_id }"
    }

    output dns_name{ value = "${ module.load-balancer.out_dns_name}" }


## Module Inputs

| Input Variable | Type | Notes - Description |
|:-------------- |:----:|:------------------- |
| **in_vpc_id** | String | The ID of the VPC containing all the back-end targets, subnets and security groups to route to. |
| **in_security_group_id** | String | The security group must be configured to permit the type of traffic the load balancer is routing. A **504 Gateway Time-out** error from your browser means a missing **security group rule** is blocking the traffic. |
| **in_subnet_ids** | List | Use public subnets for an externally accessible front-end even when the back-end targets are in private subnets. Use private subnets for internal load balancers. The IDs of the subnets that traffic will be routed to. **Important - traffic will not be routed to two or more subnets in the same availability zone.** |
| **in_is_internal** | Boolean | If true the load balancer's DNS name is private - if false the DNS name will be externally addressable. |
| **in_ip_addresses** | List | List of **private or public IP addresses** that the **load balancer's back-end** will route traffic to. If **internal [ in_is_internal = true ]**, then only private IP addresses **inside private subnets*** can be specified. |
| **in_ssl_certificate_id** | String | The ID of the SSL certificate living in the ACM (Amazon Certificate Manager) repository. |
| **in_front_end** | List | List of front end listener configurations for this load balancer like web (for http port 80) and ssl (for https port 443).  |
| **in_back_end** | List | List of back end target configuration for this load balancer **like etcd (for http port 2379)**, web (for http port 80) and ssl (for https port 443). |
| **in_access_logs_bucket** | String | The **name of the S3 bucket** to which the load balancer will post access logs. |
| **in_ecosystem** | String | the class name of the ecosystem being built here. |

---

## Load Balancer Front End and Back End Configuration

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


---

## public or private subnets? which do I use?

**Always use *public subnets* for internet facing load balancers and private subnets for internal load balancers. **

### @todo Create table to document this (two columns and two rows).

### External load balancer | private subnets?

For external load balancers with services in private subnets you use the vpc network module to create **twin public and private subnets** in each availability zone (usually 6). Give the load balancer the public subnets (in the same order) and create services in the private subnets.

### Internal load balancer | private subnets?

### Disallowed

Internal load balancers are not allowed to sit in public subnets and external load balancers are not allowed to sit in private subnets (but the services can).

---


## Important Advice | Public or Private Subnets

Use **public subnet ids** even when the **back-end targets** are in **private subnets** if you want a **public facing load-balancer front-end**. From the browser the load-balancer will just hang if you have used private subnets because you can't connect to a service in private subnets from the outside world.

The **vpc-network** module will provide the correct infrastructure to ensure services in private subnets can connect, via a NAT gateway and routes, to the internet.

If you desire an internal load balancer then use private subnet IDs. Your load balancer will be available through a VPN or bastion host, and it will be **accessible to services in any VPCs for the same account** without the need for a peering connection.

### Subnets in the same availability zone

Load balancers will error saying that traffic will not be routed to two or more subnets in the same availability zone if that is what has been provided.


## 504 Gateway Time-out | Security Group

A **504 Gateway Time-out** error from your browser means that a **security group is blocking your application load-balancer** from initiating a connection using a given protocol on a given port.

Fix it by allowing **all-traffic** through then narrow the gap until you discover the missing security group rule.

---

## output variables

Here are the most popular **output variables** exported from this VPC and subnet creating module.

| Exported | Type | Example | Comment |
|:-------- |:---- |:------- |:------- |
**out_vpc_id** | String | vpc-1234567890 | the **VPC id** of the just-created VPC
**out_rtb_id** | String | "rtb-2468013579" | ID of the VPC's default route table
**out_subnet_ids** | List of Strings | [ "subnet-545123498798345", "subnet-83507325124987" ] | list of **all private and public** subnet ids
**out_private_subnet_ids** | List of Strings | [ "subnet-545123498798345", "subnet-83507325124987" ] | list of **private** subnet ids
**out_public_subnet_ids** | List of Strings |  [ "subnet-945873408204034", "subnet-8940202943031" ] | list of **public** subnet ids


---

## [Examples and Tests](integration.test.dir)

**[This terraform module has runnable example integration tests](integration.test.dir)**. Read the instructions on how to clone the project and run the integration tests.

---

## Inputs for the Application Load Balancer

In order to create a load balancer you need security groups, subnets and you must specify whether it can be accessible on the internet, rather than just internally.

For internet accessible load balancers you must ensure that the VPC (parent of the subnets) **has an internet gateway** and **a route** to some kind of destination (the most open being 0.0.0.0/0).

## Inputs for Load Balancer Target Group

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

## Inputs for Network Interface (IP Address) Target Group Attachments

When AWS creates **instance (node) clusters** for the likes of Redis, Postgres, Kubernetes and ElasticSearch, it places ENIs (elastic network interfaces) that expose private IP addresses that load balancers can hook onto.

This method enables SSL termination (using Certificate Manager SSL certificates) whilst connecting to clusters through a load balancer.

The relevant network interfaces are queried for and when returned, we loop over them creating target group attachments that bind the target group to their private intra VPC IP addresses.

The port to use for each attachment is currently hardcoded to 443.

Splat syntax is used to retrieve the list of IP addresses, which are hen passed over for one to one creation of target group attachments.

## Inputs for Load Balancer Listeners

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


## Inputs for Load Balancer Listener Rules

The application load balancer can have many rules meaning we can route traffic to different places based on

- the **request path (url** text after first sole forward slash)
- the **host** that the request came from (info in http headers)

---

## Architectural Advice | Load Balancers

## The Reverse Proxy Pattern | SSL Termination

This load balancer can implement the **reverse proxy pattern** by terminating SSL which is useful when backend services either cannot will not or should not work with SSL and/or manage SSL certificates within applications and containers.

As such the ID of the **ssl certificate** in AWS's certificate manager is typically provided to the load balancer's listener. These certificates are free and are automatically renewed which is highly attractive in contrast with the manual and costly nature of dealing with certificate authorities.


## Goodbye nginx

If you use nginx **only for SSL termination and/or reverse proxying** you should consider replacing it with an **application load balancer**. (Note that this also applies to the likes of Apache2 and WeBrick(Ruby).

A load balancer will perform better, is cheaper, simpler, more secure and inherently super scaleable. They scale to higher throughputs and loads without any performance degradation and they take the headaches of maintenance, upgrades, security and deployment off your shoulders.

AWS load balancers **can write access logs into an S3 bucket** further making the case to migrate away from traditional web servers.

That said, nginx is ideal for more complex workloads like url rewriting, email routing, caching and authentication.

## Serverless Infrastructure Pattern

The move to a **serverless infrastructure** is an undeniable upwards trend and **replacing traditional webservers with load balancers** achieves just that. Serverless comes into play when you use

- EKS (elastic kubernetes service)
- the managed AWS elasticsearch service
- RDS (MySQL and/or Postgres)  in the AWS cloud
- AWS Lambda
- cloud services like email (SES), DNS (Route53) and storage (S3)

Migrating towards load balancers and away from web servers is a step towards the serverless paradigm.

## Port Mapping

Load balancers can achieve port mapping between front-end listeners and back-end targets.

An example is the **[etcd3 cluster](https://github.com/devops4me/terraform-aws-etcd3-cluster/blob/master/etcd3.cluster-main.tf)** that maps the **back-end etcd port 2379** to the **front-end listener port 80**.

    module load-balancer
    {
        source               = "github.com/devops4me/terraform-aws-load-balancer"
        in_vpc_id            = "${ module.vpc-network.out_vpc_id }"
        in_subnet_ids        = "${ module.vpc-network.out_subnet_ids }"
        in_security_group_id = "${ module.security-group.out_security_group_id }"
        in_ip_addresses      = "${ aws_instance.node.*.private_ip }"
        in_front_end         = [ "web"  ]
        in_back_end          = [ "etcd" ]
        in_ecosystem         = "${ local.ecosystem_id }"
    }

The *in_front_end** defintion **web** is saying that the ubiquitous port 80 should be mapped to **etcd port 2379** as signaled by **in_back_end**.


## Goodbye VPC Peering

VPC peering allows services in the private subnets of different VPCs to talk to each other.

VPC peering encourages the hardcoding of one (or two) VPC IDs and a number of subnet IDs. It also adds complexity due to the routing and subnet associations that must be made.

**Consider using internal load balancers instead of VPC peering.** Services in private subnets of one VPC can talk to their peers in private subnets of another VPC through a load balancer without configuring VPC peering.

## Goodbye Bastion Hosts

Often proxying machines called bastion hosts are setup in a public subnet simply to allow connectivity to services in sister private subnets. IP tables and port forwarding are typically used to effect the connectivity.

Consider replacing bastion hosts with a load balancer. An externally accessible load balancer can route to services in private subnets thus negating the need for clumsy EC2 instances that risk becoming single points of failure in your architecture.


---

## Layer 7 Load Balancer vs Layer 4 Load Balancer

The AWS application load balancer is a (network) layer 7 load balancer which opens up incoming packets. Its ability to look into the request data means it can

- terminate HTTPS (SSL) traffic (when given a certificate)
- route traffic based on the request path and/or content
- route traffic based on the host including sticky sessions

A layer 4 **network load balancer** does not open up the message thus making it faster, but the trade-off is it does not have the capabilities of a layer 7 load balancer.

---


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


### Contributing

Bug reports and pull requests are welcome on GitHub at the https://github.com/devops4me/terraform-aws-vpc-network page. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

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
