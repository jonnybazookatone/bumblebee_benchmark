# This is a basic VCL configuration file for varnish.  See the vcl(7)
# man page for details on VCL syntax and semantics.
# 
# Default backend definition.  Set this to point to your content
# server.
# 
backend default {
    .host = "127.0.0.1";
    .port = "8000";
}

backend adsapi {
     .host = "107.21.42.88";
     #.host = "api.adslabs.org";
     .port = "80";
}

# 
# Below is a commented-out copy of the default VCL logic.  If you
# redefine any of these subroutines, the built-in logic will be
# appended to your code.
sub vcl_recv {
      # Regex: contains this text
      if (req.url ~ "/v1/search" || req.url ~ "/v1/bumblebee/bootstrap") {
        set req.backend = adsapi;
      } else {
        set req.backend = default;
        return (pass); # this will skip any caching
      }
#     if (req.restarts == 0) {
# 	if (req.http.x-forwarded-for) {
# 	    set req.http.X-Forwarded-For =
# 		req.http.X-Forwarded-For + ", " + client.ip;
# 	} else {
# 	    set req.http.X-Forwarded-For = client.ip;
# 	}
#     }
     if (req.request != "GET" &&
       req.request != "HEAD" &&
       req.request != "PUT" &&
       req.request != "POST" &&
       req.request != "TRACE" &&
       req.request != "OPTIONS" &&
       req.request != "DELETE") {
         /* Non-RFC2616 or CONNECT which is weird. */
         return (pipe);
     }
     #if (req.request != "GET" && req.request != "HEAD") {
     #    /* We only deal with GET and HEAD by default */
     #    return (pass);
     #}

     # Else strip all cookies
     if (req.url ~ "/v1/") {
       unset req.http.cookie;


     }

#     if (req.http.Authorization || req.http.Cookie) {
#         /* Not cacheable by default */
#         return (pass);
#     }

     return (lookup);
}

#sub vcl_backend_response {
#    if (req.url ~ "/v1/") {
#        unset beresp.http.set-cookie;
#    }
#}

# 
# sub vcl_pipe {
#     # Note that only the first request to the backend will have
#     # X-Forwarded-For set.  If you use X-Forwarded-For and want to
#     # have it set for all requests, make sure to have:
#     # set bereq.http.connection = "close";
#     # here.  It is not set by default as it might break some broken web
#     # applications, like IIS with NTLM authentication.
#     return (pipe);
# }
# 
# sub vcl_pass {
#     return (pass);
# }
# 
 sub vcl_hash {

     # Hash on URL
     hash_data(regsub(req.url, "\d*$", ""));

     # Hash includes ip - do I care? Not for now.
     #if (req.http.host) {
     #    hash_data(req.http.host);
     #} else {
     #    hash_data(server.ip);
     #}

     # Differentiate based on login cookie too
     if (req.http.cookie && req.backend == adsapi) {
         hash_data(req.http.cookie);
         set req.http.X-Hash-Cookie = "YES";
     } else {
         set req.http.X-Hash-Cookie = "NO";
     }

     return (hash);
 }
# 
 sub vcl_hit {
     return (deliver);
 }
# 
 sub vcl_miss {
     return (fetch);
 }
# 
 sub vcl_fetch {

   #/* Set the clients TTL on this object */
   #set beresp.http.cache-control = "max-age=10";

   /* Set varnish TTL on this object */
   set beresp.ttl = 200s;

   /* Headers with info */
   set beresp.http.X-Cacheable = "YES ";
   set beresp.http.X-Ttl = beresp.ttl;

#     if (beresp.ttl <= 0s ||
#         beresp.http.Set-Cookie ||
#         beresp.http.Vary == "*") {
# 		/*
# 		 * Mark as "Hit-For-Pass" for the next 2 minutes
# 		 */
# 		set beresp.ttl = 120 s;
# 		return (hit_for_pass);
#     }
     return (deliver);
 }
# 
 sub vcl_deliver {
     /* Set debugging header values */
     set resp.http.X-Cache-Hits = obj.hits;
     set resp.http.X-Backend = req.backend;
     set resp.http.X-Hash-Cookie = req.http.X-Hash-Cookie;

     return (deliver);
 }
# 
# sub vcl_error {
#     set obj.http.Content-Type = "text/html; charset=utf-8";
#     set obj.http.Retry-After = "5";
#     synthetic {"
# <?xml version="1.0" encoding="utf-8"?>
# <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
#  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
# <html>
#   <head>
#     <title>"} + obj.status + " " + obj.response + {"</title>
#   </head>
#   <body>
#     <h1>Error "} + obj.status + " " + obj.response + {"</h1>
#     <p>"} + obj.response + {"</p>
#     <h3>Guru Meditation:</h3>
#     <p>XID: "} + req.xid + {"</p>
#     <hr>
#     <p>Varnish cache server</p>
#   </body>
# </html>
# "};
#     return (deliver);
# }
# 
# sub vcl_init {
# 	return (ok);
# }
# 
# sub vcl_fini {
# 	return (ok);
# }
