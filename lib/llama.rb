require 'rubygems'
require 'eventmachine'

module Llama
  def self.start(&block)
    EventMachine::run do
      puts "Starting Llama..."
      block.call
    end
  end 
  
  module Message
    class Base
    end

    class JSONMessage < Base
    end

    class XmlMessage < Base
    end
  end

  class Component
  end

  module Producer
    class Base < Component
      def produce(*args)
        raise "Subclass #{self} and define this method"
      end
    end

    class DiskFile < Base 
      def initialize(filename)
        @filename = filename
      end

      def produce
        puts "Producing from #{@filename}" 
        return "HELLO"
      end
    end
  end

  module Consumer
    class Base < Component
      def consume(*args) 
        raise "Subclass #{self} and define this method"
      end
    end

    class Stdout < Base
      def consume(message)
        puts message
      end
    end
  end

  class Filter
  end

  module Routing 
    class Route
      class ComponentNotFoundException < StandardError; end
      class ProducerComponentNotAllowed < StandardError; end

      def initialize(*args)
        @chain = []
      end

      def from(component)
        raise ComponentNotFoundException unless component.kind_of?(Llama::Component) 
        puts "From #{component}"
        @chain.push(component)
        self
      end

      def to(component)
        raise ComponentNotFoundException unless component.kind_of?(Llama::Component) 
        raise ProducerComponentNotAllowed if component.kind_of?(Llama::Producer::Base)
        puts "To #{component}"
        @chain.push(component)
        self 
      end

      def run
        EventMachine::spawn {
          puts "Running #{self}"
        }
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
      end

      def run
        @routes.each{|r| r.run}
      end

      def self.start
        router = new
        router.setup_routes
        router.run
      end
    end
  end
end

Llama::start do
  class MyRouter < Llama::Routing::Router
    def setup_routes
      add from(Llama::Producer::DiskFile.new("test.data")).
          to(Llama::Consumer::Stdout.new)
    end
  end

  MyRouter.start
end
