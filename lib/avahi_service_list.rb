module Avahi
  class ServiceList
    FILTER_TYPES = [:stype, :status, :discovered, :domain, :description, :iface, :name, :protocol,:services,:updated_pass].freeze
    UNIQ_REQS = [:stype, :domain, :description, :iface, :name, :discovered ].freeze
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
        call_cb(s) if self.should_run?(service_info)
      end
      def should_run?(trigger)
STDERR.puts "\n\n\tSHOULD_RUN? " + trigger.inspect
#        STDERR.puts "FIRED FOR " +  @filter_state[:fired_for].inspect
        special_filters={}
        if trigger[:cb_type]==:new_service
          should_run = FILTER_TYPES.inject(true){|r,f|
            r and begin
#STDERR.puts "\t\t#{[trigger[f],self[f]].inspect}"
            self[f].nil? or 
              Symbol===self[f] ? special_filters[f]=self[f] : trigger[f]==self[f]
            end
          }
          return false unless should_run
#STDERR.puts "SURVIVED CHECK !"
#STDERR.puts "SPECIAL FILTERS = #{special_filters.inspect}"
          special_filters.each do |(f,val)|
            if val==:uniq 
              any_matches=false
              filters_to_test = (UNIQ_REQS - [f])
              @filter_state[:fired_for].compact.each do |fired_for| 
#STDERR.puts "FIRED FOR? " + fired_for.inspect
#nm=nil
last=nil
                jwlt = true if  filters_to_test.inject(true){|r,f|
#                  STDERR.puts "\t\t\t#{[fired_for,trigger].inspect}"
                  STDERR.puts "\t\t#{f} #{[fired_for[f],trigger[f]].inspect} #{(trigger[f].nil? or fired_for[f]==trigger[f] or Symbol===trigger[f])}"

                  r and ((last=f)||true)  and   
                  (trigger[f].nil? or fired_for[f]==trigger[f] or Symbol===trigger[f])
                }
                if jwlt
                puts "\tNot firing for dup\n\t\t#{trigger.inspect}\n\t\t#{ fired_for.inspect}" 
else
puts " failed on #{f}" + [fired_for[f],trigger[f]].inspect   
puts "\tNEW MATCH dup\n\t\t#{trigger.inspect}\n\t\t#{ fired_for.inspect}" 
end 
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
        next unless filter[:cb_type]==new_service_info[:cb_type]
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
=begin
      existing_service = @service_list[s[:stype]].inject(nil){|r,i|r || i if i.same_class?(s)}
      if existing_service
        existing_service[:iface] << s[:iface].first
        existing_service.updated_pass=pass_number 
      else 
        s.updated_pass = pass_number
        @service_list[s[:stype]] << s
      end
=end
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
          nil
        else
          s
        end
      end.compact!
      nil
    end
    def close_type service_type,pass_number
#STDERR.puts [service_type].inspect
#@service_list.to_a.sort_by(&:first).map{|l|if l.last.size==0 then nil else [l.first,l.last.size] end }.compact.each{|p|STDERR.puts p.inspect}
#      STDERR.puts "closing #{service_type} #{pass_number.inspect}"
      @service_list[service_type].delete_if{|t|t.updated_pass < pass_number}
    end
  end
end
