open Mirage

let net = generic_stackv4 default_network

let logger = syslog_udp ~config:(syslog_config "retreat") net

let packages = [
  package ~sublibs:["lwt"] "logs" ;
  package "omd" ;
  package "tyxml" ;
  package ~min:"3.7.1" "tcpip" ;
  package ~min:"0.2.1" "logs-syslog" ;
  package "monitoring-experiments"
]

let () =
  register "retreat" [
    foreign
      ~deps:[ abstract nocrypto ; abstract logger ; abstract app_info ]
      ~packages
      "Unikernel.Main"
      ( time @-> mclock @-> pclock @-> stackv4 @-> kv_ro @-> job )
    $ default_time
    $ default_monotonic_clock
    $ default_posix_clock
    $ net
    $ crunch "tls"
  ]
