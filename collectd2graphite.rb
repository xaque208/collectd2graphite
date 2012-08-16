#! /usr/bin/env ruby

require 'sinatra'
#require 'pp'
require 'json'
require 'json2graphite'
require 'yaml'

config = YAML::load(File.read('etc/c2g.yaml'))

set :graphiteserver, config[:server]
set :graphiteport, config[:port]
set :port, 47654

post '/post-collectd' do
  request.body.rewind  # in case someone already read it
  received = JSON.parse request.body.read
  received.each do |r|
    #pp r

    # Values retrieved from the raw json
    time            = r["time"].to_i
    values          = r["values"]
    host            = r["host"].gsub('.', '_')
    type            = r["type"]
    type_instance   = r["type_instance"]
    plugin          = r["plugin"]
    plugin_instance = r["plugin_instance"]
    pluginstring    = [r["plugin"], ["plugin_instance"]].join('-')

    # Set the pluginstring for better target specification
    #
    # If the plugin_instance contains something, ues it in the plugin string
    # if not, use the type_instance
    if plugin_instance.empty?
      if type_instance.empty?
        # Neither plguin_instance nor type_instance exist
        typestring   = r["type"]
        pluginstring = r["plugin"]
      else
        # Plugin_instance set while type_instance is not
        typestring   = r["type"]
        pluginstring = [r["plugin"],r["type_instance"]].join('-')
      end
    else
      if type_instance.empty?
        # type_instance not set, while plugin_instance is set
        typestring   = r["type"]
        pluginstring = [r["plugin"],r["plugin_instance"]].join('-')
      else
        # Both instance for plugin and type exist
        typestring   = [r["type"],r["type_instance"]].join('-')
        pluginstring = [r["plugin"],r["plugin_instance"]].join('-')
      end
    end
    superstring = [pluginstring,typestring].join('.')

    # Set the typestring for better target specification
    #if type_instance.empty?
    #else
    #end


    # Create some empty hashes to work with
    data = Hash.new
    data[:agents] = Hash.new
    data[:agents][host] = Hash.new
    if values.count > 1
      data[:agents][host][superstring] = Hash.new
    end

    # Fill in the hash
    values.each_index do |i|
      if values.count > 1
        data[:agents][host][superstring][r["dsnames"][i]] = r["values"][i]
      else
        data[:agents][host][superstring] = r["values"][i]
      end
    end

    # Convert the hash to graphite formatted data
    processed = Json2Graphite.get_graphite(data, time)
    #puts processed
    s = TCPSocket.open(settings.graphiteserver, settings.graphiteport)
    processed.each do |line|
      s.puts(line)
    end
    s.close
  end
end

