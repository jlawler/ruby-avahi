module Avahi
  class AvahiManager 
    include Avahi::Constants
    attr_accessor :service_list, :server
    def initialize
      @pass_counter=0
      @bus = DBus::SystemBus.instance
      @service_list=Avahi::ServiceList.new
      interface,@protocol,name,aprotocol,@address,flags = self.server.ResolveHostName(IF_UNSPEC,IF_UNSPEC,self.default_fqdn,IF_UNSPEC,0)
    end
    def entry
      @entry ||= begin
        entry_path = self.server.EntryGroupNew()[0]
        _entry = self.avahi.object(entry_path)
        _entry.introspect
        _entry.default_iface = 'org.freedesktop.Avahi.EntryGroup'
        _entry
      end
    end

    def avahi;   @avahi ||= @bus.service('org.freedesktop.Avahi'); end
    def server 
      @server||=begin
        _server = self.avahi.object('/')
        _server.introspect
        _server.default_iface = 'org.freedesktop.Avahi.Server'
        _server
      end
    end

    def default_domain
      @default_domain||=@server.GetDomainName()[0]
    end
    def default_fqdn
      @default_fqdn ||= @server.GetHostNameFqdn()[0]
    end
    def add_listener stype
      browser_path = @server.ServiceBrowserNew(IF_UNSPEC,PROTO_UNSPEC,stype,self.default_domain,0).first
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
      server.ResolveService(interface, Avahi::PROTO_UNSPEC, name, stype, domain, Avahi::PROTO_UNSPEC, 0)
    end
    
    #publish a service  
    def publish(interface, protocol, name, stype, port, text, domain = self.default_domain, hostname_fqdn = self.default_fqdn)
      add_listener(stype)
      entry.AddService(interface, protocol, 0, name, stype, domain, hostname_fqdn, port, text)
      entry.Commit()
    end
  end
end
