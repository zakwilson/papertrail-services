# encoding: utf-8

class Service::Boundary < Service
  def receive_logs
    raise_config_error 'Missing Organization ID' if settings[:orgid].to_s.empty?
    raise_config_error 'Missing API Key' if settings[:token].to_s.empty?

    Scrolls::Log.context[:boundary_orgid] = settings[:orgid].to_s.strip

    return if payload[:events].blank?

    # Setup HTTP connection
    http.basic_auth settings[:token].to_s.strip, ''
    http.headers['content-type'] = 'application/json'

    payload[:events].each_with_index do |event, idx|
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

      Metriks.timer('papertrail_services.boundary.post').time do
        count = 0

        while true
          resp = http_post "https://api.boundary.com/#{settings[:orgid].to_s.strip}/events", annotation.to_json

          if resp.status == 429
            count += 1
            Scrolls.log(:idx => idx, :status => resp.status, :body => resp.body, :count => count)

            sleep 1
            next
          end

          unless resp.success?
            Scrolls.log(:idx => idx, :status => resp.status, :body => resp.body)
          end

          break
        end
      end
    end
  rescue ::PapertrailServices::Service::TimeoutError => e
    Scrolls.log_exception({:from => :boundary}, e)
    raise
  end
end
