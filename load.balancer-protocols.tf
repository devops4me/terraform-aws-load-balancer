
/*
 | --
 | -- Its easy to reuse this load balancer module with these protocols.
 | --   ps (send a pull request if your desired protocol is not here).
 | --
 | -- The first section is for the application (layer 7) load balancer 
 | -- which only handles HTTP/HTTPS traffic that almost always originates
 | -- from human beings. The second section configures machine traffic
 | -- handled by the (layer 4) network load balancer.
 | --
 | --
 | -- Example - Human traffic from port 80 to RabbitMQ UI port 15672
 | --           (application load balancer)
 | --
 | --    in_front_end = [ "http"    ]
 | --    in_back_end  = [ "rabbit" ]
 | --
 | --
 | -- Example - Machine AMQP (tcp) traffic from/to port 5672
 | --           (network load balancer)
 | --
 | --    in_front_end = [ "http"    ]
 | --    in_back_end  = [ "rabbit" ]
 | --
*/

variable protocols
{
    description = "Load balancer protocols for front and back end traffic."
    type = "map"

    default
    {

	# < ~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~ >
	# < ~~~ human (http/https) application load balancer interface ~~~ >
	# < ~~~ ------------------------------------------------------ ~~~ >

        http     = [ "HTTP" ,     80,  "http port 80"        ]
        https    = [ "HTTPS",    443,  "ssl on port 443"     ]
        etcd     = [ "HTTP" ,   2379,  "etcd port 2379"      ]
        rabbitmq = [ "HTTP" ,  15672,  "rabbitmq port 15672" ]
        rmq-ssl  = [ "HTTPS",  15671,  "rmq ssl port 15671"  ]

	# < ~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~ >
	# < ~~~ machine (tcp) network load balancer interface ~~~ >
	# < ~~~ --------------------------------------------- ~~~ >

        amqp     = [ "TCP"  ,  5672 ,  "amqp port 5672"      ]
        ssh      = [ "TCP"  ,  22   ,  "ssh port 22"         ]

    }

}
