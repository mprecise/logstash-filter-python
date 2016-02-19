# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "logstash/timestamp"
require "logstash/util"
require "rubypython"


class LogStash::Filters::Python < LogStash::Filters::Base

  TIMESTAMP = "@timestamp"

  config_name "python"

  config :python_exe, :validate => :string, :required => false
  config :python_lib, :validate => :string, :required => false
  
  config :env_python_path, :validate => :string, :required => true
  config :module_name, :validate => :string, :required => true
  config :function_name, :validate => :string, :required => true

  # Example using execbeat as input:
  #    "[exec][stdout]" gives a string
  #    "[exec]" gives a hash
  config :field, :validate => :string, :required => false

  # If specified, result will be stored in this event field.
  # If not specified, result will be merged into the root of the
  # event, overwriting any existing root keys with the same name. In
  # the latter case, the result must be a hash.
  config :target, :validate => :string, :required => false

  config :tag_on_failure, :validate => :array, :default => ["_pythonexception"]

  public
  def initialize(params)
    super(params)
    @logger.debug("initializing python filter plugin")
    @threadsafe = false
  end

  public
  def register
    @logger.debug("registering python filter plugin")

    ENV["PYTHONPATH"] = @env_python_path
    RubyPython.start(python_exe: @python_exe, python_lib: @python_lib)
    @py_utils_module = RubyPython.import("utils")
    @py_module = RubyPython.import(@module_name)

    # Verify the specified module-level function exists.
    pyfunction = @py_utils_module.get_attr(@py_module, @function_name)
  end

  public
  def close
    @logger.debug("closing python filter plugin")
    RubyPython.stop
  end

  public
  def filter(event)
    begin
      if @field.nil?
        success = process_all_fields(event)
      else
        success = process_single_field(event)
      end

      if success
        filter_matched(event)
      end
    rescue Exception => e
      @logger.error("Ruby exception occurred: #{e}")
      @tag_on_failure.each{|tag| event.tag(tag)}
    end
  end # def filter

  private
  def process_all_fields(event)
    fields = event.to_hash_with_metadata()
    fields.each do |k, v|
      if k == TIMESTAMP && v.is_a?(LogStash::Timestamp)
        fields[k] = v.to_iso8601()
      end
    end

    begin
      fields = @py_utils_module.call_function(@py_module, @function_name, fields)
    rescue Exception => e
      @logger.error("Python exception occurred: #{e}")
      @tag_on_failure.each{|tag| event.tag(tag)}
      return false
    end

    fields = fields.rubify

    unless @target.nil?
      event[@target] = fields
      return true
    end

    fields.each do |k, v|
      if k == TIMESTAMP && v.is_a?(String)
        v = LogStash::Timestamp.parse_iso8601(v)
      end
      event[k] = v
    end

    return true
  end # def process_all_fields


  private
  def process_single_field(event)
    field = event.sprintf(@field)

    begin
      fields = @py_utils_module.call_function(@py_module, @function_name, event[field])
    rescue Exception => e
      @logger.error("Python exception occurred: #{e}")
      @tag_on_failure.each{|tag| event.tag(tag)}
      return false
    end

    fields = fields.rubify

    unless @target.nil?
      event[@target] = fields
      return true
    end

    if fields.is_a?(Hash)
      fields.each do |k, v|
        if k == TIMESTAMP && v.is_a?(String)
          v = LogStash::Timestamp.parse_iso8601(v)
        end
        event[k] = v
      end
    else
      @logger.error("Ruby exception occurred: Cannot merge a #{fields.class} into an event. Specify a target.")
      @tag_on_failure.each{|tag| event.tag(tag)}
      return false
    end

    return true
  end # def process_single_field

end # class LogStash::Filters::Python

