require 'simple-rss'
require 'open-uri'

module Llama
  module Producer
    class Base < Component
      def produce(*args)
        raise "Subclass #{self} and define this method"
      end

      def producer?
        true
      end
    end

    class PollingProducer < Base
      attr_accessor :poll_period

      def long_running?
        true
      end
    end

    class DiskFile < Base 
      def initialize(filename)
        @filename = filename
      end

      def produce(message)
        File.open(@filename){|f| message.body = f.read} 
        return message
      end
    end

    class RSS < PollingProducer 
      def initialize(url, opts={})
        @url = url
        @poll_period = opts[:every]
      end

      def long_running?
        !@poll_period.nil?
      end

      def produce(message)
        rss = SimpleRSS.parse open(@url)
        return Llama::Message::DefaultMessage.new(
                  :headers => {:title => rss.title, :link => rss.link}, 
                  :body => rss.items) #body is splittable
      end
    end
  end
end
