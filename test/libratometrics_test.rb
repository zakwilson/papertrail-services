require File.expand_path('../helper', __FILE__)

class LibratoMetricsTest < PapertrailServices::TestCase
  def test_removes_spaces_from_metric_name
    service = service(:logs, { :name  => 'very  wordy metric' }, payload)
    assert_equal 'very_wordy_metric', service.metric_name
  end

  def test_handles_nil_librato_user
    service = service(:logs, {}, payload)
    assert_equal '', service.librato_user
  end

  def test_cleans_whitespace_from_librato_user
    service = service(:logs, { :user  => ' arthur@dent.com  ' }, payload)
    assert_equal 'arthur@dent.com', service.librato_user
  end

  def test_handles_nil_librato_token
    service = service(:logs, {}, payload)
    assert_equal '', service.librato_token
  end

  def test_cleans_whitespace_from_librato_token
    service = service(:logs, { :token  => ' towel  ' }, payload)
    assert_equal 'towel', service.librato_token
  end

  def test_submits_logs_metrics
    expected_metrics = { 'alien'   => { 1311369000 => 2,
                                        1311370200 => 1,
                                        1311370800 => 1 },
                         'lullaby' => { 1311371400 => 1 }}

    service = service(:logs, service_settings, payload)
    service.expects(:submit_metrics).with(expected_metrics)
    service.receive_logs
  end

  def test_submits_counts_metrics
    expected_metrics = { 'alien'   => { 1311369000 => 2,
                                        1311370200 => 1,
                                        1311370800 => 1 },
                         'lullaby' => { 1311371400 => 1 }}

    service = service(:logs, service_settings, counts_payload)
    service.expects(:submit_metrics).with(expected_metrics)
    service.receive_counts
  end

  def test_submitting_metrics
    Librato::Metrics::Queue.any_instance.expects(:submit)

    metrics = { 'alien' => { Time.now.to_i => 2 }}
    service(:logs, service_settings, counts_payload).submit_metrics(metrics)
  end

  def test_submitting_no_metrics_sends_nothing
    Librato::Metrics::Queue.any_instance.expects(:submit).never

    metrics = {}
    service(:logs, service_settings, counts_payload).submit_metrics(metrics)
  end

  def test_submitting_no_measurements_sends_nothing
    Librato::Metrics::Queue.any_instance.expects(:submit).never

    metrics = { 'alien' => {}}
    service(:logs, service_settings, counts_payload).submit_metrics(metrics)
  end

  def test_submitting_metrics_unauthorized
    Librato::Metrics::Queue.any_instance.expects(:submit)
      .raises(Librato::Metrics::Unauthorized.new('unauthorized'))

    metrics = { 'alien' => { Time.now.to_i => 2 }}
    assert_raise Service::ConfigurationError do
      service(:logs, service_settings, counts_payload).submit_metrics(metrics)
    end
  end

  def test_submitting_metrics_error
    Librato::Metrics::Queue.any_instance.expects(:submit)
      .raises(Librato::Metrics::MetricsError)

    metrics = { 'alien' => { Time.now.to_i => 2 }}
    assert_raise Service::ConfigurationError do
      service(:logs, service_settings, counts_payload).submit_metrics(metrics)
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
