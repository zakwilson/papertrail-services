require File.expand_path('../helper', __FILE__)

class DatadogTest < PapertrailServices::TestCase
  def test_config
    svc = service(:logs, {}.with_indifferent_access, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }

    svc = service(:logs, { 'api_key' => "foobar" }.with_indifferent_access, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }

    svc = service(:logs, { 'metric' => "foobar" }.with_indifferent_access, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }
  end

  def test_logs
    svc = service(:logs, { 'api_key' => 'foobar', "metric" => "foo.bar"}.with_indifferent_access, payload)

    http_stubs.post "/api/v1/series" do |env|
      [200, {}, ""]
    end

    svc.receive_logs
  end

  def service(*args)
    super Service::Datadog, *args
  end
end
