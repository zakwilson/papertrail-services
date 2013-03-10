# encoding: utf-8
class Service::Stathat < Service
  def receive_logs
    raise_config_error 'Missing EZ Key' if settings[:ezkey].to_s.empty?
    raise_config_error 'Missing stat name' if settings[:stat].to_s.empty?

    counts = Hash.new do |h,k|
      h[k] = 0
    end

    payload[:events].each do |event|
      time = Time.iso8601(event[:received_at]).to_i
      counts[time] += 1
    end

    counts.each do |time, count|
      http_post "http://api.stathat.com/ez" do |req|
        req.body = {
          :ezkey => settings[:ezkey],
          :stat => settings[:stat],
          :count => count,
          :t => time
        }
    end
  rescue Faraday::Error::ConnectionFailed
    raise_config_error "Connection refused"
  end
end
