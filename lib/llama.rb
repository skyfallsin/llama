require 'rubygems'
require 'eventmachine'

module Llama
  def self.start(&block)
    EventMachine::run do
      puts "Starting Llama..."
      block.call
    end
  end 
end

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
        s = rand(10)
        puts "sleeping for #{s} seconds"
        sleep(s)
        set_deferred_status :succeeded
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

      def add(built_route)
        @routes.push(built_route)
        puts "added #{built_route.inspect}"
      end

      def run
        @routes.collect{|r| 
          EventMachine::spawn do
            r.callback{ puts "done with #{r.inspect}" } 
            r.run
          end
        }.each_with_index{|s,i| 
          puts "notifying #{i}"
          s.notify}
      end

      def self.start
        router = new
        router.setup_routes
        router.run
        EventMachine.stop
      end
    end
  end
end

if __FILE__ == $0
  Llama::start do
    class MyRouter < Llama::Routing::Router
      def setup_routes
        add from(Llama::Producer::DiskFile.new("test.data")).
            to(Llama::Consumer::Stdout.new)

        add from(Llama::Producer::DiskFile.new("hello.data")).
            to(Llama::Consumer::Stdout.new)
      end
    end

    MyRouter.start
  end
end
