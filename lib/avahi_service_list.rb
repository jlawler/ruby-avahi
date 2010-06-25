module Avahi
  class ServiceList
    class ServiceFilter
      def initialize blk,opts={}
        @cb = blk
         raise "FILTER MUST BE A HASH" unless Hash===opts
        @filter_opts=opts
        @filter_state={:fired_for => []} 
      end
      def call_cb(s)
        @filter_state[:fired_for] << s
        @cb.call(s)
      end
      def call_if_should(service_info)
        service_info = service_info.dup
        s = service_info.delete :service
        if service_info[:cb_type] == :new_service
        call_cb(s) if self.should_run?(service_info)
        else service_info[:cb_type] == :remove_service
        trigger=service_info.dup
        @filter_state[:fired_for].map!{|fired_for|
          if  UNIQ_REQS.inject(true){|r,f|
           r and    
           (trigger[f].nil? or fired_for[f]==trigger[f] or Symbol===trigger[f])
          } then 
            nil
          else
            fired_for
          end

        }
@filter_state[:fired_for].compact!
        end
      end
      def should_run?(trigger)
        special_filters={}
        if trigger[:cb_type]==:new_service
          should_run = FILTER_TYPES.inject(true){|r,f|
            r and begin
            self[f].nil? or 
              Symbol===self[f] ? special_filters[f]=self[f] : trigger[f]==self[f]
            end
          }
          return false unless should_run
          special_filters.each do |(f,val)|
            if val==:uniq 
              any_matches=false
              filters_to_test = (UNIQ_REQS - [f])
              @filter_state[:fired_for].compact.each do |fired_for| 
last=nil
                jwlt = true if  filters_to_test.inject(true){|r,f|

                  r and ((last=f)||true)  and   
                  (trigger[f].nil? or fired_for[f]==trigger[f] or Symbol===trigger[f])
                }
              any_matches=true if jwlt
              end
              return false if any_matches 
            end
          end
          return true
        end
        return false
      end 

      def [] k 
        @filter_opts[k]
      end
    end
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
      @callbacks[gci] = ServiceFilter.new(blk,cb_type)
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
