module Avahi
  class Callback
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
end
