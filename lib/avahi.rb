require 'rubygems'
require 'dbus'
require 'thread'

require 'avahi/constants'
require 'avahi/manager'
require 'avahi/service'
require 'avahi/callback'
require 'avahi/service_list'
 
module Avahi
  FILTER_TYPES = [:stype, :status, :discovered, :domain, :description, :iface, :name, :protocol,:services,:updated_pass].freeze
  UNIQ_REQS = [:stype, :domain, :description, :iface, :name ].freeze
  #some discoverable service types 
  def get_service_types
    return @@types = [`avahi-browse --all -bt`.split("\n"),`avahi-browse --all -bkt`.split("\n")].transpose.inject({}){|s,(k,v)|s.merge({k => v})}
    types = {}
    types["Workstation"] = "workstation"
    types["SSH Remote Terminal"] = "ssh"
    types["Website"] = "http"
    types["Secure Website"] = "https"
    types["iChat Presence"] = "presence"
    types["PulseAudio Sound Server"] = "pulse-server"
    types["Subversion Revision Control"] = "svn"
    types["GIT"] = "git"
    types["APT Package Repository"] = "apt"
    types["WebDAV"] = "webdav"
    types["Secure WebDAV"] = "webdavs"
    types["Samba"] = "smb"
    types["Robots IPC Cluster"] = "robots"
    types["Alexandria"] = "alexandria"
    return types
  end
  module_function :get_service_types

end

