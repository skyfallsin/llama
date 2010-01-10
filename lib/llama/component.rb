module Llama
  class Component
    def respond(message)
      message = case self
        when Llama::Producer::Base: produce(message)
        when Llama::Consumer::Base: consume(message)
      end
      return message
    end

    def producer?
      false
    end

    def consumer?
      false
    end

    def long_running?
      false
    end
  end
end
