open Lwt.Infix

module Main (T : Mirage_time_lwt.S) (M : Mirage_clock.MCLOCK) (P : Mirage_clock.PCLOCK) (S : Mirage_stack_lwt.V4) (KEYS : Mirage_kv_lwt.RO) = struct
  module TCP = S.TCPV4
  module X = Tls_mirage.X509(KEYS)(P)
  module M = Monitoring_experiments.M.S(T)(P)(M)(S)

  let http_header ~status xs =
    let headers = List.map (fun (k, v) -> k ^ ": " ^ v) xs in
    let lines = status :: headers @ [ "\r\n" ] in
    Cstruct.of_string (String.concat "\r\n" lines)

  let header len = http_header
      ~status:"HTTP/1.1 200 OK"
      [ ("Content-Type", "text/html; charset=UTF-8") ;
        ("Content-length", string_of_int len) ;
        ("Connection", "close") ]

  let serve data tcp =
    let ip, port = TCP.dst tcp in
    Logs_lwt.info (fun m -> m "%s:%d served" (Ipaddr.V4.to_string ip) port) >>= fun () ->
    TCP.writev tcp data >>= fun _ ->
    TCP.close tcp

  let start _ _ _ stack keys _ _ info =
    Logs.info (fun m -> m "used packages: %a"
                  Fmt.(Dump.list @@ pair ~sep:(unit ".") string string)
                  info.Mirage_info.packages) ;
    Logs.info (fun m -> m "used libraries: %a"
                  Fmt.(Dump.list string) info.Mirage_info.libraries) ;
    X.certificate keys (`Name "monitor") >>= fun (certs, key) ->
    let c = `Single (certs, key) in
    M.create_tls stack ~hostname:"nqsb.retreat" c;

    let data =
      let content_size = Cstruct.len Page.rendered in
      [ header content_size ; Page.rendered ]
    in
    S.listen_tcpv4 stack ~port:80 (serve data) ;
    S.listen stack
end
