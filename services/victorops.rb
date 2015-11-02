# coding: utf-8

class Service::Victorops < Service

  def receive_logs
    raise_config_error 'Missing Victorops API key (token)' if
      settings[:token].to_s.empty?
    raise_config_error 'Missing Victorops routing key' if
      settings[:routing_key].to_s.empty?

    events = payload[:events]

    hosts = events.collect { |e| e[:source_name] }.sort.uniq
    entity_id = payload[:saved_search][:name]
    if hosts.length < 5
        entity_id = "#{entity_id} (#{hosts.join(', ')})"
      else
        entity_id = "#{entity_id} (from #{hosts.length} hosts)"
    end

    message = events.collect { |item|
      syslog_format(item)
    }.join(", ")

    message = message[0..1020] + "..." if message.length > 1024

    if message.empty?
      raise_config_error "Could not process payload"
    end

    postdata = {
      entity_id: entity_id,
      monitoring_tool: "Papertrail",
      message_type: "INFO",
      timestamp: Time.iso8601(events[0][:received_at]).to_i,
      state_message: message,
    }
    
    url = "https://alert.victorops.com/integrations/generic/20131114/alert/#{settings[:token]}/#{settings[:routing_key]}"

    resp = http_post url, postdata.to_json

    unless resp.success?
      puts "victorops: #{resp.body.to_s}"

      raise_config_error "Failed to post to Victorops"
    end
  end


end
