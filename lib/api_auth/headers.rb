module ApiAuth

  # Builds the canonical string given a request object.
  class Headers

    include RequestDrivers

    def initialize(request)
      @original_request = request

      case request.class.to_s
      when /Net::HTTP/
        @request = NetHttpRequest.new(request)
      when /RestClient/
        @request = RestClientRequest.new(request)
      when /Curl::Easy/
        @request = CurbRequest.new(request)
      when /ActionController::Request/
        @request = ActionControllerRequest.new(request)
      when /ActionController::TestRequest/
        if defined?(ActionDispatch)
          @request = ActionDispatchRequest.new(request)
        else
          @request = ActionControllerRequest.new(request)
        end
      when /ActionDispatch::Request/
        @request = ActionDispatchRequest.new(request)
      when /Rack::Request/
        @request = RackRequest.new(request)
      when /ActionController::CgiRequest/
        @request = ActionControllerRequest.new(request)
      else
        raise UnknownHTTPRequest, "#{request.class.to_s} is not yet supported."
      end
      true
    end

    # Returns the request timestamp
    def timestamp
       @request.timestamp
    end

    # Returns the canonical string computed from the request's headers
    def canonical_string
      config = ApiAuth.config
      array = Array.new
      array << @request.request_method  if config[:include_verb]

      array .concat [ @request.content_type,
        @request.content_md5,
        @request.request_uri.gsub(/https?:\/\/[^(,|\?|\/)]*/,''), # remove host
        @request.timestamp
      ]
      headers = config[:included_headers]
      headers.each do |header|
        headerup = header.upcase
        headers = [headerup, headerup.gsub('-','_'),"HTTP_#{headerup.gsub('-','_')}"]
        value = @request.find_header(headers)
        unless value.nil?
          key = config[:include_header_name] ? "#{header}=" :''
          array << "#{key}#{value}"
        end
      end
      array.join(",")
    end

    # Returns the authorization header from the request's headers
    def authorization_header
      @request.authorization_header
    end

    def set_date
      @request.set_date if @request.timestamp.empty?
    end

    def calculate_md5
      @request.populate_content_md5 if @request.content_md5.empty?
    end

    def md5_mismatch?
      if @request.content_md5.empty?
        false
      else
        @request.md5_mismatch?
      end
    end

    # Sets the request's authorization header with the passed in value.
    # The header should be the ApiAuth HMAC signature.
    #
    # This will return the original request object with the signed Authorization
    # header already in place.
    def sign_header(header)
      @request.set_auth_header header
    end

  end

end
