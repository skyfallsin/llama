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

      def produce(message)
        puts "Producing from #{@filename}" 
        File.open(@filename){|f| 
          message.body = f.read
        } 

        return message
      end
    end
  end
end
