# frozen_string_literal: true

module XmpToolkitRuby
  module XmpFileOpenFlags
    OPEN_FOR_READ = 0x0000_0001 # Open for read-only access
    OPEN_FOR_UPDATE = 0x0000_0002 # Open for reading and writing
    OPEN_ONLY_XMP = 0x0000_0004 # Only the XMP is wanted, allows space/time optimizations
    FORCE_GIVEN_HANDLER = 0x0000_0008 # Force use of the given handler (format), do not verify format
    OPEN_STRICTLY = 0x0000_0010 # Strictly use only designated file handler, no fallback
    OPEN_USE_SMART_HANDLER = 0x0000_0020 # Require the use of a smart handler
    OPEN_USE_PACKET_SCANNING = 0x0000_0040 # Force packet scanning, do not use smart handler
    OPEN_LIMITED_SCANNING = 0x0000_0080 # Only scan files "known" to need scanning
    OPEN_REPAIR_FILE = 0x0000_0100 # Attempt to repair a file opened for update
    OPTIMIZE_FILE_LAYOUT = 0x0000_0200 # Optimize file layout when updating
    PRESERVE_PDF_STATE = 0x0000_0400 # Preserve PDF document state when updating

    FLAGS = {
      open_for_read: OPEN_FOR_READ,
      open_for_update: OPEN_FOR_UPDATE,
      open_only_xmp: OPEN_ONLY_XMP,
      force_given_handler: FORCE_GIVEN_HANDLER,
      open_strictly: OPEN_STRICTLY,
      open_use_smart_handler: OPEN_USE_SMART_HANDLER,
      open_use_packet_scanning: OPEN_USE_PACKET_SCANNING,
      open_limited_scanning: OPEN_LIMITED_SCANNING,
      open_repair_file: OPEN_REPAIR_FILE,
      optimize_file_layout: OPTIMIZE_FILE_LAYOUT,
      preserve_pdf_state: PRESERVE_PDF_STATE
    }.freeze

    FLAGS_BY_VALUE = FLAGS.invert.freeze

    class << self
      def value_for(name)
        key = name.is_a?(String) ? name.to_sym : name
        FLAGS[key]
      end

      def name_for(hex_value)
        FLAGS_BY_VALUE[hex_value]
      end

      def flags_for(bitmask)
        FLAGS.select { |_, bit| bitmask.anybits?(bit) }.keys
      end

      def contains?(bitmask, flag)
        raise ArgumentError, "Invalid flag type: #{flag.class}" unless flag.is_a?(Symbol) || flag.is_a?(String)

        bitmask & value_for(flag) != 0
      end

      # Takes multiple flag names (symbols or strings) or constants,
      # returns combined bitmask OR-ing all.
      #
      # Example:
      #   bitmask_for(:open_for_read, :force_given_handler)
      #   bitmask_for(OPEN_FOR_READ, FORCE_GIVEN_HANDLER)
      def bitmask_for(*args)
        args.reduce(0) do |mask, flag|
          val = case flag
                when Symbol, String then value_for(flag)
                when Integer then flag
                else
                  raise ArgumentError, "Invalid flag type: #{flag.class}"
                end
          raise ArgumentError, "Unknown flag: #{flag.inspect}" unless val

          mask | val
        end
      end
    end
  end
end
