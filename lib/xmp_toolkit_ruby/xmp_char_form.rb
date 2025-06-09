# frozen_string_literal: true

module XmpToolkitRuby
  module XmpCharForm
    # Mapping of character format and byte-order masks (charForm enum)
    CHAR_FORM = {
      # Byte-order masks (do not use directly)
      little_endian_mask: 0x0000_0001, # kXMP_CharLittleEndianMask
      char_16bit_mask: 0x0000_0002, # kXMP_Char16BitMask
      char_32bit_mask: 0x0000_0004, # kXMP_Char32BitMask

      # Character format constants
      char_8bit: 0x0000_0000, # kXMP_Char8Bit
      char_16bit_big: 0x0000_0002, # kXMP_Char16BitBig
      char_16bit_little: 0x0000_0003, # kXMP_Char16BitLittle
      char_32bit_big: 0x0000_0004, # kXMP_Char32BitBig
      char_32bit_little: 0x0000_0005, # kXMP_Char32BitLittle
      char_unknown: 0x0000_0001 # kXMP_CharUnknown
    }.freeze

    # Reverse lookup by value
    CHAR_FORM_BY_VALUE = CHAR_FORM.invert.freeze

    class << self
      # Lookup the integer value for a given charForm name (Symbol or String).
      # @example XmpCharForm.value_for(:char_16bit_little) # => 3
      def value_for(name)
        key = name.is_a?(String) ? name.to_sym : name
        CHAR_FORM[key]
      end

      # Lookup the charForm name for a given integer value.
      # @example XmpCharForm.name_for(4) # => :char_32bit_big
      def name_for(value)
        CHAR_FORM_BY_VALUE[value]
      end

      # For a bitmask combining masks, return all matching names.
      # @example XmpCharForm.flags_for(0x0003) # => [:char_16bit_mask, :little_endian_mask, :char_16bit_little]
      def flags_for(bitmask)
        CHAR_FORM.select { |_, v| (bitmask & v).nonzero? }.keys
      end
    end
  end
end