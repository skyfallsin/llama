module Llama
  module Routing 
    class Route
      include EM::Deferrable

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
        @chain.push(component)
        self
      end

      def filter(klass=nil, &block)
        if klass
          @chain.push(klass)
        else
          @chain.push(Llama::Filter::DefaultFilter.new(&block))
        end

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
        if evented?
          run_evented_route!
        elsif polling?
          EM::PeriodicTimer.new(poll_period) do
            run_route!
          end 
        else
          run_route!
        end

        set_deferred_status :succeeded
      end

      def run_evented_route!
        # remove the producer from the chain, and attach the rest of the route as a callback
        producer = evented_producers.first
        @chain.delete(producer)
        producer.respond(Llama::Message::DefaultMessage.new)
        producer.add_hook do |message|
          run_route!(message)
        end
      end

      def run_route!(message=Llama::Message::DefaultMessage.new)
        messages = [message]
        @chain.each_with_index{|component, i| 
          #puts "BEGIN #{i}: #{messages.inspect}"
          messages.collect!{|m| component.respond(m)}.flatten!
          messages.compact! #filters return nil if predicate fails
          #puts "END #{i}: #{messages.inspect}"
        }
        @result_queue.push(*messages) 
      end

      def evented?
        !evented_producers.empty?
      end

      def evented_producers
        @chain.select{|x| x.producer? && x.evented?}
      end

      def polling?
        !polling_producers.empty?
      end

      def polling_producers 
        @chain.select{|x| x.producer? && x.polling?}
      end

      def poll_period 
        polling_producers.first.poll_period
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
            r.run
          end
        }.each{|thread| thread.join}
      end

      def self.start
        EM::run do 
          router = new
          router.setup_routes
          router.run
        end
      end
    end
  end

  Llama::Router = Llama::Routing::Router
end

