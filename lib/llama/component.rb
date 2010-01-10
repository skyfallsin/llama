module Llama
  class Component
    def respond(message)
      message = case self
        when Llama::Producer::Base: produce(message)
        when Llama::Consumer::Base: consume(message)
      end
      message.revision += 1
      return message
    end
  end
end
