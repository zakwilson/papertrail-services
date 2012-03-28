# encoding: utf-8
class Service::GeckoBoard < Service
  attr_writer :geckoboard

  def receive_logs
    raise_config_error 'Missing GeckoBoard API key' if settings[:token].to_s.empty?
    raise_config_error 'Missing GeckoBoard widget key' if settings[:widget_key].to_s.empty?

    deliver(settings[:token], settings[:widget_key], payload[:events].size)
  rescue
    raise_config_error "Error sending GeckoBoard message: #{$!}"
  end

  def deliver(token, widget_key, count)
    # http://docs.geckoboard.com/api/push.html
    geckoboard.post(URI.join("https://push.geckoboard.com/v1/send/", token).to_s,
      { :api_key => widget_key,
        :item => [
          { 
            :text => "",
            :value => value
          }
        ],
        :item => [
          { 
            :text => "",
            :value => value
          }
        ]
      }
    )
  end

  def geckoboard
    @geckoboard ||= Faraday.new
  end
end