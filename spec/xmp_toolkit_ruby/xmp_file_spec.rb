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

  before :each do
    XmpToolkitRuby::XmpToolkit.initialize_xmp
  end

  after :each do
    XmpToolkitRuby::XmpToolkit.terminate
  end

  let(:filename) { fixture_file_clone("sample.pdf").path }
  subject(:xmp_file) { described_class.new(filename, open_flags: XmpToolkitRuby::XmpFileOpenFlags::OPEN_FOR_UPDATE | XmpToolkitRuby::XmpFileOpenFlags::OPEN_USE_SMART_HANDLER) }

  describe "#update_property" do
    it "can set a property" do
      XmpToolkitRuby::XmpFile.register_namespace XmpToolkitRuby::Namespaces::XMP_NS_PDFUA_ID, "pdfua"

      xmp_file.open
      xmp_file.update_property XmpToolkitRuby::Namespaces::XMP_NS_PDFUA_ID, "part", "1"
      xmp_file.write
      xmp_file.close

      xmp = XmpToolkitRuby.xmp_from_file(filename)

      expect(xmp["xmp_data"]).to include ("part")
    ensure
      xmp_file.close
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

      expect(xmp["xmp_data"]).to include ('<rdf:li xml:lang="en-US">Hello world</rdf:li>')
    ensure
      xmp_file.close
    end
  end

  describe ".with_xmp_file" do
    it "initializes the sdk" do
      described_class.with_xmp_file(filename, open_flags: XmpToolkitRuby::XmpFileOpenFlags.bitmask_for(:open_for_read, :open_use_smart_handler)) do |_xmp_file|
        expect(XmpToolkitRuby.sdk_initialized?).to be_truthy
      end
    end

    it "terminates the sdk, afterwards" do
      described_class.with_xmp_file(filename, open_flags: XmpToolkitRuby::XmpFileOpenFlags.bitmask_for(:open_for_read, :open_use_smart_handler)) do |_xmp_file|

      end

      expect(XmpToolkitRuby.sdk_initialized?).to be_falsy
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

      expect(xmp["xmp_data"]).to include ('<rdf:li xml:lang="en-US">Hello world</rdf:li>')
    end
  end

end