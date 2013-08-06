require 'sinatra'
require 'json'
require 'json2graphite'
require 'yaml'

# A module for converting collectd data into graphite data.
#

class Collectd2Graphite

  def initialize(rawdata)
    @rawdata = rawdata

    # Verify we have received an array
    unless rawdata.is_a? Array
      raise "received data is not an Array, and should be."
      exit 127
    end

  end

  #
  # Accepts an array of hashes formatted by the collectd write_http plugin
  # Returns an array of hashes formatted to your liking, but in a structure
  # that can be used with the jsonn2graphite library
  #
  # The format of the reeived data:
  #
  # [{
  #   "values": [1.16497e+08,3.91247e+08],
  #   "time":1288638055,
  #   "interval":10,
  #   "host":"collectd_restmq_server",
  #   "plugin":"df",
  #   "plugin_instance":"",
  #   "type":"df",
  #   "type_instance":"boot"}
  # }]
  #

  def raw_convert (array)

    # If we've not received an Array, something is broken.
    exit 127 unless array.is_a? Array

    # Initialize the object that we will return
    data_array = Array.new

    # Process each hash in the array
    array.each do |r|

      # initialize that data object that will return
      data = Hash.new

      # Pull out the useful bits from the raw collectd hash that we have received
      time            = r["time"].to_i
      values          = r["values"]
      host            = r["host"].gsub('.', '_')
      type            = r["type"]
      type_instance   = r["type_instance"]
      plugin          = r["plugin"]
      plugin_instance = r["plugin_instance"]
      pluginstring    = [r["plugin"], ["plugin_instance"]].join('-')

      # Set the time the data was created
      data[:time] = time

      # Set the pluginstring for better target specification
      #
      # Collectd formats the data object in a manner that takes some munging to
      # make sense of.  
      #
      # This process doesn't actually build a nested hash, which I think I
      # might prefer, but for now, it just formatts the string, so the result
      # when used with graphite should be identical.
      #

      #plugindata = Hash.new
      #puts 'r is:'
      #pp r
      #plugindata = ["type","type_instance","plugin", "plugin_instance"].inject({}) {|hash, element|
      #  #next if r[element].empty?
      #  #puts "what is in element: #{element}"
      #  #puts "is r[element] empty?"
      #  #puts r[element].empty?
      #  #puts "element is: #{element}"
      #  #puts "r[element] is #{r[element]}"
      #  #hash[r[element]] = {} unless r[element].empty?
      #  #puts "hash is now: "
      #  #pp hash
      #  #puts hash[r[element]]
      #  #hash[r[element]] = r["#{element}"] unless r[element].empty?
      #  hash = hash[r[element]] unless r[element].empty?
      #  hash
      #}

      #pp plugindata

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

      # Here is the string that will actually be used in the output
      superstring = [pluginstring,typestring].join('.')

      # Create some empty hashes to work with
      data[:collectd] = Hash.new
      data[:collectd][host] = Hash.new

      # if we are working with multiple values, we should handle specially
      if values.count > 1
        data[:collectd][host][superstring] = Hash.new
      end

      # Load the hash with actual data
      values.each_index do |i|
        if values.count > 1
          data[:collectd][host][superstring][r["dsnames"][i]] = r["values"][i]
        else
          data[:collectd][host][superstring] = r["values"][i]
        end
      end

      # Add our hash to the method return object
      data_array << data

    end

    # Return the array of hashes we promised
    data_array
  end

end

