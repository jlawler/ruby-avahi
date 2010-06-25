module Avahi
  class AvahiService
    attr_accessor :stype, :status, :discovered, :domain, :description, :iface, :name, :protocol,:services,:updated_pass
    def to_filter_hsh
      ret={}
      [:stype, :domain, :description, :iface, :name, :discovered ].each{|e|ret[e]=self[e]}
      ret    
    end
    def initialize hsh
      self.update(hsh)
    end
    def [] x
      xs = x.to_s
      x = :stype if xs == 'service_type'
      self.send(x) unless xs=~/^=/
    end
    def []= x,y
      self.send("#{x}=",y)
    end
    def update hsh
      hsh.each_pair{|k,v|self.send("#{k}=",v)}
    end
    def same_class? x
      [:stype, :status, :domain, :description, :name, :protocol].inject(true){ |r,att|
        r and (self[att]==x[att])
      }
    end  
  end
end
