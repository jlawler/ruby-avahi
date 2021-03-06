module Avahi
  module Constants
    ####
    ## address.h
    ##
    PROTO_INET      =  0
    PROTO_INET6     =  1
    PROTO_UNSPEC    = -1
  
    IF_UNSPEC       = -1
  
    ####
    ## defs.h
    ##
    # AvahiPublishFlags
    PUBLISH_UNIQUE = 1
    PUBLISH_NO_PROBE = 2
    PUBLISH_NO_ANNOUNCE = 4
    PUBLISH_ALLOW_MULTIPLE = 8
    PUBLISH_NO_REVERSE = 16
    PUBLISH_NO_COOKIE = 32
    PUBLISH_UPDATE = 64
    PUBLISH_USE_WIDE_AREA = 128
    PUBLISH_USE_MULTICAST = 256
  
    # AvahiLookupFlags
    LOOKUP_USE_WIDE_AREA = 1
    LOOKUP_USE_MULTICAST = 2
    LOOKUP_NO_TXT = 4
    LOOKUP_NO_ADDRESS = 8
  
    # AvahiLookupResultFlags
    LOOKUP_RESULT_CACHED = 1
    LOOKUP_RESULT_WIDE_AREA = 2
    LOOKUP_RESULT_MULTICAST = 4
    LOOKUP_RESULT_LOCAL = 8
    LOOKUP_RESULT_OUR_OWN = 16
    LOOKUP_RESULT_STATIC = 32
  
    DNS_TYPE_A = 0x01
    DNS_TYPE_NS = 0x02
    DNS_TYPE_CNAME = 0x05
    DNS_TYPE_SOA = 0x06
    DNS_TYPE_PTR = 0x0C
    DNS_TYPE_HINFO = 0x0D
    DNS_TYPE_MX = 0x0F
    DNS_TYPE_TXT = 0x10
    DNS_TYPE_AAAA = 0x1C
    DNS_TYPE_SRV = 0x2
  
    DNS_CLASS_IN = 0x01
  end
end
