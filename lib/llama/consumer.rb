module Llama
  module Consumer
    class Base < Component
      def consume(*args) 
        raise "Subclass #{self} and define this method"
      end

      def consumer?
        true
      end
    end

    class Stdout < Base
      def initialize(print_key=nil)
        @print_key = print_key
      end

      def consume(message)
        if @print_key
          puts "RECV: #{message.body.send(@print_key).inspect[0..100]}"
        else
          puts "RECV: #{message.body.inspect[0..100]}"
        end
        
        return message 
      end
    end
  end
end
