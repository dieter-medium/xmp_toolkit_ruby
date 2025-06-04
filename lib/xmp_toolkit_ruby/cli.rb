# frozen_string_literal: true

require "thor"

module XmpToolkitRuby
  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  class CLI < Thor
    # Ensures that the CLI exits with a non-zero status code on failure.
    def self.exit_on_failure?
      true
    end

    desc "print_xmp FILE_PATH [OUTPUT_FILE_PATH]", "Prints the XMP metadata from a given file. Optionally writes to OUTPUT_FILE_PATH."
    method_option :raw, type: :boolean, default: false, desc: "Output the original, raw XMP data instead of the cleaned version."

    def print_xmp(file_path, output_file_path = nil)
      metadata = XmpToolkitRuby.xmp_from_file(file_path)
      key_to_print = options[:raw] ? "xmp_data_orig" : "xmp_data"

      if metadata && metadata[key_to_print]
        xmp_content = metadata[key_to_print]
        if output_file_path
          begin
            File.write(output_file_path, xmp_content)
            puts "XMP Metadata from #{file_path}#{" (raw)" if options[:raw]} written to #{output_file_path}"
          rescue SystemCallError => e # Catches errors like EACCES, ENOENT etc.
            raise Thor::Error, "Error writing to output file #{output_file_path}: #{e.message}"
          end
        else
          puts "XMP Metadata for: #{file_path}#{" (raw)" if options[:raw]}"
          puts xmp_content
        end
      else
        message = "No XMP metadata found (key: #{key_to_print}) or an error occurred for: #{file_path}"
        raise Thor::Error, message if output_file_path

        puts message

      end
    rescue XmpToolkitRuby::FileNotFoundError => e
      raise Thor::Error, "Error: #{e.message}"
    rescue StandardError => e
      raise Thor::Error, "An unexpected error occurred: #{e.message}"
    end

    desc "override_xmp FILE_PATH XML_FILE_PATH", "Overrides XMP metadata in FILE_PATH with content from XML_FILE_PATH."
    long_desc <<-LONGDESC
      This command will replace the existing XMP metadata in FILE_PATH
      with the XMP metadata provided in XML_FILE_PATH.

      The content of XML_FILE_PATH will be validated as XML before attempting to write.
    LONGDESC

    def override_xmp(file_path, xml_file_path)
      raise Thor::Error, "XML file not found: #{xml_file_path}" unless File.exist?(xml_file_path)
      raise Thor::Error, "XML file is not readable: #{xml_file_path}" unless File.readable?(xml_file_path)

      xml_content = File.read(xml_file_path)

      # Validate XML
      doc = Nokogiri::XML(xml_content) do |config|
        config.strict.nonet # More secure parsing options
      end

      unless doc.errors.empty?
        error_messages = doc.errors.map(&:message).join("\n - ")
        raise Thor::Error, "Invalid XML in #{xml_file_path}:\n - #{error_messages}"
      end

      # The XmpToolkitRuby.xmp_to_file method itself will call check_file! for file_path
      XmpToolkitRuby.xmp_to_file(file_path, xml_content, override: true)
      puts "Successfully overrode XMP metadata in #{file_path} with content from #{xml_file_path}."
    rescue XmpToolkitRuby::FileNotFoundError => e
      raise Thor::Error, "Error: #{e.message}"
    rescue Thor::Error # Re-raise Thor errors directly
      raise
    rescue StandardError => e
      raise Thor::Error, "An unexpected error occurred: #{e.message}\n#{e.backtrace.join("\n")}"
    end

    desc "version", "Show xmp_toolkit_ruby version"

    def version
      puts "xmp_toolkit_ruby version #{XmpToolkitRuby::VERSION}"
    end
  end

  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
end
