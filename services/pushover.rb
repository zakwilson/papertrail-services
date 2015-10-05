# coding: utf-8

require 'rushover'

class Service::Pushover < Service
  attr_writer :pushover

  def receive_logs
    raise_config_error 'Missing pushover app token' if
      settings[:token].to_s.empty?
    raise_config_error 'Missing pushover user token' if
      settings[:user_key].to_s.empty?

    message = payload[:events].map { |item|
      item[:message]
    }.join("\n")

    message = message[0..1020] + "..." if message.length > 1024

    if message.empty?
      raise_config_error "Could not process payload"
    end

    resp = pushover.notify(settings[:user_key],
                           message,
                           {title: payload[:saved_search][:name]})

    unless resp.ok?
      puts "pushover: #{resp.to_s}"

      raise_config_error "Failed to post to Pushover"
    end
  end

  
  def pushover
    @pushover ||= Rushover::Client.new(settings[:token])
  end
  
end
