module Llama
  module Message
    class Base
      attr_reader   :body 
      attr_accessor :headers
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
end
