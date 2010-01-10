module Llama
  module Filter
    class Base < Llama::Component

    end

    class DefaultFilter < Llama::Component
      def initialize(&block)
        @predicate = block
      end

      def process(message)
        return nil unless @predicate.call(message)
        return message
      end
    end
  end
end
