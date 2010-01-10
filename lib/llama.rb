require 'rubygems'
require 'eventmachine'

require 'llama/component'
require 'llama/producer'
require 'llama/consumer'
require 'llama/processor'
require 'llama/eip'

module Llama
  module Message
    class Base
      attr_accessor :body, :headers
      def initialize(opts={})
        @revisions = [] 
        @body = opts[:body] || nil
        @headers = opts[:headers] || {}
      end

      def revision_count
        @revisions.size
      end

      def body=(content)
        @revisions << @body
        @body = content
      end
    end

    class DefaultMessage < Base
    end

    class JSONMessage < DefaultMessage 
    end

    class XmlMessage < DefaultMessage 
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

      def process(component)
        raise ProcessorComponentNotFoundException unless component.kind_of?(Llama::Processor::Base)
        puts "PROCESSOR HOOK"
        @chain.push(component)
        self
      end

      def to(component)
        raise ComponentNotFoundException unless component.kind_of?(Llama::Component) 
        raise ProducerComponentNotAllowed if component.kind_of?(Llama::Producer::Base)
        @chain.push(component)
        self 
      end

      def split_entries
        @chain.push(Llama::EIP::Splitter.new)
        self
      end

      def run
        if long_running?
          puts "Starting a long-running route..."
        else
          puts "Route is not long-running..."
          messages = [Llama::Message::DefaultMessage.new]
          @chain.each_with_index{|component, i| 
            #puts "BEGIN #{i}: #{messages.inspect}"
            messages.collect!{|m| component.respond(m)}.flatten!
            #puts "END #{i}: #{messages.inspect}"
          }

          @result_queue.push(*messages) 
        end

        set_deferred_status :succeeded
      end

      def long_running?
        !@chain.select{|x| x.producer? && x.long_running?}.empty? 
      end

      def inspect
        @chain.inspect
      end
      alias :to_s :inspect
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
            r.callback{ puts "done with #{r}" } 
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
                process(Llama::Processor::LineInput.new).
                split_entries.to(Llama::Consumer::Stdout.new)

#      add_route from(Llama::Producer::RSS.new("http://reddit.com/.rss")).
#                to(Llama::Consumer::Stdout.new)
    end
  end

  MyRouter.start
end
