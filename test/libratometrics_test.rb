require File.expand_path('../helper', __FILE__)

class LibratoMetricsTest < PapertrailServices::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_logs_no_metric
    Librato::Metrics::Client.any_instance.expects(:fetch).raises(Librato::Metrics::NotFound)
    Librato::Metrics::Queue.any_instance.expects(:submit)

    svc = service(:logs, { :name => 'gauge', :user => 'a@something.com', :token => 'abc' }, payload)

    @stubs.post '/v1/metrics.json' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end

  def test_logs
    Librato::Metrics::Client.any_instance.expects(:fetch).returns({ 'source1' => { :count => 1, :measure_time => Time.now.to_i }})
    Librato::Metrics::Queue.any_instance.expects(:submit)

    svc = service(:logs, { :name => 'gauge', :user => 'a@b.com', :token => 'abc' }, payload)

    @stubs.post '/v1/metrics.json' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end


  def test_unauthorized
    Librato::Metrics::Client.any_instance.expects(:fetch).raises(Librato::Metrics::Unauthorized)

    svc = service(:logs, { :name => 'gauge', :user => 'a@b.com', :token => 'abc' }, payload)

    assert_raise Service::ConfigurationError do
      svc.receive_logs
    end
  end

  def test_error
    Librato::Metrics::Client.any_instance.expects(:fetch).raises(Librato::Metrics::MetricsError)

    svc = service(:logs, { :name => 'gauge', :user => 'a@b.com', :token => 'abc' }, payload)

    assert_raise Service::ConfigurationError do
      svc.receive_logs
    end
  end

  def service(*args)
    super Service::LibratoMetrics, *args
  end
end
