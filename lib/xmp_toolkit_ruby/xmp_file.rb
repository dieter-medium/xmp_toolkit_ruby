# frozen_string_literal: true

module XmpToolkitRuby
  require_relative "xmp_file_open_flags"

  # XmpFile provides a high-level Ruby interface for managing XMP metadata
  # in files such as JPEG, TIFF, PNG, and PDF. It wraps the underlying
  # Adobe XMP SDK calls, offering simplified methods to open, read, update,
  # and write XMP packets, as well as to retrieve file and packet information.
  #
  # == Core Features
  # - Open files for read or update, with optional fallback flags
  # - Read raw and parsed XMP metadata
  # - Update metadata by bulk XML or by individual property/schema
  # - Write changes back to the file
  # - Retrieve file-level info (format, handler flags, open flags)
  # - Retrieve packet-level info (packet size, padding)
  # - Support for localized text properties (alt-text arrays)
  #
  # @example Read and print XMP data:
  #   XmpFile.with_xmp_file("image.jpg") do |xmp|
  #     p xmp.meta["xmp_data"]
  #   end
  #
  # @example Update a custom property:
  #   XmpFile.with_xmp_file("doc.pdf", open_flags: XmpFileOpenFlags::OPEN_FOR_UPDATE) do |xmp|
  #     new_xml = '<x:xmpmeta xmlns:x="adobe:ns:meta/">...'</x>
  #     xmp.update_meta(new_xml)
  #   end
  class XmpFile
    # Path to the file on disk containing XMP metadata.
    # @return [String]
    attr_reader :file_path

    # Flags used for the primary open operation. See XmpFileOpenFlags.
    # @return [Integer]
    attr_reader :open_flags

    # Optional fallback flags if opening with primary flags fails.
    # @return [Integer, nil]
    attr_reader :fallback_flags

    class << self
      # Register a custom namespace URI for subsequent property operations.
      #
      # @param namespace [String] Full URI of the namespace, e.g. "http://ns.adobe.com/photoshop/1.0/"
      # @param suggested_prefix [String] Short prefix to use in XML (e.g. "photoshop").
      # @return [String] The actual prefix registered by the SDK.
      # @raise [RuntimeError] if the XMP toolkit has not been initialized.
      def register_namespace(namespace, suggested_prefix)
        warn "XMP Toolkit not initialized; loading default plugins from \#{XmpToolkitRuby::PLUGINS_PATH}" unless XmpToolkitRuby::XmpToolkit.initialized?
        XmpWrapper.register_namespace(namespace, suggested_prefix)
      end

      # Open a file with XMP support, yielding a managed XmpFile instance.
      # This method ensures the XMP toolkit is initialized and terminated,
      # and that the file is closed and written (if modified).
      #
      # @param file_path [String] Path to the target file.
      # @param open_flags [Integer] Bitmask from XmpFileOpenFlags (default: OPEN_FOR_READ).
      # @param plugin_path [String] Directory of XMP SDK plugins (default: PLUGINS_PATH).
      # @param fallback_flags [Integer, nil] Alternate flags if primary fails.
      # @param auto_terminate_toolkit [Boolean] Shutdown toolkit after block (default: true).
      # @yield [xmp_file] Gives an XmpFile instance for metadata operations.
      # @yieldparam xmp_file [XmpFile]
      # @return [void]
      # @raise [IOError] if file open fails and no fallback succeeds.
      def with_xmp_file(
        file_path,
        open_flags: XmpFileOpenFlags::OPEN_FOR_READ,
        plugin_path: XmpToolkitRuby::PLUGINS_PATH,
        fallback_flags: nil,
        auto_terminate_toolkit: true
      )
        XmpToolkitRuby.check_file!(file_path,
                                   need_to_read: true,
                                   need_to_write: XmpFileOpenFlags.contains?(open_flags, :open_for_update))

        XmpToolkitRuby::XmpToolkit.initialize_xmp(plugin_path) unless XmpToolkitRuby.sdk_initialized?

        xmp_file = new(file_path,
                       open_flags: open_flags,
                       fallback_flags: fallback_flags)
        xmp_file.open
        yield xmp_file
      ensure
        xmp_file.write if xmp_file && XmpFileOpenFlags.contains?(xmp_file.open_flags, :open_for_update)
        xmp_file&.close
        XmpToolkitRuby::XmpToolkit.terminate if auto_terminate_toolkit && XmpToolkitRuby.sdk_initialized?
      end
    end

    # Initialize an XmpFile for a given path.
    #
    # @param file_path [String,Pathname] Local file path to open.
    # @param open_flags [Integer] XmpFileOpenFlags bitmask (default: OPEN_FOR_READ).
    # @param fallback_flags [Integer,nil] Alternate flags on failure.
    # @raise [ArgumentError] if file_path is not readable.
    # @example
    #   XmpFile.new("photo.tif", open_flags: XmpFileOpenFlags::OPEN_FOR_UPDATE)
    def initialize(file_path, open_flags: XmpFileOpenFlags::OPEN_FOR_READ, fallback_flags: nil)
      @file_path = file_path.to_s
      raise ArgumentError, "File path '#{@file_path}' must exist and be readable" unless File.readable?(@file_path)

      @open_flags = open_flags
      @fallback_flags = fallback_flags
      @open = false
      @xmp_wrapper = XmpWrapper.new
    end

    # Open the file for XMP operations.
    # If initialization flags fail and fallback_flags is provided,
    # attempts a second open with fallback flags.
    #
    # @return [void]
    # @raise [IOError] if both primary and fallback open(...) fail.
    # @note Emits warning if toolkit not initialized.
    def open
      return if open?

      warn "XMP Toolkit not initialized; using default plugin path" unless XmpToolkitRuby::XmpToolkit.initialized?

      begin
        @xmp_wrapper.open(file_path, open_flags).tap { @open = true }
      rescue IOError => e
        @xmp_wrapper.close
        @open = false
        raise e unless fallback_flags

        @xmp_wrapper.open(file_path, fallback_flags).tap { @open = true }
      end
    end

    # @return [Boolean] Whether the file is currently open for XMP operations.
    def open?
      @open
    end

    # Retrieve a hash of file-level metadata and flags.
    #
    # @return [Hash{String=>Object}]
    # @example
    #   info = xmp.file_info
    #   puts "Format: #{info['format']}"
    def file_info
      @file_info ||= begin
                       info = @xmp_wrapper.file_info
                       {
                         "handler_flags" => XmpToolkitRuby::XmpFileHandlerFlags.flags_for(info["handler_flags"]),
                         "handler_flags_orig" => info["handler_flags"],
                         "format" => XmpToolkitRuby::XmpFileFormat.name_for(info["format"]),
                         "format_orig" => info["format"],
                         "open_flags" => XmpToolkitRuby::XmpFileOpenFlags.flags_for(info["open_flags"]),
                         "open_flags_orig" => info["open_flags"]
                       }
                     end
    end

    # Retrieve low-level packet information (size, offset, padding).
    #
    # @return [Hash] Raw packet info as provided by the SDK.
    def packet_info
      @packet_info ||= @xmp_wrapper.packet_info
    end

    # Get parsed XMP metadata and packet boundaries.
    #
    # @return [Hash]
    #   - "begin" [String]: Packet start marker timestamp
    #   - "packet_id" [String]: Unique XMP packet ID
    #   - "xmp_data" [String]: Inner RDF/XML content
    #   - "xmp_data_orig" [String]: Full packet including processing instruction
    #  rubocop:disable Metrics/AbcSize
    def meta
      raw = @xmp_wrapper.meta
      return {} if raw.nil? || raw.empty?

      doc = Nokogiri::XML(raw)
      pis = doc.xpath("//processing-instruction('xpacket')")
      begin_pi = pis.detect { |pi| pi.content.start_with?("begin=") }
      attrs = begin_pi.content.scan(/(\w+)="([^"]*)"/).to_h
      pis.remove

      {
        "begin" => attrs["begin"],
        "packet_id" => attrs["id"],
        "xmp_data" => doc.root.to_xml,
        "xmp_data_orig" => raw
      }
    end

    # rubocop:enable Metrics/AbcSize

    # Persist all pending XMP updates to the file.
    #
    # @raise [RuntimeError] unless file is open.
    # @return [void]
    def write
      raise "File not open; cannot write" unless open?

      @xmp_wrapper.write
    end

    # Bulk update XMP metadata using an RDF/XML string.
    #
    # @param xmp_data [String] Full RDF/XML payload or fragment
    # @param mode [Symbol] :upsert (default) or :replace
    # @return [void]
    def update_meta(xmp_data, mode: :upsert)
      open
      @xmp_wrapper.update_meta(xmp_data, mode: mode)
    end

    # Update a single property in the XMP schema.
    #
    # @param namespace [String] Schema namespace URI
    # @param property [String] Qualified property name (without prefix)
    # @param value [String] New value for the property
    # @return [void]
    def update_property(namespace, property, value)
      open
      @xmp_wrapper.update_property(namespace, property, value)
    end

    # Retrieve the value of a simple XMP property.
    #
    # This will open the file (if not already open), query the underlying
    # SDK for the given namespace + property, and return whatever value is stored.
    #
    # @param namespace [String] Namespace URI of the schema (e.g. "http://ns.adobe.com/photoshop/1.0/")
    # @param property [String] Property name (without prefix), e.g. "CreatorTool"
    # @return [String, nil] The value of the property, or nil if not set
    # @raise [RuntimeError] if the file cannot be opened
    def property(namespace, property)
      open
      @xmp_wrapper.property(namespace, property)
    end

    # Retrieve a localized (alt-text) value from an XMP array.
    #
    # Locates the alt-text array identified by
    # `alt_text_name` in the given `schema_ns`, then returns the string
    # matching the requested generic and specific language codes.
    #
    # @param schema_ns [String] Namespace URI of the alt-text schema
    # @param alt_text_name [String] The name of the localized text array
    # @param generic_lang [String] Base language code (e.g. "en")
    # @param specific_lang [String] Locale variant (e.g. "en-US")
    # @return [String, nil] The localized string for that locale, or nil if not found
    # @raise [RuntimeError] if the file cannot be opened
    def localized_property(schema_ns:, alt_text_name:, generic_lang:, specific_lang:)
      open

      @xmp_wrapper.localized_property(
        schema_ns: schema_ns,
        alt_text_name: alt_text_name,
        generic_lang: generic_lang,
        specific_lang: specific_lang
      )
    end

    # Update an alternative-text (localized string) property.
    #
    # @param schema_ns [String] Namespace URI of the alt-text schema
    # @param alt_text_name [String] Name of the alt-text array
    # @param generic_lang [String] Base language (e.g. "en")
    # @param specific_lang [String] Specific locale (e.g. "en-US")
    # @param item_value [String] Localized string value
    # @param options [Integer] Bitmask for array operations (see SDK)
    # @return [void]
    def update_localized_property(schema_ns:, alt_text_name:, generic_lang:, specific_lang:, item_value:, options:)
      open
      @xmp_wrapper.update_localized_property(
        schema_ns: schema_ns,
        alt_text_name: alt_text_name,
        generic_lang: generic_lang,
        specific_lang: specific_lang,
        item_value: item_value,
        options: options
      )
    end

    # Close the file and clear internal state.
    # @return [void]
    def close
      return unless open?

      @open = false
      @xmp_wrapper.close
    end

    private

    # Internal helper to map raw handler flags to named symbols.
    #
    # @param handler_flags [Integer,nil]
    # @return [Hash]
    # @api private
    def map_handler_flags(handler_flags)
      return {} if handler_flags.nil?

      {
        "handler_flags" => XmpToolkitRuby::XmpFileHandlerFlags.flags_for(handler_flags),
        "handler_flags_orig" => handler_flags
      }
    end
  end
end
