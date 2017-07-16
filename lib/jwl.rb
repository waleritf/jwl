module JWL
  require 'net/http'
  require 'uri'
  require 'json'
  require 'cgi'
  require 'pry'
  require 'date'
  require 'optparse'
  require 'csv'

  require_relative 'jwl/client.rb'
  require_relative 'jwl/request.rb'
  require_relative 'jwl/collector.rb'
  require_relative 'jwl/csv_exporter.rb'

  options = {}.tap do |options|
    OptionParser.new do |parser|
      parser.on('-a', '--authencticate LOGIN:PASSWORD') do |a|
        a.split(':', 2).tap do |auth_data|
          options[:login] = auth_data[0]
          options[:password] = auth_data[1]
        end
      end

      parser.on('-j', '--jira-url URL') do |jira_url|
        options[:jira_url] = jira_url
      end

      parser.on('-u', '--username USERNAME') do |username|
        options[:username] = username
      end

      parser.on('-p', '--project PROJECT') do |project|
        options[:project] = project
      end

      parser.on('-i', '--interval DATE:DATE') do |interval|
        interval.split(':', 2).tap do |dates|
          options[:startdate] = DateTime.parse(dates[0])
          options[:enddate] = DateTime.parse(dates[1]) || DateTime.now
        end
      end
    end.parse!
  end

  Client.login = options[:login]
  Client.password = options[:password]
  Client.url = options[:jira_url]

  $stdout.puts('Collecting...')

  collector = Collector.new options[:project], options[:username],
                            options[:startdate], options[:enddate]
  issues = collector.issues
  worklogs = collector.worklogs issues

  CsvExporter.new.perform worklogs

  $stdout.puts('Done!')
end
