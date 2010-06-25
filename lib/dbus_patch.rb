require 'rubygems'
require 'dbus'
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

