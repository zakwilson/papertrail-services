require File.expand_path('../helper', __FILE__)

class LibratoMetricsTest < PapertrailServices::TestCase
  def test_logs
    Librato::Metrics::Queue.any_instance.expects(:submit)

    svc = service(:logs, { :name => 'gauge', :user => 'a@b.com', :token => 'abc' }, shifted_payload)

    http_stubs.post '/v1/metrics.json' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end


  def test_unauthorized
    Librato::Metrics::Queue.any_instance.expects(:submit).raises(Librato::Metrics::Unauthorized.new('unauthorized'))

    svc = service(:logs, { :name => 'gauge', :user => 'a@b.com', :token => 'abc' }, shifted_payload)

    assert_raise Service::ConfigurationError do
      svc.receive_logs
    end
  end

  def test_error
    Librato::Metrics::Queue.any_instance.expects(:submit).raises(Librato::Metrics::MetricsError)

    svc = service(:logs, { :name => 'gauge', :user => 'a@b.com', :token => 'abc' }, shifted_payload)

    assert_raise Service::ConfigurationError do
      svc.receive_logs
    end
  end

  # Shift time stamps to within the acceptable offset from
  # real time. This should try to keep the uniqueness of times
  # whenever possible (except when a factor of the max offset).
  def shifted_payload
    now = Time.now.tv_sec
    max_real_offset = 3600 * 24

    shifted = counts_payload.dup
    shifted[:counts].each do |count|
      count[:timeseries] = count[:timeseries].
        each_with_object({}) do |(time, count), timeseries|
          time  = Time.iso8601(time)
          time  = time.to_i - (time.to_i % 60)
          delta = now - time
          shifted_time = Time.at(now - (delta % max_real_offset)).iso8601
          timeseries[shifted_time] = count
        end
    end

    shifted
  end

  def service(*args)
    super Service::LibratoMetrics, *args
  end
end
