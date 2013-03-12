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

    data = counts.map do |time, count|
      {
        :stat => settings[:stat],
        :count => count,
        :t => time
      }
    end

    resp = http_post "http://api.stathat.com/ez" do |req|
      req.headers[:content_type] = 'application/json'
      req.body = {
        :ezkey => settings[:ezkey],
        :data => data
      }.to_json
    end

    unless resp.success?
      puts "stathat: #{payload[:saved_search][:id]}: #{resp.status}: #{resp.body}"
      raise_config_error "Could not submit metrics"
    end
  rescue Faraday::Error::ConnectionFailed
    raise_config_error "Connection refused"
  end
end
