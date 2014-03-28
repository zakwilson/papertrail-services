# encoding: utf-8
class Service::Slack < Service
  def receive_logs
    raise_config_error 'Missing slack webhook' if settings[:slack_url].to_s.empty?
    raise_config_error "Slack webhook must point to slack.com" unless settings[:slack_url].to_s.match(/slack\.com/)
    
    message = %{"#{payload[:saved_search][:name]}" search found #{pluralize(payload[:events].length, 'match')} — #{payload[:saved_search][:html_search_url]}}
    content = payload[:events].collect { |event| syslog_format(event) }.join("\n")
    
    # Provide some basic escaping of ``` in messages
    content = content.gsub('```', '` ` `')

    attachment = "```" + content + "```"

    data = {
      :text => message,
      :username => 'papertrail',
      :icon_url => 'https://0.gravatar.com/avatar/e52fd880666c3708c72496114a64dec0?s=140',
      :attachments => [
        {
          :text => attachment,
          :mrkdwn_in => ["text"]
        }
      ]
    }
    
    http.headers['content-type'] = 'application/json'
    response = http_post settings[:slack_url], data.to_json

    unless response.success?
      puts "slack: #{payload[:saved_search][:id]}: #{response.status}: #{response.body}"
      raise_config_error "Could not submit logs"
    end
  end
end