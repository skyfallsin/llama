require 'rubygems'
require 'eventmachine'

require 'llama/component'
require 'llama/producer'
require 'llama/consumer'

module Llama
  module Message
    class Base
    end

    class JSONMessage < Base
    end

    class XmlMessage < Base
    end
  end

  class Filter
  end

  module Routing 
    class Route
      include EventMachine::Deferrable

      class ComponentNotFoundException < StandardError; end
      class ProducerComponentNotAllowed < StandardError; end

      def initialize(*args)
        @chain = []
        @result_queue = []
      end

      def from(component)
        raise ComponentNotFoundException unless component.kind_of?(Llama::Component) 
        @chain.push(component)
        self
      end

      def to(component)
        raise ComponentNotFoundException unless component.kind_of?(Llama::Component) 
        raise ProducerComponentNotAllowed if component.kind_of?(Llama::Producer::Base)
        @chain.push(component)
        self 
      end

      def run
        if long_running?
          puts "Starting a long-running route..."
        else
          puts "Route is not long-running..."
          msg = nil
          @chain.each_with_index{|component, i| 
            #puts "BEGIN #{i}: #{msg}"
            #puts component.inspect
            msg = component.respond(msg)
            #puts "END #{i}: #{msg}"
          }
          @result_queue << msg
        end

        set_deferred_status :succeeded
      end

      def long_running?
        false
      end

      def to_s
        @chain.to_s
      end

      def inspect
        @chain.inspect
      end
    end

    class Router
      def initialize
        puts "Initializing Router..."
        @routes ||= []
      end

      def setup_routes(&block)
        raise "Subclass this"
      end

      def from(component)
        return Route.new.from(component) 
      end

      def add_route(built_route)
        @routes.push(built_route)
        puts "added #{built_route.inspect}"
      end
      alias :add :add_route

      def run
        @routes.collect{|r| 
          Thread.new do
            r.callback{ puts "done with #{r.inspect}" } 
            r.run
          end
        }.each{|thread| thread.join}
      end

      def self.start
        EventMachine::run do 
          router = new
          router.setup_routes
          router.run
          EventMachine.stop
        end
      end
    end
  end

  Llama::Router = Llama::Routing::Router
end

if __FILE__ == $0
  class MyRouter < Llama::Router
    def setup_routes
      add_route from(Llama::Producer::DiskFile.new("test.data")).
                to(Llama::Consumer::Stdout.new)
    end
  end

  MyRouter.start
end
