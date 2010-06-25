#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__),'../lib')
require 'pp'
require 'avahi'
def avahi 
  @avahi_dba||= Avahi::AvahiManager.new
end

def avahid 
  @avahi_dbat||=begin
    _t = avahi 
    _t.avahi_loop
    _t
  end
end
avahi.publish(Avahi::Constants::IF_UNSPEC, Avahi::Constants::PROTO_UNSPEC, 'blahblaah','_http._tcp',35,[])
sleep(5)

