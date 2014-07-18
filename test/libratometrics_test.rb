require File.expand_path('../helper', __FILE__)

class LibratoMetricsTest < PapertrailServices::TestCase
  def test_submits_logs_metrics
    expected_metrics = { 'alien'   => { 1311369000 => 2,
                                        1311370200 => 1,
                                        1311370800 => 1 },
                         'lullaby' => { 1311371400 => 1 }}
    Service::LibratoMetrics::MetricsQueue.expects(:submit_metrics)
      .with(expected_metrics, service_settings)

    service(:logs, service_settings, payload).receive_logs
  end

  def test_submits_counts_metrics
    expected_metrics = { 'alien'   => { 1311369000 => 2,
                                        1311370200 => 1,
                                        1311370800 => 1 },
                         'lullaby' => { 1311371400 => 1 }}
    Service::LibratoMetrics::MetricsQueue.expects(:submit_metrics)
      .with(expected_metrics, service_settings)

    service(:logs, service_settings, counts_payload).receive_counts
  end

  def test_submitting_metrics
    Librato::Metrics::Queue.any_instance.expects(:submit)

    metrics = { 'alien' => { Time.now.to_i => 2 }}
    Service::LibratoMetrics::MetricsQueue.
      submit_metrics(metrics, service_settings)
  end

  def test_submitting_metrics_unauthorized
    Librato::Metrics::Queue.any_instance.expects(:submit)
      .raises(Librato::Metrics::Unauthorized.new('unauthorized'))

    assert_raise Service::ConfigurationError do
      metrics = { 'alien' => { Time.now.to_i => 2 }}
      Service::LibratoMetrics::MetricsQueue.
        submit_metrics(metrics, service_settings)
    end
  end

  def test_submitting_metrics_error
    Librato::Metrics::Queue.any_instance.expects(:submit)
      .raises(Librato::Metrics::MetricsError)

    assert_raise Service::ConfigurationError do
      metrics = { 'alien' => { Time.now.to_i => 2 }}
      Service::LibratoMetrics::MetricsQueue.
        submit_metrics(metrics, service_settings)
    end
  end


  def service(*args)
    super Service::LibratoMetrics, *args
  end

  def service_settings
    { :name  => 'gauge',
      :user  => 'arthur@dent.com',
      :token => 'towel' }
  end

  # Shift time stamps to within the acceptable offset from
  # real time. This should try to keep the uniqueness of times
  # whenever possible (except when a factor of the max offset).
  def shifted_time(time, now)
    max_real_offset = 3600 * 24
    shifted_time    = Time.iso8601(time).to_i
    delta           = now - shifted_time
    Time.at(now - (delta % max_real_offset)).iso8601
  end

  def shifted_logs_payload
    now     = Time.now.tv_sec
    shifted = payload.dup
    shifted[:events].each do |event|
      event[:received_at] = shifted_time(event[:received_at], now)
    end

    shifted
  end

  def shifted_counts_payload
    now     = Time.now.tv_sec
    shifted = counts_payload.dup
    shifted[:counts].each do |count|
      count[:timeseries] = count[:timeseries].
        each_with_object({}) do |(time, count), timeseries|
          timeseries[shifted_time(time, now)] = count
        end
    end

    shifted
  end
end
