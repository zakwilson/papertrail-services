require File.expand_path('../helper', __FILE__)

class BoundaryTest < PapertrailServices::TestCase
  def test_logs
    svc = service(:logs, { :type => 'k', :tags => 'one, two', :orgid => 'a', :token => 'b' }, payload)

    http_stubs.post '/a/events' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end

  def test_logs_with_include_host_tags
    svc = service(:logs, { :type => 'k', :tags => 'one, two', :orgid => 'a', :token => 'b', :include_host_tags => 1 }, payload)

    http_stubs.post '/a/events' do |env|
      [200, {}, '']
    end

    svc.receive_logs
  end


  def service(*args)
    super Service::Boundary, *args
  end
end
