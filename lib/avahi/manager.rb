module Avahi
  class AvahiManager 
    include Avahi::Constants
    attr_accessor :main,:server 

    def service_list 
      @service_list 
    end 
    def initialize
      @pass_counter=0
      @bus = DBus::SystemBus.instance
      @service_list||=Avahi::ServiceList.new
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
    end

    def add_listener stype
      browser_path = @server.ServiceBrowserNew(IF_UNSPEC,PROTO_UNSPEC,stype,@domain,0).first
      description='fake description'
      #now we start the match rule definition
      mr = DBus::MatchRule.new
      mr.type = "signal"
      mr.interface = "org.freedesktop.Avahi.ServiceBrowser"
      mr.path = browser_path
      count=0
      @bus.add_match(mr) { |msg| service_callback description,msg,stype,Time.now.to_i }
    end 
    #service callback
    def service_callback description,msg,stype,timestamp
      case msg.member
        when 'ItemNew' then @service_list.add(add_service_int(description,msg,timestamp))
        when "ItemRemove" then   @service_list.remove(msg)
        when 'AllForNow','CacheExhausted' then nil
        else STDERR.puts "UNKNOWN MSG #{msg.member}"
      end
    end
        
    #adds a service to the list of running services
    def add_service_int description,msg,timestamp
      s = AvahiService.new({:description => description ,:status => "running",:discovered => timestamp})
      p = msg.params
      #params look like this: 0 interface,1 protocol,2 name,3 type,4 domain
      s[:iface],s[:protocol],s[:name],s[:stype],s[:domain] = p[0],p[1],p[2],p[3],p[4]
      s
    end
    
    
    #resolve a service   
    def resolve(interface, name, stype, domain)
      add_listener(stype)
      #interface, protocol, name, type, domain, host, aprotocol, address, port, text, flags
      @server.ResolveService(interface, Avahi::PROTO_UNSPEC, name, stype, domain, Avahi::PROTO_UNSPEC, 0)
    end
    
    #publish a service  
    def publish(interface, protocol, name, stype, port, text, domain = @domain, hostname_fqdn = @hostname_fqdn)
      add_listener(stype)
      @entry.AddService(interface, protocol, 0, name, stype, domain, hostname_fqdn, port, text)
      @entry.Commit()
    end
  end
end
