# encoding: utf-8
class Service::LibratoMetrics < Service
  def receive_logs
    default_metrics = Hash.new do |metrics, name|
      metrics[name] = default_timeseries
    end

    metrics = payload[:events].
      each_with_object(default_metrics) do |event, metrics|
        rounded = round_to_minute(event[:received_at])
        metrics[event[:source_name]][rounded] += 1
      end

    MetricsQueue.submit_metrics metrics, settings
  end

  def receive_counts
    metrics = payload[:counts].each_with_object({}) do |count, metrics|
      metrics[count[:source_name]] = count[:timeseries].
        each_with_object(default_timeseries) do |(time, count), timeseries|
          timeseries[round_to_minute(time)] += count
        end
    end

    MetricsQueue.submit_metrics metrics, settings
  end

  def default_timeseries
    Hash.new do |timeseries, time|
      timeseries[time] = 0
    end
  end

  def round_to_minute(time)
    time = Time.iso8601(time).to_i
    time - (time % 60)
  end

  class MetricsQueue
    def self.submit_metrics(metrics, settings)
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
        raise Service::ConfigurationError,
          "Error sending to Librato Metrics: #{e.message}"
      end
    rescue Librato::Metrics::CredentialsMissing, Librato::Metrics::Unauthorized
      raise Service::ConfigurationError,
        "Error sending to Librato Metrics: Invalid email address or token"
    rescue Librato::Metrics::MetricsError => e
      raise Service::ConfigurationError,
        "Error sending to Librato Metrics: #{e.message}"
    end
  end
end
