# frozen_string_literal: true

module XmpToolkitRuby
  module XmpFileFormat
    # Mapping from constant name (as a Symbol) to its 32‐bit hexadecimal value
    FORMATS = {
      # Public file formats
      kXMP_PDFFile: 0x50444620,
      kXMP_PostScriptFile: 0x50532020,
      kXMP_EPSFile: 0x45505320,
      kXMP_JPEGFile: 0x4A504547,
      kXMP_JPEG2KFile: 0x4A505820,
      kXMP_TIFFFile: 0x54494646,
      kXMP_GIFFile: 0x47494620,
      kXMP_PNGFile: 0x504E4720,
      kXMP_SWFFile: 0x53574620,
      kXMP_FLAFile: 0x464C4120,
      kXMP_FLVFile: 0x464C5620,
      kXMP_MOVFile: 0x4D4F5620,
      kXMP_AVIFile: 0x41564920,
      kXMP_CINFile: 0x43494E20,
      kXMP_WAVFile: 0x57415620,
      kXMP_MP3File: 0x4D503320,
      kXMP_SESFile: 0x53455320,
      kXMP_CELFile: 0x43454C20,
      kXMP_MPEGFile: 0x4D504547,
      kXMP_MPEG2File: 0x4D503220,
      kXMP_MPEG4File: 0x4D503420,
      kXMP_MXFFile: 0x4D584620,
      kXMP_WMAVFile: 0x574D4156,
      kXMP_AIFFFile: 0x41494646,
      kXMP_REDFile: 0x52454420,
      kXMP_ARRIFile: 0x41525249,
      kXMP_HEIFFile: 0x48454946,
      kXMP_P2File: 0x50322020,
      kXMP_XDCAM_FAMFile: 0x58444346,
      kXMP_XDCAM_SAMFile: 0x58444353,
      kXMP_XDCAM_EXFile: 0x58444358,
      kXMP_AVCHDFile: 0x41564844,
      kXMP_SonyHDVFile: 0x53484456,
      kXMP_CanonXFFile: 0x434E5846,
      kXMP_AVCUltraFile: 0x41564355,
      kXMP_HTMLFile: 0x48544D4C,
      kXMP_XMLFile: 0x584D4C20,
      kXMP_TextFile: 0x74657874,
      kXMP_SVGFile: 0x53564720,

      # Adobe application file formats
      kXMP_PhotoshopFile: 0x50534420,
      kXMP_IllustratorFile: 0x41492020,
      kXMP_InDesignFile: 0x494E4444,
      kXMP_AEProjectFile: 0x41455020,
      kXMP_AEProjTemplateFile: 0x41455420,
      kXMP_AEFilterPresetFile: 0x46465820,
      kXMP_EncoreProjectFile: 0x4E434F52,
      kXMP_PremiereProjectFile: 0x5052504A,
      kXMP_PremiereTitleFile: 0x5052544C,
      kXMP_UCFFile: 0x55434620,

      # Others
      kXMP_UnknownFile: 0x20202020
    }.freeze

    # Inverted mapping from hex value to constant name (Symbol)
    FORMATS_BY_VALUE = FORMATS.invert.freeze

    class << self
      # Retrieve the hex value for a given constant name (Symbol or String).
      #
      # Example:
      #   XMPFileFormat.value_for(:kXMP_JPEGFile)  # => 0x4A504547
      #   XMPFileFormat.value_for("kXMP_PNGFile")  # => 0x504E4720
      def value_for(name)
        key = name.is_a?(String) ? name.to_sym : name
        FORMATS[key]
      end

      # Retrieve the constant name (Symbol) for a given hex value (Integer).
      #
      # Example:
      #   XMPFileFormat.name_for(0x4D4F5620)  # => :kXMP_MOVFile
      def name_for(hex_value)
        FORMATS_BY_VALUE[hex_value]
      end
    end
  end
end
