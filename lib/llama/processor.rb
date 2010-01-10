module Llama
  module Processor
    class Base < Llama::Component
      def process(*args)
        raise "Define this in your subclass"
      end
    end

    class LineInput < Base 
      def process(message)
        message.body = message.body.split("\n")
        return message
      end
    end

  end
end
