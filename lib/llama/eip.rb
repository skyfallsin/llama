module Llama
  module EIP
    class Base < Component
    end

    class Splitter < Base 
      class CannotSplitNonEnumerableMessageBody < StandardError; end

      def process(message)
        return CannotSplitNonEnumerableMessageBody unless message.body.respond_to?(:each)
        return message.body.collect{|entry|
          message.class.new(:headers => message.headers, :body => entry)
        }
      end
    end
  end
end
