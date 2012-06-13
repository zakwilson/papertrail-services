# encoding: utf-8

# Initial implementation by Mike Heffner:
#  https://github.com/librato/papertrail_pagerduty_webhook
class Service::Boundary < Service
  def receive_logs
    return if payload[:events].blank?

    annotation = {
      :type => settings[:title].presence || payload[:saved_search][:name],
      :subtype => payload[:events].first[:message],
      :start_time => Time.zone.parse(payload[:events].first[:received_at]).to_i,
      :end_time => Time.zone.parse(payload[:events].last[:received_at]).to_i,
      :tags => settings[:tags].to_s.split(/, */).compact,
      :links => [
        {
          :rel => 'papertrail',
          :href => "#{payload[:saved_search][:html_search_url]}?centered_on_id=#{payload[:events].first[:id]}",
          :node => 'Start of log messages'
        }
      ]
    }
    
    include_host_tags = settings[:include_host_tags].to_i == 1
    
    if include_host_tags
      annotation[:tags] += payload[:events].map { |e| e[:source_name] }.uniq.sort
    end
    
    annotation[:tags].uniq!

    # Setup HTTP connection
    http.basic_auth settings[:token], ''
    http.headers['content-type'] = 'application/json'

    http_post "https://api.boundary.com/#{settings[:orgid]}/annotations", annotation.to_json
  end
end
