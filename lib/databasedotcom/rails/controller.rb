module Databasedotcom
  module Rails
    module Controller
      module ClassMethods
        def dbdc_client
          unless @dbdc_client
            if ENV['DATABASE_COM_URL']
              @dbdc_client = Databasedotcom::Client.new
            else
              config = YAML.load_file(File.join(::Rails.root, 'config', 'databasedotcom.yml'))
              @dbdc_client = Databasedotcom::Client.new(config)
            end
            @dbdc_client.debug = true
            password = @dbdc_client.password
            username = @dbdc_client.username
            if ENV['DATABASE_COM_SECURITY_TOKEN']
              stoken = ENV['DATABASE_COM_SECURITY_TOKEN']
              pwd_stoken = "#{@dbdc_client.password}#{stoken}"
              password = pwd_stoken
            end
            puts "Using [#{username}][#{password}] to authenticate"
            @dbdc_client.authenticate(:username => username, :password => password)
          end
          @dbdc_client
        end
        
        def dbdc_client=(client)
          @dbdc_client = client
        end

        def sobject_types
          unless @sobject_types
            @sobject_types = dbdc_client.list_sobjects
          end

          @sobject_types
        end

        def const_missing(sym)
          if sobject_types.include?(sym.to_s)
            dbdc_client.materialize(sym.to_s)
          else
            super
          end
        end
      end
      
      module InstanceMethods
        def dbdc_client
          self.class.dbdc_client
        end

        def sobject_types
          self.class.sobject_types
        end
      end
      
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.send(:extend, ClassMethods)
      end
    end
  end
end
