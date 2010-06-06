require 'rubygems'
require 'dbus'
require 'dbus_patch'
require 'avahi_constants'
require 'thread'

class DBus::Connection
  def dbus_mutex
    @dbus_mutex||=Mutex.new
    return @dbus_mutex unless Kernel.block_given?
    @dbus_mutex.synchronize{yield(self)}
  end
  def update_buffer
    begin
      @buffer += @socket.read_nonblock(MSG_BUF_SIZE)
      @last_success=Time.now
    rescue Errno::EAGAIN => e
#      STDERR.puts @last_success.inspect
#      STDERR.puts ["#{e.class} #{e.message}",*e.backtrace].join("\n")
      sleep 1
      retry
    end
  end
end
class DBus::Main
  attr_accessor :last_updated
  def last_updated; @last_updated||=Time.now; end
  def dbus_mutex
    @dbus_mutex||=Mutex.new
  end
  def run_with_mutex
      loop do
        ready, dum, dum = IO.select(@buses.keys)
        last_updated=Time.now 
        ready.each do |socket|
          b = @buses[socket]
        self.dbus_mutex.synchronize do
          b.update_buffer
        end
          while m = b.pop_message
            b.process(m)
          end
      end
    end
  end
end
module Avahi
  class AvahiService
    attr_accessor :type, :status, :discovered, :domain, :description, :iface, :name, :protocol
    def initialize hsh
      self.update(hsh)
    end
    def iface= x
      (@iface||=[])<<x
    end
    def iface
      @iface||=[]
    end
    def [] x
      self.send(x) unless x.to_s=~/^=/
    end
    def []= x,y
      self.send("#{x}=",y)
    end
    def update hsh
      hsh.each_pair{|k,v|self.send("#{k}=",v)}
    end
    def same_class? x
      [:type, :status, :domain, :description, :name, :protocol].inject(true){ |r,att|
#        STDERR.puts "SC : #{self[att]} #{x[att]} #{r}"
        r and (self[att]==x[att])
      }
    end  
  end
  class AvahiManager
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
        #puts "Now listening on #{description}!"
        browser_path = use_bus{@server.ServiceBrowserNew(IF_UNSPEC,PROTO_UNSPEC,service,@domain,0).first}
        #now we start the match rule definition
        mr = DBus::MatchRule.new
        mr.type = "signal"
        mr.interface = "org.freedesktop.Avahi.ServiceBrowser"
        mr.path = browser_path
        use_bus{|bus|@bus.add_match(mr) { |msg| service_callback description,msg }}
      end
    end
    
    #service callback
    def service_callback description,msg
      add_service description,msg if msg.member.eql? "ItemNew"
      remove_service description,msg if msg.member.eql? "ItemRemoved"
    end
    
    #adds a service to the list of running services
    def add_service description,msg
#      STDERR.puts "NEW SERVICE!"
      s = AvahiService.new({:description => description ,:status => "running",:discovered => Time.now})
      p = msg.params
      #params look like this: 0 interface,1 protocol,2 name,3 type,4 domain
      s[:iface],s[:protocol],s[:name],s[:type],s[:domain] = p[0],p[1],p[2],p[3],p[4]
      #setup
      @services[s[:type]] ||= [] 
      #and add
      existing_service =@services[s[:type]].inject(nil){|r,i|r || i if i.same_class?(s)}
      if existing_service
        existing_service[:iface] << s[:iface].first
      else 
        @services[s[:type]] << s unless existing_service
      end
#      STDERR.puts "FAKE MERGE " + [existing_service,s].inspect  
      #RESOLVE - TODO: still blocks, don't know why, guess i broke ruby-dbus again :)
      #0 interface,1 protocol,2 name,3 type,4 domain,5 host,6 aprotocol,7 address,8 port,9 text,10 flags
      #res = resolve(p[0],p[2],p[3],p[4])
      #puts "host: #{res[5]} port: #{res[8]} addr: #{res[7]}"
    end
    
    #removes a service from the list of running services
    def remove_service description,msg
#      puts "REMOVING: #{description}: #{msg.params[2]}"
    end
    
    #resolve a service   
    def resolve(interface, name, type, domain)
      #interface, protocol, name, type, domain, host, aprotocol, address, port, text, flags
      @server.ResolveService(interface, Avahi::PROTO_UNSPEC, name, type, domain, Avahi::PROTO_UNSPEC, 0)
    end
    
    #publish a service  
    def publish(interface, protocol, name, type, port, text, domain = @domain, hostname_fqdn = @hostname_fqdn)
      use_bus{
      @entry.AddService(interface, protocol, 0, name, type, domain, hostname_fqdn, port, text)
      @entry.Commit()
      }
    end

    #set the host name
    def set_host_name(name)
      use_bus{@server.SetHostName(name)}
      @hostname = @server.GetHostName(name)
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
