require File.expand_path('../helper', __FILE__)

class LibratoMetricsTest < PapertrailServices::TestCase
  def test_logs
    Librato::Metrics::Queue.any_instance.expects(:submit)

    svc = service(:logs, { :name => 'gauge', :user => 'a@b.com', :token => 'abc' }, shifted_logs_payload)

    http_stubs.post '/v1/metrics.json' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end

  def test_logs_unauthorized
    Librato::Metrics::Queue.any_instance.expects(:submit).raises(Librato::Metrics::Unauthorized.new('unauthorized'))

    svc = service(:logs, { :name => 'gauge', :user => 'a@b.com', :token => 'abc' }, shifted_logs_payload)

    assert_raise Service::ConfigurationError do
      svc.receive_logs
    end
  end

  def test_logs_error
    Librato::Metrics::Queue.any_instance.expects(:submit).raises(Librato::Metrics::MetricsError)

    svc = service(:logs, { :name => 'gauge', :user => 'a@b.com', :token => 'abc' }, shifted_logs_payload)

    assert_raise Service::ConfigurationError do
      svc.receive_logs
    end
  end

  def test_counts
    Librato::Metrics::Queue.any_instance.expects(:submit)

    svc = service(:logs, { :name => 'gauge', :user => 'a@b.com', :token => 'abc' }, shifted_counts_payload)

    http_stubs.post '/v1/metrics.json' do |env|
      [200, {}, '']
    end

    svc.receive_counts
  end

  def test_counts_unauthorized
    Librato::Metrics::Queue.any_instance.expects(:submit).raises(Librato::Metrics::Unauthorized.new('unauthorized'))

    svc = service(:logs, { :name => 'gauge', :user => 'a@b.com', :token => 'abc' }, shifted_counts_payload)

    assert_raise Service::ConfigurationError do
      svc.receive_counts
    end
  end

  def test_counts_error
    Librato::Metrics::Queue.any_instance.expects(:submit).raises(Librato::Metrics::MetricsError)

    svc = service(:logs, { :name => 'gauge', :user => 'a@b.com', :token => 'abc' }, shifted_counts_payload)

    assert_raise Service::ConfigurationError do
      svc.receive_counts
    end
  end

  # Shift time stamps to within the acceptable offset from
  # real time. This should try to keep the uniqueness of times
  # whenever possible (except when a factor of the max offset).
  def shifted_time(time, now)
    max_real_offset = 3600 * 24
    shifted_time    = Time.iso8601(time)
    shifted_time    = shifted_time.to_i - (shifted_time.to_i % 60)
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

  def service(*args)
    super Service::LibratoMetrics, *args
  end
end
