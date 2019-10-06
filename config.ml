open Mirage

let net = generic_stackv4 default_network

let logger = syslog_udp ~config:(syslog_config "retreat") net

let packages = [
  package ~sublibs:["lwt"] "logs" ;
  package "omd" ;
  package "tyxml" ;
  package ~min:"3.7.1" "tcpip" ;
  package ~min:"0.2.1" "logs-syslog" ;
]

let () =
  register "retreat" [
    foreign
      ~deps:[ abstract logger ; abstract app_info ]
      ~packages
      "Unikernel.Main"
      ( stackv4 @-> job )
    $ net
  ]
