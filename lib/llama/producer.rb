module Llama
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
end
