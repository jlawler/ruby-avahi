module Avahi
  class AvahiManager
    include Avahi::Constants
    def get_service_types
      Avahi.get_service_types
    end
    attr_accessor :main,:server 
    def inspect
      orig = super
      orig=~/^([^\s]+)/ 
      %Q(#{$1} @hostname="#{@hostname}", @address="#{@address}">)
    end
    def to_s; self.inspect; end 
    attr_reader :services #we'll but all the services we discover in here
    def use_bus
      return yield(@dbus)
      @bus.dbus_mutex{|i|yield(i)}
    end
    def _service_list; 
      @service_list 
    end 

    def service_list; 
      #add_service_listeners
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
      #we'll put services in here
      @services = Hash.new{|h,e|h[e]=[]}
      #add the default service listeners
      add_service_listeners
      #go into loop (non-blocking)
      #avahi_loop
    end

    #add service listeners
    def add_service_listeners
      raise "double add" if @_service_listeners_initialized
      @_service_listeners_initialized = true
      pass_number = @pass_counter+=1
      #rofl_enable_trace
      service_types = get_service_types
      #will subscribe to all known services
      service_types.each do |description,service| 
        #puts "Now listening on #{description}!"
        browser_path = use_bus{@server.ServiceBrowserNew(IF_UNSPEC,PROTO_UNSPEC,service,@domain,0).first}
        #now we start the match rule definition
        mr = DBus::MatchRule.new
        mr.type = "signal"
        mr.interface = "org.freedesktop.Avahi.ServiceBrowser"
        mr.path = browser_path
        count=0
        use_bus{|bus|@bus.add_match(mr) { |msg| service_callback description,msg,service,pass_number,Time.now.to_i }}
      end
    end
    
    #service callback
    def service_callback description,msg,service_type,pass_number,timestamp
      case msg.member
        when 'ItemNew' then @service_list.add(add_service_int(description,msg,timestamp),pass_number)
        when "ItemRemove" then   @service_list.remove(msg,pass_number)
        when 'CacheExhausted' then nil
        when 'AllForNow' then 
          @service_list.close_type(service_type,pass_number)
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
    def resolve(interface, name, type, domain)
      #interface, protocol, name, type, domain, host, aprotocol, address, port, text, flags
      @server.ResolveService(interface, Avahi::PROTO_UNSPEC, name, type, domain, Avahi::PROTO_UNSPEC, 0)
    end
    
    #publish a service  
    def publish(interface, protocol, name, type, port, text, domain = @domain, hostname_fqdn = @hostname_fqdn)
      use_bus{
      #STDERR.puts "call AddService "  + [interface, protocol, 0, name, type, domain, hostname_fqdn, port, text].map{|i|i.inspect}.join(', ')
      @entry.AddService(interface, protocol, 0, name, type, domain, hostname_fqdn, port, text)
      @entry.Commit()
      }
    end

    #set the host name
    def set_host_name(name)
      use_bus{@server.SetHostName(name)}
      @hostname = @server.GetHostName(name)
    end
    def avahi_loop_thread
      @avahi_loop_thread
    end 
    #don't get nasty
    def avahi_loop
      @avahi_loop_thread ||= begin
        Thread.new do
          loop do 
            @server.introspect
            sleep 1
          end
        end
      end
    end
  end
end
