require File.expand_path('../helper', __FILE__)
require 'aws-sdk'

class CloudWatchTest < PapertrailServices::TestCase

  def setup
    @common_settings = { aws_access_key_id: '123',
                         aws_secret_access_key: '456',
                         namespace: "papertrail-test",
                         metric_name: "test-metric",
                       }
    new_payload = payload # payload has some magic and can't be modified
    new_payload[:events].each do |e|
      # Cloudwatch demands recent dates
      e[:received_at] = (Time.now - rand(0..100)).iso8601
    end
        
    @svc = service(:logs,
                   metric_regex_params(3, :dimension => 'Region=West;Element=page').merge(@common_settings),
                   new_payload)
  end

  def test_size
    assert_raises(PapertrailServices::Service::ConfigurationError) {
      @svc.prepare_post_data(@svc.payload[:events], size_limit=8)
    }
  end

  def test_logs
    AWS.stub!
    @svc.receive_logs
  end

  def service(*args)
    super Service::CloudWatch, *args
  end

  def metric_regex_params(count, metric_options = { :regex => 'abc' })
    metrics = {}
    count.times.map do |i|
      metrics[i] = { :name => "MetricName#{i}" }
      metrics[i].merge!(metric_options)
    end
    { :metric => metrics }
  end
end
