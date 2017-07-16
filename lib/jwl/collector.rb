module JWL
  class Collector
    attr_reader :project, :username, :startdate, :enddate

    def initialize(project, username, startdate, enddate)
      @project = project
      @username = username
      @startdate = startdate
      @enddate = enddate
    end

    def issues
      jql = "project = #{project} and " \
            "assignee = #{username} and " \
            "created < #{enddate.strftime("%Y-%m-%d")} and " \
            "updated > #{startdate.strftime("%Y-%m-%d")} and " \
            "timespent > 0"

      body = { startAt: 0, jql: jql, fields: ['key'], maxResults: 1000 }

      Request.new(:post, Client.url, body).issues
    end

    def worklogs(issues)
      [].tap do |arr|
        issues.each do |issue|
          arr << issue_worklogs(issue)
        end
      end.flatten
    end

    private

    # TODO refator this
    def issue_worklogs(issue)
      worklogs = Request.new(:get, Client.url).worklogs(issue['key'])

      filtered_worklogs = worklogs.select do |worklog|
        DateTime.parse(worklog['started']).between?(startdate, enddate) &&
        worklog['author']['key'].eql?(username)
      end

      serialized_worklogs = filtered_worklogs.each do |worklog|
        worklog['author_name'] = worklog['author']['displayName']
        worklog.reject! { |key| !%w(author_name comment timeSpent).include? key }
      end

      serialized_worklogs.map do |worklog|
        worklog.inject({}) { |hash, (key, value)| hash[key.to_sym] = value; hash[:issue_key] = issue['key']; hash }
      end
    end
  end
end
