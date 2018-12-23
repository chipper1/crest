module Crest
  class Redirector
    def initialize(
      @response : Crest::Response,
      @request : Crest::Request
    )
    end

    def follow : Crest::Response
      case @response.status_code
      when 200..207
        @response
      when 301, 302, 303, 307
        check_max_redirects
        follow_redirection
      else
        raise_exception! if @request.handle_errors
        @response
      end
    end

    private def check_max_redirects
      raise_exception! if @request.max_redirects <= 0
    end

    # Follow a redirection response by making a new HTTP request to the
    # redirection target.
    private def follow_redirection
      url = extract_url_from_headers

      new_request = prepare_new_request(url)
      new_request.redirection_history = @response.history + [@response]
      new_request.execute
    end

    private def extract_url_from_headers
      location_url = @response.headers["Location"].to_s
      location_uri = URI.parse(location_url)

      return location_url if location_uri.absolute?

      uri = URI.parse(@request.url)
      port = uri.port ? ":#{uri.port}" : ""

      "#{uri.scheme}://#{uri.host}#{port}#{location_url}"
    end

    private def prepare_new_request(url)
      Request.new(
        method: :get,
        url: url,
        headers: @request.headers.to_h,
        max_redirects: @request.max_redirects - 1,
        cookies: @response.cookies,
        logging: @request.logging,
        logger: @request.logger,
        handle_errors: @request.handle_errors,
        p_addr: @request.p_addr,
        p_port: @request.p_port,
        p_user: @request.p_user,
        p_pass: @request.p_pass
      )
    end

    private def raise_exception!
      raise RequestFailed.subclass_by_status_code(@response.status_code).new(@response)
    end
  end
end