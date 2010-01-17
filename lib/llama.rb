require 'rubygems'
require 'eventmachine'

require 'llama/component'
require 'llama/producer'
require 'llama/consumer'
require 'llama/processor'
require 'llama/eip'
require 'llama/message'
require 'llama/filter'
require 'llama/router'

if __FILE__ == $0
  class MyRouter < Llama::Router
    def setup_routes
#      add_route from(Llama::Producer::DiskFile.new("test.data")).
#                process(Llama::Processor::LineInput.new).
#                split_entries.
#                filter{|message| message.body == "one"}.
#                to(Llama::Consumer::Stdout.new)

#      add_route from(Llama::Producer::Http.new("http://yahoo.com")).
#                to(Llama::Consumer::Stdout.new)

      add_route from(Llama::Producer::Stomp.new("localhost", 61613, 'llama')).
                to(Llama::Consumer::Stdout.new)

      add_route from(Llama::Producer::RSS.new("http://reddit.com/.rss", :every => 3)).
                split_entries.to(Llama::Consumer::Stdout.new)
    end
  end

  MyRouter.start
end
