require 'avahi'
def dba 
  @avahi_dba||= Avahi::AvahiManager.new
end

def dbat
  @avahi_dbat||=begin
    _t = dba
    _t.avahi_loop
    _t
  end
end

STDERR.puts "pp Avahi.get_service_types"
STDERR.puts "dba.resolve(Avahi::Constants::IF_UNSPEC,'music player daemon on papyrus ','_alexandria._tcp','local')"
STDERR.puts "publish(Avahi::Constants::IF_UNSPEC,Avahi::Constants::PROTO_UNSPEC,'blahblah','_synergys._tcp','35','descript')"
#def publish(interface, protocol, name, type, port, text, domain = @domain, hostname_fqdn = @hostname_fqdn)

