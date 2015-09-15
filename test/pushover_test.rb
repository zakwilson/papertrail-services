require File.expand_path('../helper', __FILE__)

require 'fakeweb'

class PushoverTest < PapertrailServices::TestCase

  def setup
    FakeWeb.register_uri(:post, "https://api.pushover.net/1/messages.json",
                         :body => { :status => 1 }.to_json,
                         :content_type => "application/json")
  end

  def teardown
    FakeWeb.clean_registry
  end
  
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

  end

  def service(*args)
    super Service::Pushover, *args
  end
  
end
