require 'rubygems'
require 'dbus'
require 'avahi_constants'

module Avahi

  class AvahiManager  
    
    attr_reader :services #we'll but all the services we discover in here
  
    def initialize
      @bus = DBus::SystemBus.instance
      @avahi = @bus.service('org.freedesktop.Avahi')
      @server = @avahi.object('/')
      @server.introspect
      @server.default_iface = 'org.freedesktop.Avahi.Server'
      @domain = @server.GetDomainName()[0]
      @hostname = @server.GetHostName()[0]
      @hostname_fqdn = @server.GetHostNameFqdn()[0]
      interface,@protocol,name,aprotocol,@address,flags = @server.ResolveHostName(IF_UNSPEC,IF_UNSPEC,@hostname_fqdn,IF_UNSPEC,0)
      entry_path = @server.EntryGroupNew()[0]
      @entry = @avahi.object(entry_path)
      @entry.introspect
      @entry.default_iface = 'org.freedesktop.Avahi.EntryGroup'
      #we'll put services in here
      @services = {}
      #add the default service listeners
      add_service_listeners
      #go into loop (non-blocking)
      #avahi_loop
    end

    #add service listeners
    def add_service_listeners
      #rofl_enable_trace
      service_types = get_service_types
      #will subscribe to all known services
      service_types.each do |description,service| 
        puts "Now listening on #{description}!"
        browser_path = @server.ServiceBrowserNew(IF_UNSPEC,PROTO_UNSPEC,"_#{service}._tcp",@domain,0).first
        #now we start the match rule definition
        mr = DBus::MatchRule.new
        mr.type = "signal"
        mr.interface = "org.freedesktop.Avahi.ServiceBrowser"
        mr.path = browser_path
        @bus.add_match(mr) { |msg| service_callback description,msg }
      end
    end
    
    #service callback
    def service_callback description,msg
      add_service description,msg if msg.member.eql? "ItemNew"
      remove_service description,msg if msg.member.eql? "ItemRemoved"
    end
    
    #adds a service to the list of running services
    def add_service description,msg
      s = {:description => description ,:status => "running",:discovered => Time.now}
      p = msg.params
      #params look like this: 0 interface,1 protocol,2 name,3 type,4 domain
      s[:iface],s[:protocol],s[:name],s[:type],s[:domain] = p[0],p[1],p[2],p[3],p[4]
      #setup
      @services[s[:type]] = [] unless @services.has_key? s[:type]
      #and add
      @services[s[:type]] << s
      #RESOLVE - TODO: still blocks, don't know why, guess i broke ruby-dbus again :)
      #0 interface,1 protocol,2 name,3 type,4 domain,5 host,6 aprotocol,7 address,8 port,9 text,10 flags
      #res = resolve(p[0],p[2],p[3],p[4])
      #puts "host: #{res[5]} port: #{res[8]} addr: #{res[7]}"
    end
    
    #removes a service from the list of running services
    def remove_service description,msg
      puts "REMOVING: #{description}: #{msg.params[2]}"
    end
    
    #resolve a service   
    def resolve(interface, name, type, domain)
      #interface, protocol, name, type, domain, host, aprotocol, address, port, text, flags
      @server.ResolveService(interface, Avahi::PROTO_UNSPEC, name, type, domain, Avahi::PROTO_UNSPEC, 0)
    end
    
    #publish a service  
    def publish(interface, protocol, name, type, port, text, domain = @domain, hostname_fqdn = @hostname_fqdn)
      @entry.AddService(interface, protocol, 0, name, type, domain, hostname_fqdn, port, text)
      @entry.Commit()
    end

    #set the host name
    def set_host_name(name)
      @server.SetHostName(name)
      @hostname = @server.GetHostName(name)
    end
    
    #don't get nasty
    def avahi_loop
      Thread.new do
        main = DBus::Main.new
        main << @bus
        main.run
      end
    end
  end
end

include Avahi
dba = AvahiManager.new

#loop we're getting caught in
loop do
  sleep 1
end
