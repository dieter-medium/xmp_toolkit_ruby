# frozen_string_literal: true

module XmpToolkitRuby
  class XmpValue
    attr_reader :value, :type

    TYPES = %i[string bool int int64 float date].freeze

    def initialize(value, type: nil)
      @value = value
      @type = type.to_sym

      raise ArgumentError, "Invalid type: #{type}" unless TYPES.include?(@type)
    end
  end
end
