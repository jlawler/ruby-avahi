#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__),'../lib')
require 'pp'
require 'avahi'
def dba 
  @avahi_dba||= Avahi::AvahiManager.new
end

def dbat
  @avahi_dbat||=begin
    _t = dba
    _t.avahi_loop
    _t
  end
end
dba.publish(Avahi::IF_UNSPEC, Avahi::PROTO_UNSPEC, 'blahblaah','_hattp._tcp',35,[])
sleep(5)

