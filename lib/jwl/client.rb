module JWL
  class Client
    # JWL::Client.new.collect_worklogs 'jwlclear', 'admin', DateTime.parse('2017-07-07'), DateTime.now

    HEADERS = {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    }
    WORKLOG_FIELDS = %w(author_name comment timeSpent)

    attr_reader :url, :login, :password

    def initialize(url, login, password)
      @url = URI(url)
      @login = login
      @password = password
    end

    def collect_worklogs(project, username, startdate, enddate)
      issues = issues(project, username, startdate, enddate)

      [].tap do |arr|
        issues.each do |issue|
          arr << issue_worklogs(issue, startdate, enddate)
        end
      end.flatten
    end

    def export_to_csv(worklogs)
      file = File.new("#{DateTime.now.strftime("%Y-%m-%d-%H-%M-%S")}.csv", 'w')

      CSV.open(file.path, 'wb') do |row|
        row << worklogs.first.keys
        worklogs.each { |worklog| row << worklog.values }
      end

      file.close
    end

    private

    def issues(project, username, start_date, enddate)
      start_date = start_date.strftime("%Y-%m-%d")
      enddate = enddate.strftime("%Y-%m-%d")

      jql = "project = #{project} and " \
            "assignee = #{username} and " \
            "created < #{enddate} and " \
            "updated > #{start_date} and " \
            "timespent > 0"

      params = { startAt: 0, jql: jql, fields: ['key'], maxResults: 1000 }
      url.path = '/rest/api/2/search'
      req = Net::HTTP::Post.new(url, HEADERS)
      req.body = params.to_json
      req.basic_auth login, password

      res = https.request(req)
      json_res = JSON.parse res.body
      json_res['issues']
    end

    def issue_worklogs(issue, startdate, enddate)
      issue_key = issue['key']
      url.path = "/rest/api/2/issue/#{issue_key}/worklog"
      req = Net::HTTP::Get.new(url, HEADERS)
      req.basic_auth login, password

      res = https.request(req)
      json_res = JSON.parse res.body

      filter_worklogs = filter_worklogs_by(json_res['worklogs'], startdate, enddate)
      serialize_worklogs(filter_worklogs, issue, WORKLOG_FIELDS)
    end

    def https
      http = Net::HTTP.new(url.hostname, url.port)
      http.use_ssl = true
      http
    end

    def filter_worklogs_by(worklogs, startdate, enddate)
      worklogs.select do |worklog|
        DateTime.parse(worklog['started']).between? startdate, enddate
      end
    end

    def serialize_worklogs(worklogs, issue, fields)
      worklogs.each do |worklog|
        worklog['author_name'] = worklog['author']['displayName']
        worklog.reject! { |key| !fields.include? key }
      end

      worklogs.map do |worklog|
        worklog.inject({}) { |hash, (key, value)| hash[key.to_sym] = value; hash[:issue_key] = issue['key']; hash }
      end
    end
  end
end
