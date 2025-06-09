# frozen_string_literal: true

module XmpToolkitRuby
  require_relative "xmp_file_open_flags"

  class XmpFile
    attr_reader :file_path, :open_flags

    class << self
      def register_namespace(namespace, suggested_prefix)
        warn("XmpToolkitRuby not initialized default Plugin paths #{XmpToolkitRuby::PLUGINS_PATH} will be used") unless XmpToolkitRuby::XmpToolkit.initialized?

        XmpWrapper.register_namespace(namespace, suggested_prefix)
      end

      def with_xmp_file(file_path, open_flags: XmpFileOpenFlags::OPEN_FOR_READ, plugin_path: XmpToolkitRuby::PLUGINS_PATH, auto_terminate_toolkit: true)
        XmpToolkitRuby.check_file! file_path, need_to_read: true, need_to_write: XmpFileOpenFlags.contains?(open_flags, :open_for_update)

        XmpToolkitRuby::XmpToolkit.initialize_xmp(plugin_path) unless XmpToolkitRuby.sdk_initialized?

        xmp_file = new(file_path, open_flags: open_flags)
        xmp_file.open
        yield xmp_file
      ensure
        xmp_file&.write if XmpFileOpenFlags.contains?(xmp_file.open_flags, :open_for_update)
        xmp_file&.close

        XmpToolkitRuby::XmpToolkit.terminate if auto_terminate_toolkit && XmpToolkitRuby.sdk_initialized?
      end
    end

    def initialize(file_path, open_flags: XmpFileOpenFlags::OPEN_FOR_READ)
      @file_path = file_path.to_s
      @open_flags = open_flags
      @open = false
      @xmp_wrapper = XmpWrapper.new
    end

    def open
      return if open?

      raise ArgumentError, "File path must be a String or Pathname" unless File.readable?(@file_path)

      warn("XmpToolkitRuby not initialized default Plugin paths #{XmpToolkitRuby::PLUGINS_PATH} will be used") unless XmpToolkitRuby::XmpToolkit.initialized?

      @xmp_wrapper.open(file_path, open_flags).tap { @open = true }
    end

    def open?
      @open
    end

    def file_info
      @file_info ||= begin
                       info = @xmp_wrapper.file_info

                       handler_flags = info["handler_flags"]
                       handler_flags_mapped = XmpToolkitRuby::XmpFileHandlerFlags.flags_for(handler_flags)

                       format = info["format"]
                       format_mapped = XmpToolkitRuby::XmpFileFormat.name_for(format)

                       {
                         "handler_flags" => handler_flags_mapped,
                         "handler_flags_orig" => handler_flags,
                         "format" => format_mapped,
                         "format_orig" => format
                       }
                     end
    end

    def packet_info
      @packet_info ||= @xmp_wrapper.packet_info
    end

    def map_handler_flags(handler_flags)
      return {} if handler_flags.nil?

      handler_flags_mapped = XmpToolkitRuby::XmpFileHandlerFlags.flags_for(handler_flags)

      {
        "handler_flags" => handler_flags_mapped,
        "handler_flags_orig" => handler_flags
      }
    end

    def write
      raise "File not open" unless open?

      @xmp_wrapper.write
    end

    def update_property(namespace, property, value)
      open
      @xmp_wrapper.update_property(namespace, property, value)
    end

    def update_localized_property(schema_ns:,
                                  alt_text_name:,
                                  generic_lang:,
                                  specific_lang:,
                                  item_value:,
                                  options:)
      open

      @xmp_wrapper.update_localized_property(
        schema_ns:,
        alt_text_name:,
        generic_lang:,
        specific_lang:,
        item_value:,
        options:
      )
    end

    def close
      return unless open?

      @open = false
      @xmp_wrapper.close
    end
  end
end
