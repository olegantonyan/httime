require 'socket'
require 'time'
require 'uri'
require_relative 'cities'

class Server
  class NotFoundError < RuntimeError; end

  @routes = []

  def self.get(path, &block)
    raise ArgumentError, 'no block given' unless block_given?
    @routes << { path: path, handler: block } # TODO: request method maybe?
  end

  def self.handle(path)
    parts = URI.decode(path).to_s.split('?')
    base_path = parts[0]
    query = parts[1]
    route = @routes.find { |r| r[:path] == base_path }
    raise NotFoundError, "no route for #{path}" unless route
    route[:handler].call(query)
  end

  def self.run(host = 'localhost', port = 3003)
    server = TCPServer.new(host, port)
    loop do
      Thread.start(server.accept) do |connection|
        response = ''
        begin
          request = connection.gets
          result = handle(request.split(' ')[1])
          response += "HTTP/1.1 200/OK\r\nContent-type:text/plain\r\n\r\n"
          response += result
        rescue NotFoundError => e
          error = "error: #{e}"
          STDERR.puts(error)
          response = "HTTP/1.1 404 Not Found\r\n\r\n#{error}\r\n"
        rescue => e
          error = "error: #{e}"
          STDERR.puts(error)
          response = "HTTP/1.1 500 Internal Error\r\n\r\n#{error}\r\n"
        ensure
          connection.print(response)
          connection.close
        end
      end
    end
  end
end

Server.get('/time') do |query|
  thetime = Time.now
  format_time = -> (tm) { tm.strftime('%Y-%m-%d %H:%M:%S') }

  result = "UTC: #{format_time.call(thetime.utc)}\r\n"

  if query
    cities = query.split(',')
    cities.each do |city|
      offset = Cities[city]
      time_in_city = if offset
                       format_time.call(thetime.getlocal(offset))
                     else
                       'move along people nothing to see here'
                     end
      result += "#{city}: #{time_in_city}\r\n"
    end
  end
  result
end

Server.run if __FILE__ == $PROGRAM_NAME
