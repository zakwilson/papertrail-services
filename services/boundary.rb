# encoding: utf-8

class Service::Boundary < Service
  def receive_logs
    raise_config_error 'Missing Organization ID' if settings[:orgid].to_s.empty?
    raise_config_error 'Missing API Key' if settings[:token].to_s.empty?

    return if payload[:events].blank?

    # Setup HTTP connection
    http.basic_auth settings[:token].to_s.strip, ''
    http.headers['content-type'] = 'application/json'

    payload[:events].each do |event|
      message = event[:message]

      if message.length > 255
        message = message[0..251] + '...'
      end

      annotation = {
        :title => settings[:title].presence || payload[:saved_search][:name],
        :message => message,
        :fingerprintFields => %w(@title @message),
        :receivedAt => Time.iso8601(event[:received_at]).to_i * 1000,
        :sender => {
          :ref => 'Papertrail',
          :type => 'Papertrail'
        },
        :tags => settings[:tags].to_s.split(/, */).compact + [ event[:source_name] ],
        :source => {
          :ref => event[:source_name],
          :type => 'host'
        },
        :properties => {
          'Papertrail Logs' => [
            {
              :href => "#{payload[:saved_search][:html_search_url]}?centered_on_id=#{event[:id]}",
            }
          ]
        }
      }

      annotation[:tags].uniq!

      resp = http_post "https://api.boundary.com/#{settings[:orgid].to_s.strip}/events", annotation.to_json
      unless resp.success?
        puts "boundary: #{payload[:saved_search][:id]}: #{resp.status}: #{resp.body}"
      end
    end
  rescue ::PapertrailServices::Service::TimeoutError
    puts "boundary: #{payload[:saved_search][:id]}: #{settings[:orgid].to_s.strip}: timeout"
    raise
  end
end
