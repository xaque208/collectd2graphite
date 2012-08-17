require 'sinatra'
require 'json'
require 'json2graphite'
require 'yaml'
#require 'pp'

# A module for converting collectd data into graphite data.

module Collectd2Graphite
  module_function

  # Accepts an array of hashes formatted by the collectd write_http plugin
  # Returns an array of hashes formatted to your liking, but in a structure
  # that can be used with the jsonn2graphite library

  def convert (array)

    # If we've not received an Array, something is broken.
    exit 127 unless array.is_a? Array

    # Initialize the object that we will return
    data_array = Array.new


    # Process each hash in the array
    array.each do |r|

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
      # Collectd formats the data object in a manner that takes some munging to
      # make sense of.  Plugins seem to format its data in different wats, so
      # consistency is tough.  The munging below is an attempt to hammer the
      # hash tree in a format that makes sense for your graphite installation.
      #
      # This process doesn't actually build a nested hash, which I think I
      # might prefer, but for now, it just formatts the string, so the result
      # when used with graphite should be identical.

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
      data = Hash.new
      data[:collectd] = Hash.new
      data[:collectd][host] = Hash.new
      if values.count > 1
        data[:collectd][host][superstring] = Hash.new
      end

      # Fill in the hash
      values.each_index do |i|
        if values.count > 1
          data[:collectd][host][superstring][r["dsnames"][i]] = r["values"][i]
        else
          data[:collectd][host][superstring] = r["values"][i]
        end
      end

      # Add our hash to the return object
      data_array << data

    end

    # Return the array of hashes we promised
    data_array
  end

end
