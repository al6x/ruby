require 'rack'

module Rack
  class Assets < Files
    attr_accessor :roots, :prefix

    def initialize roots, prefix, headers = {}, default_mime = 'text/plain'
      @prefix = prefix
      @roots = roots.map { |path| ::File.expand_path(path) }
      super nil, headers, default_mime
    end

    def get env
      request = Rack::Request.new env
      unless ALLOWED_VERBS.include? request.request_method
        return fail(405, "Method Not Allowed", { 'allow' => ALLOW_HEADER })
      end

      path_info = Utils.unescape_path request.path_info
      return fail(400, "Bad Request") unless Utils.valid_path?(path_info)

      clean_path_info = Utils.clean_path_info(path_info).sub(@prefix, '')

      @roots.each do |root|
        path = ::File.join(root, clean_path_info)
        return serving(request, path) if ::File.file?(path) && ::File.readable?(path)
      end

      fail(404, "File not found: #{path_info}")
    end

    def match? path
      path.start_with?(@prefix) or path == "/favicon.ico"
    end
  end
end

# Making thin exit on error
module Thin
  class Connection
    def pre_process
      # Add client info to the request env
      @request.remote_address = remote_address

      # Connection may be closed unless the App#call response was a [-1, ...]
      # It should be noted that connection objects will linger until this
      # callback is no longer referenced, so be tidy!
      @request.async_callback = method(:post_process)

      if @backend.ssl?
        @request.env["rack.url_scheme"] = "https"

        if cert = get_peer_cert
          @request.env['rack.peer_cert'] = cert
        end
      end

      # When we're under a non-async framework like rails, we can still spawn
      # off async responses using the callback info, so there's little point
      # in removing this.
      response = AsyncResponse
      catch(:async) do
        # Process the request calling the Rack adapter
        response = @app.call(@request.env)
      end
      response
    # rescue Exception => e
    #   unexpected_error(e)
    #   # Pass through error response
    #   can_persist? && @request.persistent? ? Response::PERSISTENT_ERROR : Response::ERROR
    end
  end
end