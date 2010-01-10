module Llama
  module EIP
    class Base < Component
    end

    class Splitter < Base 
      class CannotSplitNonEnumerableMessageBody < StandardError; end

      def process(message)
        raise CannotSplitNonEnumerableMessageBody unless message.body.kind_of?(Array)
        return message.body.collect{|entry|
          message.class.new(:headers => message.headers, :body => entry)
        }
      end
    end
  end
end
