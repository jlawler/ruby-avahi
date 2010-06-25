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
dbat.service_list.add_callback({:cb_type => :new_service, :service_type => '_hattp._tcp', :iface => :uniq}){|s|STDERR.puts "FOUND NEW HAATP SERVICE! #{s.inspect}"}
begin
dbat.avahi_loop_thread.join
rescue  Exception => e
pp dbat.service_list.to_hsh['_hattp._tcp']
STDERR.puts "\n\n"
raise
end
