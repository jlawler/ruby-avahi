require 'rubygems'
require 'dbus'
require 'thread'

require 'avahi/constants'
require 'avahi/manager'
require 'avahi/daemon'
require 'avahi/service'
require 'avahi/callback'
require 'avahi/service_list'

require 'gdbm' rescue LoadError 
module Avahi
  FILTER_TYPES = [:stype, :status, :discovered, :domain, :description, :iface, :name, :protocol,:services,:updated_pass].freeze
  UNIQ_REQS = [:stype, :domain, :description, :iface, :name ].freeze
  AVAHI_SERVICE_DB = '/usr/lib/avahi/service-types.db'
  #some discoverable service types 
  def silent?
    false
  end
  module_function :silent?
  def get_service_types
    return @@types = begin
      msg,res=nil,nil
      if Object.const_defined?(:GDBM) 
        msg = "Warning: Can't load ruby gdbm" if msg.nil? and not Object.const_defined?(:GDBM)
        msg = "Warning: Can't find DB file" if msg.nil? and not File.exists?(AVAHI_SERVICE_DB)
        if msg.nil?
          res = GDBM.new(AVAHI_SERVICE_DB).to_hash.reject!{|k,v|k=~/\[/}.invert
          msg = "ERROR Opening avahi service db" if res.nil?
        end 
      end
      STDERR.puts msg + "\ndefaulting to avahi-browse hack" if msg and not silent? 
      if res.nil?
        raise "Unable to determine service types!" if `avahi-browse`==''
        res ||=
          [`avahi-browse --all -bt`.split("\n"),`avahi-browse --all -bkt`.split("\n")].transpose.inject({}){|s,(k,v)|s.merge({k => v})}
      end
      res      
    end
  end
  module_function :get_service_types

end

