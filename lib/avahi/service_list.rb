module Avahi
  class ServiceList

    def initialize
      @service_list=Hash.new{|h,e|h[e]=[]}
      @callbacks={}
      @last_callback_id=0
    end
    def get_callback_id
      ret = nil
      Thread.exclusive do 
      ret = @last_callback_id+=1
      end
      ret
    end
    def add_callback cb_type={}, &blk
      gci = get_callback_id
      @callbacks[gci] = Avahi::Callback.new(blk,cb_type)
      gci 
    end
    def run_new_service_callbacks new_service_info={}
      @callbacks.values.each {|filter|
        filter.call_if_should(new_service_info)
      }
    end       
    def to_hsh
      @service_list.dup
    end
    def [] k
      @service_list[k]
    end 
    def []= k,v
      @service_list[k]=v
    end 
    def add s,pass_number
      s.updated_pass=pass_number
      @service_list[s[:stype]] << s
    
      run_new_service_callbacks s.to_filter_hsh.merge(:cb_type => :new_service, :service => s)
    end
    def remove msg,pass_number
      @remove_order ||= [:iface, :proto, :name, :stype, :domain, :unknown ]
      remove_hsh={}
      msg.params.size.times{|i|remove_hsh[@remove_order[i]]=msg.params[i]}
      @service_list[remove_hsh[:stype]].map! do  |s|
        should_remove = [:iface,:domain,:stype,:name].inject(true){|r,t|r and s[t]==remove_hsh[t]}
        if should_remove
         run_new_service_callbacks s.to_filter_hsh.merge(:cb_type => :remove_service, :service => s)
          nil
        else
          s
        end
      end.compact!
      nil
    end
    def close_type service_type,pass_number
      @service_list[service_type].delete_if{|t|t.updated_pass < pass_number}
    end
  end
end
