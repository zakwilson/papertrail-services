# encoding: utf-8
class Service::LibratoMetrics < Service
  def receive_logs
    # metrics[hostname][time]
    metrics = Hash.new do |h,k|
      h[k] = Hash.new do |i,l|
        i[l] = 0
      end
    end

    payload[:events].each do |event|
      time = Time.iso8601(event[:received_at]).to_i
      time = time.to_i - (time.to_i % 60)
      metrics[event[:source_name]][time] += 1
    end

    submit_metrics metrics
  end

  def receive_counts
    metrics = {}
    payload[:counts].each do |count|
      metrics[count[:source_name]] = count[:timeseries].
        each_with_object({}) do |(time, count), timeseries|
          timeseries[Time.iso8601(time).to_i] = count
        end
    end

    submit_metrics metrics
  end

  def submit_metrics(metrics)
    name   = settings[:name].gsub(/ +/, '_')
    client = Librato::Metrics::Client.new
    client.authenticate(settings[:user].to_s.strip, settings[:token].to_s.strip)
    client.agent_identifier("Papertrail-Services/1.0")

    queue = client.new_queue

    metrics.each do |source_name, hash|
      hash.each do |time, count|
        queue.add name => {
          :source       => source_name,
          :value        => count,
          :measure_time => time,
          :type         => 'gauge'
        }
      end
    end

    unless queue.empty?
      queue.submit
    end
  rescue Librato::Metrics::ClientError => e
    if e.message !~ /is too far in the past/
      raise_config_error("Error sending to Librato Metrics: #{e.message}")
    end
  rescue Librato::Metrics::CredentialsMissing, Librato::Metrics::Unauthorized
    raise_config_error("Error sending to Librato Metrics: Invalid email address or token")
  rescue Librato::Metrics::MetricsError => e
    raise_config_error("Error sending to Librato Metrics: #{e.message}")
  end
end
