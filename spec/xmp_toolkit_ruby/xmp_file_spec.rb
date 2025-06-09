# frozen_string_literal: true

require "tempfile"

RSpec.describe XmpToolkitRuby::XmpFile do
  def fixture_file_clone(filename)
    orig_file = fixture_file(filename)
    cloned_file = Tempfile.new(File.basename(orig_file))

    FileUtils.cp(orig_file, cloned_file.path)
    cloned_file
  end

  def fixture_file(filename)
    File.expand_path("../fixtures/#{filename}", __dir__)
  end

  def xmp_toolkit_fixture_file(filename)
    fixture_file("XMP-Toolkit-SDK/testfiles/#{filename}")
  end

  subject(:xmp_file) { described_class.new(filename, open_flags: XmpToolkitRuby::XmpFileOpenFlags::OPEN_FOR_UPDATE | XmpToolkitRuby::XmpFileOpenFlags::OPEN_USE_SMART_HANDLER) }

  before do
    XmpToolkitRuby::XmpToolkit.initialize_xmp
  end

  after do
    XmpToolkitRuby::XmpToolkit.terminate
  end

  let(:filename) { fixture_file_clone("sample.pdf").path }

  describe "#update_property" do
    it "can set a property" do
      described_class.register_namespace XmpToolkitRuby::Namespaces::XMP_NS_PDFUA_ID, "pdfua"

      xmp_file.open
      xmp_file.update_property XmpToolkitRuby::Namespaces::XMP_NS_PDFUA_ID, "part", "1"
      xmp_file.write
      xmp_file.close

      xmp = XmpToolkitRuby.xmp_from_file(filename)

      expect(xmp["xmp_data"]).to include("part")
    ensure
      xmp_file.close
    end

    context "when using XmpToolkitRuby::XmpValue" do
      after do
        xmp_file&.close
      end

      it "can handle string values" do
        xmp_file.open

        string_value = XmpToolkitRuby::XmpValue.new("hello world", type: :string)
        xmp_file.update_property XmpToolkitRuby::Namespaces::XMP_NS_DC, "string", string_value

        xmp_file.write
        xmp_file.close

        xmp = XmpToolkitRuby.xmp_from_file(filename)

        expect(xmp["xmp_data"]).to include("<dc:string>hello world</dc:string>")
      end

      it "can handle date values" do
        xmp_file.open

        date_value = XmpToolkitRuby::XmpValue.new(DateTime.parse("023-10-01T12:00:00+05:30"), type: :date)
        xmp_file.update_property XmpToolkitRuby::Namespaces::XMP_NS_DC, "date", date_value

        xmp_file.write
        xmp_file.close

        xmp = XmpToolkitRuby.xmp_from_file(filename)

        expect(xmp["xmp_data"]).to include("<rdf:li>0023-10-01T12:00:00+05:30</rdf:li>")
      end

      it "can handle bool values" do
        xmp_file.open

        bool_value = XmpToolkitRuby::XmpValue.new(true, type: :bool)
        xmp_file.update_property XmpToolkitRuby::Namespaces::XMP_NS_DC, "bool", bool_value

        xmp_file.write
        xmp_file.close

        xmp = XmpToolkitRuby.xmp_from_file(filename)

        expect(xmp["xmp_data"]).to include("<dc:bool>True</dc:bool>")
      end

      it "can handle int values" do
        xmp_file.open

        int_value = XmpToolkitRuby::XmpValue.new(42, type: :int)
        xmp_file.update_property XmpToolkitRuby::Namespaces::XMP_NS_DC, "int", int_value

        xmp_file.write
        xmp_file.close

        xmp = XmpToolkitRuby.xmp_from_file(filename)

        expect(xmp["xmp_data"]).to include("<dc:int>42</dc:int>")
      end

      it "can handle int64 values" do
        xmp_file.open

        int64_value = XmpToolkitRuby::XmpValue.new(42, type: :int64)
        xmp_file.update_property XmpToolkitRuby::Namespaces::XMP_NS_DC, "int64", int64_value

        xmp_file.write
        xmp_file.close

        xmp = XmpToolkitRuby.xmp_from_file(filename)

        expect(xmp["xmp_data"]).to include("<dc:int64>42</dc:int64>")
      end

      it "can handle float values" do
        xmp_file.open

        float_value = XmpToolkitRuby::XmpValue.new(42.42, type: :float)
        xmp_file.update_property XmpToolkitRuby::Namespaces::XMP_NS_DC, "float", float_value

        xmp_file.write
        xmp_file.close

        xmp = XmpToolkitRuby.xmp_from_file(filename)

        expect(xmp["xmp_data"]).to include("<dc:float>42.420000</dc:float>")
      end
    end
  end

  describe "#update_localized_property" do
    it "can set a localized property" do
      xmp_file.open

      xmp_file.update_localized_property schema_ns: XmpToolkitRuby::Namespaces::XMP_NS_DC,
                                         alt_text_name: "title",
                                         generic_lang: "en",
                                         specific_lang: "en-US",
                                         item_value: "Hello world",
                                         options: 0

      xmp_file.write
      xmp_file.close

      xmp = XmpToolkitRuby.xmp_from_file(filename)

      expect(xmp["xmp_data"]).to include('<rdf:li xml:lang="en-US">Hello world</rdf:li>')
    ensure
      xmp_file.close
    end
  end

  describe "#file_info" do
    it "returns file information" do
      described_class.with_xmp_file(filename, open_flags: XmpToolkitRuby::XmpFileOpenFlags.bitmask_for(:open_for_read, :open_use_smart_handler)) do |xmp_file|
        expect(xmp_file.file_info).to eq({
          "format" => :kXMP_PDFFile,
          "format_orig" => 1_346_651_680,
          "handler_flags" => %i[can_inject_xmp can_expand can_rewrite allows_only_xmp returns_raw_packet handler_owns_file allows_safe_update needs_preloading],
          "handler_flags_orig" => 17_255
        })
      end
    end
  end

  describe "#packet_info" do
    it "returns packet information" do
      described_class.with_xmp_file(filename, open_flags: XmpToolkitRuby::XmpFileOpenFlags.bitmask_for(:open_for_read, :open_use_smart_handler)) do |xmp_file|
        expect(xmp_file.packet_info).to eq({
          "char_form" => 0,
          "has_wrapper" => true,
          "length" => -1,
          "offset" => -1,
          "pad" => 0,
          "pad_size" => 2049,
          "writeable" => true
        })
      end
    end
  end

  describe ".with_xmp_file" do
    it "initializes the sdk" do
      described_class.with_xmp_file(filename, open_flags: XmpToolkitRuby::XmpFileOpenFlags.bitmask_for(:open_for_read, :open_use_smart_handler)) do |_xmp_file|
        expect(XmpToolkitRuby).to be_sdk_initialized
      end
    end

    it "terminates the sdk, afterwards" do
      # rubocop:disable Lint/EmptyBlock
      described_class.with_xmp_file(filename, open_flags: XmpToolkitRuby::XmpFileOpenFlags.bitmask_for(:open_for_read, :open_use_smart_handler)) do |_xmp_file|
      end
      # rubocop:enable Lint/EmptyBlock

      expect(XmpToolkitRuby).not_to be_sdk_initialized
    end

    it "provides a valid xmp_file" do
      described_class.with_xmp_file(filename, open_flags: XmpToolkitRuby::XmpFileOpenFlags.bitmask_for(:open_for_update, :open_use_smart_handler)) do |xmp_file|
        xmp_file.update_localized_property schema_ns: XmpToolkitRuby::Namespaces::XMP_NS_DC,
                                           alt_text_name: "title",
                                           generic_lang: "en",
                                           specific_lang: "en-US",
                                           item_value: "Hello world",
                                           options: 0
      end

      xmp = XmpToolkitRuby.xmp_from_file(filename)

      expect(xmp["xmp_data"]).to include('<rdf:li xml:lang="en-US">Hello world</rdf:li>')
    end
  end
end
