# frozen_string_literal: true

module XmpToolkitRuby
  module XmpFileHandlerFlags
    # The keys here are Ruby-style snake_case equivalents of the handler flag constants
    # defined in Adobe's XMP Toolkit SDK (see XMP_Const.h, e.g. kXMPFiles_CanInjectXMP, etc).
    # For details on what each flag means, refer to the SDK's C++ header documentation.
    FLAGS = {
      can_inject_xmp: 0x0000_0001, # kXMPFiles_CanInjectXMP
      can_expand: 0x0000_0002, # kXMPFiles_CanExpand
      can_rewrite: 0x0000_0004, # kXMPFiles_CanRewrite
      prefers_in_place: 0x0000_0008, # kXMPFiles_PrefersInPlace
      can_reconcile: 0x0000_0010, # kXMPFiles_CanReconcile
      allows_only_xmp: 0x0000_0020, # kXMPFiles_AllowsOnlyXMP
      returns_raw_packet: 0x0000_0040, # kXMPFiles_ReturnsRawPacket
      handler_owns_file: 0x0000_0100, # kXMPFiles_HandlerOwnsFile
      allows_safe_update: 0x0000_0200, # kXMPFiles_AllowsSafeUpdate
      needs_read_only_packet: 0x0000_0400, # kXMPFiles_NeedsReadOnlyPacket
      uses_sidecar_xmp: 0x0000_0800, # kXMPFiles_UsesSidecarXMP
      folder_based_format: 0x0000_1000, # kXMPFiles_FolderBasedFormat
      can_notify_progress: 0x0000_2000, # kXMPFiles_CanNotifyProgress
      needs_preloading: 0x0000_4000, # kXMPFiles_NeedsPreloading
      needs_local_file_opened: 0x0001_0000 # kXMPFiles_NeedsLocalFileOpened
    }.freeze

    FLAGS_BY_VALUE = FLAGS.invert.freeze

    class << self
      # Retrieve the hex value for a given flag name (Symbol or String).
      # Example: XmpFileHandlerFlags.value_for(:can_inject_xmp) #=> 0x00000001
      def value_for(name)
        key = name.is_a?(String) ? name.to_sym : name
        FLAGS[key]
      end

      # Retrieve the flag name (Symbol) for a given hex value (Integer).
      # Example: XmpFileHandlerFlags.name_for(0x00000008) #=> :prefers_in_place
      def name_for(hex_value)
        FLAGS_BY_VALUE[hex_value]
      end

      # Given a bitmask, return an array of all flag names that are set.
      # Example: XmpFileHandlerFlags.flags_for(0x00000005) #=> [:can_inject_xmp, :can_rewrite]
      def flags_for(bitmask)
        FLAGS.select { |_, bit| bitmask.anybits?(bit) }.keys
      end
    end
  end
end
