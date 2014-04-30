require File.expand_path('../helper', __FILE__)

class SlackTest < PapertrailServices::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_logs
    svc = service(:logs, { :slack_url => "https://site.slack.com/services/hooks/incoming-webhook?token=aaaa" }, payload)

    @stubs.post '/services/hooks/incoming-webhook' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end

  def test_long_logs
    long_payload = payload.dup
    100.times do
      long_payload[:events] += payload[:events]
    end

    svc = service(:logs, { :slack_url => "https://site.slack.com/services/hooks/incoming-webhook?token=aaaa" }, long_payload)

    @stubs.post '/services/hooks/incoming-webhook' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end


  def service(*args)
    super Service::Slack, *args
  end
end