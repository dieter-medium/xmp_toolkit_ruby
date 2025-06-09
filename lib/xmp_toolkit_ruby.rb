# frozen_string_literal: true

require_relative "xmp_toolkit_ruby/version"
require_relative "xmp_toolkit_ruby/xmp_toolkit_ruby"

require "nokogiri"
require "rbconfig"

# The `XmpToolkitRuby` module serves as a Ruby interface to Adobe's XMP Toolkit,
# a native C++ library. This module allows Ruby applications to read and write
# XMP (Extensible Metadata Platform) metadata from and to various file formats.
#
# It handles the initialization and termination of the underlying C++ toolkit,
# manages paths to necessary plugins (like PDF handlers), processes and cleans
# XMP XML data, and provides a user-friendly API for XMP operations.
#
# Key functionalities include:
# * Reading XMP metadata from files.
# * Writing XMP metadata to files, with options to override or update existing data.
# * Automatic management of the XMP Toolkit's lifecycle.
# * Platform-aware resolution of plugin paths, with environment variable override.
# * Parsing and cleaning of XMP packet data.
# * Mapping of numerical handler flags to descriptive representations.
#
# @example Reading XMP from a file
#   metadata = XmpToolkitRuby.xmp_from_file("path/to/image.jpg")
#   puts metadata["xmp_data"] # Access the cleaned XMP XML string
#
# @example Writing XMP to a file
#   new_xmp_data = "<x:xmpmeta xmlns:x='adobe:ns:meta/'><rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'></rdf:RDF></x:xmpmeta>"
#   XmpToolkitRuby.xmp_to_file("path/to/image.jpg", new_xmp_data, override: true)
#
module XmpToolkitRuby
  require_relative "xmp_toolkit_ruby/xmp_file_format"
  require_relative "xmp_toolkit_ruby/namespaces"
  require_relative "xmp_toolkit_ruby/xmp_file_handler_flags"
  require_relative "xmp_toolkit_ruby/xmp_file"

  # The `PLUGINS_PATH` constant defines the directory where the XMP Toolkit
  # should look for its plugins, particularly the PDF handler.
  # The path is determined based on the current operating system (macOS or Linux)
  # and system architecture.
  #
  # This path can be overridden by setting the `XMP_TOOLKIT_PLUGINS_PATH`
  # environment variable, which takes precedence if set and not empty.
  #
  # If the platform or architecture is unsupported, a warning will be issued,
  # and the path may be empty, potentially affecting PDF handling capabilities.
  #
  # @return [String] The absolute path to the plugins directory.
  PLUGINS_PATH = if ENV["XMP_TOOLKIT_PLUGINS_PATH"] && !ENV["XMP_TOOLKIT_PLUGINS_PATH"].empty?
                   ENV["XMP_TOOLKIT_PLUGINS_PATH"]
                 else
                   case RUBY_PLATFORM
                   when /darwin/ # macOS
                     File.expand_path("./xmp_toolkit_ruby/plugins/PDF_Handler/macintosh/universal/", __dir__)
                   when /linux/
                     if RbConfig::CONFIG["host_cpu"] =~ /x86_64|amd64/
                       File.expand_path("./xmp_toolkit_ruby/plugins/PDF_Handler/i80386linux/i80386linux_x64/", __dir__)
                     elsif RbConfig::CONFIG["host_cpu"] =~ /i[3-6]86/ # Matches i386, i486, i586, i686
                       File.expand_path("./xmp_toolkit_ruby/plugins/PDF_Handler/i80386linux/i80386linux/", __dir__)
                     else
                       warn "Unsupported Linux architecture for PLUGINS_PATH: #{RbConfig::CONFIG["host_cpu"]}. PDF Handler might not work."
                       "" # Or some other default
                     end
                   else
                     # Fallback or error for unsupported platforms
                     warn "Unsupported platform for PLUGINS_PATH: #{RUBY_PLATFORM}. PDF Handler might not work."
                     "" # Or some other default that makes sense for your application
                   end
                 end

  class Error < StandardError; end

  class FileNotFoundError < Error; end

  class << self
    # Reads XMP metadata from a specified file.
    #
    # This method first checks if the file exists and is readable. It then
    # initializes the XMP Toolkit, reads the XMP data using the native extension,
    # cleans up the extracted XML, maps handler flags to a descriptive format,
    # and ensures the toolkit is terminated.
    #
    # @param file_path [String] The absolute or relative path to the target file.
    # @return [Hash] A hash containing the XMP metadata.
    #   The hash includes:
    #   - `"begin"`: The value of the `begin` attribute from the `xpacket` processing instruction.
    #   - `"packet_id"`: The value of the `id` attribute from the `xpacket` processing instruction.
    #   - `"xmp_data"`: The cleaned XMP XML string (core XMP metadata).
    #   - `"xmp_data_orig"`: The original, raw XMP data string as returned by the toolkit.
    #   - `"handler_flags"`: A descriptive representation of the handler flags (e.g., from {XmpFileHandlerFlags}).
    #   - `"handler_flags_orig"`: The original numerical handler flags from the toolkit.
    #   Returns an empty hash merged with cleanup and flag mapping results if the native call returns nil.
    # @raise [FileNotFoundError] If the file does not exist, is not readable, or `file_path` is nil.
    def xmp_from_file(file_path)
      check_file! file_path, need_to_read: true, need_to_write: false

      with_init do
        result = XmpToolkitRuby::XmpToolkit.read_xmp(file_path)
        result ||= {}
        result.merge(cleanup_xmp(result["xmp_data"])).merge(map_handler_flags(result["handler_flags"]))
      end
    end

    # Writes XMP metadata to a specified file.
    #
    # This method checks if the file exists, is readable, and is writable.
    # It then initializes the XMP Toolkit, writes the provided XMP data
    # (either as a Hash or an XML String) to the file using the native extension,
    # and ensures the toolkit is terminated.
    #
    # The `override` parameter controls how existing XMP data in the file is handled:
    # - If `true` (`:override`), existing XMP metadata is completely replaced.
    # - If `false` (`:upsert`), the new XMP data is merged with existing metadata;
    #   new properties are added, and existing ones may be updated.
    #
    # @param file_path [String] The absolute or relative path to the target file.
    # @param xmp_data [String] The XMP metadata to write.
    #   (which will be converted to XML by the native toolkit) or a pre-formatted XML String.
    # @param override [Boolean] (false) If `true`, existing XMP metadata in the
    #   file will be replaced. If `false`, the new data will be upserted (merged).
    # @raise [FileNotFoundError] If the file does not exist, is not readable/writable, or `file_path` is nil.
    def xmp_to_file(file_path, xmp_data, override: false)
      check_file! file_path, need_to_read: true, need_to_write: true

      with_init { XmpToolkitRuby::XmpToolkit.write_xmp(file_path, xmp_data, override ? :override : :upsert) }
    end

    # Ensures the native XMP Toolkit is initialized before executing a block
    # of code and terminated afterwards. This is crucial for managing the
    # lifecycle of the underlying C++ library resources.
    #
    # This method should wrap any calls to the native `XmpToolkitRuby::XmpToolkit` methods.
    #
    # @param path [String, nil] (nil) Optional path to the XMP Toolkit plugins directory.
    #   If `nil` or not provided, it defaults to `PLUGINS_PATH`.
    # @yield The block of code to execute while the XMP Toolkit is initialized.
    # @return The result of the yielded block.
    def with_init(path = nil, &block)
      XmpToolkitRuby::XmpToolkit.initialize_xmp(path || PLUGINS_PATH)

      block.call
    ensure
      XmpToolkitRuby::XmpToolkit.terminate
    end

    # Validates file accessibility before performing read or write operations.
    #
    # Checks for:
    # - Nil file path.
    # - File existence.
    # - File readability (if `need_to_read` is true).
    # - File writability (if `need_to_write` is true).
    #
    # @param file_path [String] The path to the file to check.
    # @param need_to_read [Boolean] (true) Whether the file needs to be readable.
    # @param need_to_write [Boolean] (false) Whether the file needs to be writable.
    # @raise [FileNotFoundError] If any of the checks fail.
    # @return [void]
    # @api private
    def check_file!(file_path, need_to_read: true, need_to_write: false)
      if file_path.nil?
        raise FileNotFoundError, "File path cannot be nil"
      elsif !File.exist?(file_path)
        raise FileNotFoundError, "File not found: #{file_path}"
      elsif need_to_read && !File.readable?(file_path)
        raise FileNotFoundError, "File exists but is not readable: #{file_path}"
      elsif need_to_write && !File.writable?(file_path)
        raise FileNotFoundError, "File exists but is not writable: #{file_path}"
      end
    end

    private

    # Parses raw XMP data string to extract `xpacket` processing instruction
    # attributes and the core XMP XML content.
    #
    # The `xpacket` processing instruction contains metadata about the XMP packet itself.
    # This method isolates these attributes and provides the main XMP XML structure
    # without these processing instructions.
    #
    # @param xmp_data [String, nil] The raw XMP data string, which may include
    #   `<?xpacket ...?>` processing instructions.
    # @return [Hash] A hash containing extracted information:
    #   - `"begin"`: The value of the `begin` attribute from the `xpacket` PI.
    #   - `"packet_id"`: The value of the `id` attribute from the `xpacket` PI.
    #   - `"xmp_data"`: The XMP XML content as a string, with `xpacket` PIs removed.
    #   - `"xmp_data_orig"`: The original, unmodified `xmp_data` string.
    #   Returns an empty hash if `xmp_data` is nil or empty.
    # @api private
    # rubocop: disable Metrics/AbcSize
    def cleanup_xmp(xmp_data)
      return {} if xmp_data.nil? || xmp_data.empty?

      doc = Nokogiri::XML(xmp_data)
      pis = doc.xpath("//processing-instruction('xpacket')")

      begin_pi = pis.find { |pi| pi.content =~ /\Abegin=/ }

      begin_attrs = begin_pi.content.scan(/(\w+)="([^"]*)"/).to_h
      begin_value = begin_attrs["begin"]
      packet_id = begin_attrs["id"]

      pis.remove
      inner_xml = doc.root.to_xml

      {
        "begin" => begin_value,
        "packet_id" => packet_id,
        "xmp_data" => inner_xml,
        "xmp_data_orig" => xmp_data
      }
    end

    # Maps numerical handler flags from the XMP Toolkit to a more descriptive
    # format, typically an Array of Symbols or Strings.
    #
    # This uses `XmpToolkitRuby::XmpFileHandlerFlags.flags_for` to perform the mapping.
    #
    # @param handler_flags [Integer, nil] The numerical handler flags returned by
    #   the native XMP Toolkit.
    # @return [Hash] A hash containing:
    #   - `"handler_flags"`: The mapped, descriptive representation of the flags.
    #   - `"handler_flags_orig"`: The original numerical `handler_flags`.
    #   Returns an empty hash if `handler_flags` is nil.
    # @api private
    def map_handler_flags(handler_flags)
      return {} if handler_flags.nil?

      handler_flags_mapped = XmpToolkitRuby::XmpFileHandlerFlags.flags_for(handler_flags)

      {
        "handler_flags" => handler_flags_mapped,
        "handler_flags_orig" => handler_flags
      }
    end

    # rubocop: enable Metrics/AbcSize, Metrics/MethodLength

  end
end
