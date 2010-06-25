module Avahi
  class Daemon < ::Avahi::AvahiManager
    include Avahi::Constants


    def initialize
      super
    end
    
    def avahi_loop_thread
      @avahi_loop_thread
    end 
    #don't get nasty
    def add_listener stype
      raise "Can't add a listener after you've started the daemon!" if @avahi_loop_thread
      super
    end
    def avahi_loop
      @avahi_loop_thread ||= begin
        Thread.new do
          loop do 
            self.server.introspect
            sleep 0.2 
          end
        end
      end
    end
  end
end
