# coding: utf-8

class Service::Zapier < Service
  attr_writer :zapier

  def receive_logs
    raise_config_error 'Missing Zapier URL' if
      settings[:zapier_url].to_s.empty?

    events = payload[:events]
    
    # TODO - message length limit of 5mb

    postdata = payload

    http.headers['content-type'] = 'application/json'
    resp = http_post settings[:zapier_url], postdata.to_json
    
    unless resp.status == 200
      puts "zapier: #{resp.to_s}"

      raise_config_error "Failed to post to Zapier"
    end
  end

  
  def zapier
    
  end
  
end
