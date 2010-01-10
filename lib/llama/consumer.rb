module Llama
  module Consumer
    class Base < Component
      def consume(*args) 
        raise "Subclass #{self} and define this method"
      end
    end

    class Stdout < Base
      def consume(message)
        puts "RECV: #{message.body}"
        return message 
      end
    end
  end
end
