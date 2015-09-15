require File.expand_path('../helper', __FILE__)

class PushoverTest < PapertrailServices::TestCase
  def test_config
    svc = service(:logs, {:pushover_app_token => 'a sample token'}, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }

    svc = service(:logs, {:pushover_user_token => 'a different token'}, payload)
    assert_raises(PapertrailServices::Service::ConfigurationError) { svc.receive_logs }
  end
  
  def test_logs
    svc = service(:logs, {:pushover_app_token => 'a sample token',
                          :pushover_user_token => 'a different token'},
                  payload)

    http_stubs.post '/services/hooks/incoming-webhook' do |env|
      [200, {}, '']
    end

    # svc.receive_logs
    # TODO - stub the actual post
  end

  def service(*args)
    super Service::Pushover, *args
  end
  
end
