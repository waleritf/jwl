module JWL
  class Request
    HEADERS = {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    }

    attr_reader :method, :url, :body

    def initialize(method, url, body=nil)
      @method = method
      @url = URI(url)
      @body = body
    end

    def issues
      perform('/rest/api/2/search')['issues']
    end

    def worklogs(issue_key)
      perform("/rest/api/2/issue/#{issue_key}/worklog")['worklogs']
    end

    private

    def perform(path)
      url.path = path

      req = Module.const_get("Net::HTTP::#{method.capitalize}").new(url, HEADERS).tap do |req|
        req.basic_auth Client.login, Client.password
        req.body = body.to_json
      end

      http = Net::HTTP.new(url.hostname, url.port)
      http.use_ssl = true

      JSON.parse http.request(req).body
    end
  end
end
