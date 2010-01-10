
module Llama
  class Message
  end

  class Component
  end

  module Producer
    class Base < Component
    end

    class DiskFile < Base 
    end
  end

  module Consumer
    class Base < Llama::Component
    end
  end

  class Filter
  end

  class Router
    class ComponentNotFoundException < StandardError; end
    def setup_routes(&block)
      raise "Subclass this"
    end

    def from(component)
      raise ComponentNotFoundException unless component.kind_of?(Llama::Component) 
      return self
    end

    def to(component)
      raise ComponentNotFoundException unless component.kind_of?(Llama::Component) 
      return self
    end

    def self.start
    end
  end
end

class MyRouter < Llama::Router
  def setup_routes
    from(Llama::Components::DiskFile.new("test.data")).to($STDOUT)
  end
end

MyRouter.start
