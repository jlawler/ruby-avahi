require 'rubygems'
require 'dbus'
require 'thread'

  
module Avahi
  FILTER_TYPES = [:stype, :status, :discovered, :domain, :description, :iface, :name, :protocol,:services,:updated_pass].freeze
  UNIQ_REQS = [:stype, :domain, :description, :iface, :name ].freeze
end
require 'avahi_manager'
require 'avahi_constants'
require 'avahi_service'
require 'callback'
require 'avahi_service_list'

