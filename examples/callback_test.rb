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
avahid.service_list.add_callback({:cb_type => :new_service, :service_type => '_http._tcp', :iface => :uniq}){|s|STDERR.puts "FOUND NEW HTTP SERVICE! #{s.inspect}"}
begin
avahid.avahi_loop_thread.join
rescue  Exception => e
pp avahid.service_list.to_hsh['_http._tcp']
STDERR.puts "\n\n"
raise
end
