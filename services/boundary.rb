# encoding: utf-8

class Service::Boundary < Service
  def receive_logs
    raise_config_error 'Missing Organization ID' if settings[:orgid].to_s.empty?
    raise_config_error 'Missing API Key' if settings[:token].to_s.empty?

    return if payload[:events].blank?

    annotation = {
      :title => settings[:title].presence || payload[:saved_search][:name],
      :message => payload[:events].first[:message],
      :receivedAt => Time.iso8601(payload[:events].first[:received_at]).to_i,
      :sender => 'Papertrail',
      :tags => settings[:tags].to_s.split(/, */).compact,
      :source => {
        :ref => payload[:events].first[:source_name],
        :type => 'host'
      },
      :links => [
        {
          :rel => 'papertrail',
          :href => "#{payload[:saved_search][:html_search_url]}?centered_on_id=#{payload[:events].first[:id]}",
          :note => 'Start of log messages'
        }
      ]
    }
    
    annotation[:tags] += payload[:events].map { |e| e[:source_name] }.uniq.sort
    annotation[:tags].uniq!

    # Setup HTTP connection
    http.basic_auth settings[:token].to_s.strip, ''
    http.headers['content-type'] = 'application/json'

    http_post "https://api.boundary.com/#{settings[:orgid].to_s.strip}/events", annotation.to_json
  end
end
