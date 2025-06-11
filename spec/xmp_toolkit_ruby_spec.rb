# frozen_string_literal: true

require "tempfile"

RSpec.describe XmpToolkitRuby do
  def fixture_file_clone(filename)
    orig_file = fixture_file(filename)
    cloned_file = Tempfile.new(File.basename(orig_file))

    FileUtils.cp(orig_file, cloned_file.path)
    cloned_file
  end

  def fixture_file(filename)
    File.expand_path("./fixtures/#{filename}", __dir__)
  end

  def xmp_toolkit_fixture_file(filename)
    fixture_file("XMP-Toolkit-SDK/testfiles/#{filename}")
  end

  it "has a version number" do
    expect(XmpToolkitRuby::VERSION).not_to be_nil
  end

  it "extracts the xmp data" do
    xmp = described_class.xmp_from_file(xmp_toolkit_fixture_file("BlueSquare.png"))
    expected_xmp = <<~XMP
      <x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="XMP Core 6.0.0">
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
             <rdf:Description xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xmp="http://ns.adobe.com/xap/1.0/" xmlns:xmpMM="http://ns.adobe.com/xap/1.0/mm/" xmlns:photoshop="http://ns.adobe.com/photoshop/1.0/" xmlns:tiff="http://ns.adobe.com/tiff/1.0/" xmlns:exif="http://ns.adobe.com/exif/1.0/" rdf:about="">
                <dc:format>application/vnd.adobe.photoshop</dc:format>
                <dc:title>
                   <rdf:Alt>
                      <rdf:li xml:lang="x-default">Blue Square Test File - .psd</rdf:li>
                   </rdf:Alt>
                </dc:title>
                <dc:description>
                   <rdf:Alt>
                      <rdf:li xml:lang="x-default">XMPFiles BlueSquare test file, created in Photoshop CS2, saved as .psd, .jpg, and .tif.</rdf:li>
                   </rdf:Alt>
                </dc:description>
                <dc:subject>
                   <rdf:Bag>
                      <rdf:li>XMP</rdf:li>
                      <rdf:li>Blue Square</rdf:li>
                      <rdf:li>test file</rdf:li>
                      <rdf:li>Photoshop</rdf:li>
                      <rdf:li>.psd</rdf:li>
                   </rdf:Bag>
                </dc:subject>
                <xmp:CreatorTool>Adobe Photoshop CS2 Macintosh</xmp:CreatorTool>
                <xmp:CreateDate>2005-09-07T15:01:43-07:00</xmp:CreateDate>
                <xmp:ModifyDate>2005-09-07T15:10:03-07:00</xmp:ModifyDate>
                <xmp:MetadataDate>2006-04-10T13:37:30-07:00</xmp:MetadataDate>
                <xmpMM:DocumentID>uuid:9A3B7F4E214211DAB6308A7391270C13</xmpMM:DocumentID>
                <xmpMM:InstanceID>uuid:B59AC1B6214311DAB6308A7391270C13</xmpMM:InstanceID>
                <photoshop:ColorMode>3</photoshop:ColorMode>
                <photoshop:ICCProfile>sRGB IEC61966-2.1</photoshop:ICCProfile>
                <tiff:Orientation>1</tiff:Orientation>
                <tiff:XResolution>720/10</tiff:XResolution>
                <tiff:YResolution>720/10</tiff:YResolution>
                <tiff:ResolutionUnit>2</tiff:ResolutionUnit>
                <tiff:ImageWidth>360</tiff:ImageWidth>
                <tiff:ImageLength>216</tiff:ImageLength>
                <tiff:NativeDigest>256,257,258,259,262,274,277,284,530,531,282,283,296,301,318,319,529,532,306,270,271,272,305,315,33432;9E4CBFDEEFA10EA008D1626B64394ED4</tiff:NativeDigest>
                <tiff:BitsPerSample>
                   <rdf:Seq>
                      <rdf:li>8</rdf:li>
                      <rdf:li>8</rdf:li>
                      <rdf:li>8</rdf:li>
                   </rdf:Seq>
                </tiff:BitsPerSample>
                <exif:PixelXDimension>360</exif:PixelXDimension>
                <exif:PixelYDimension>216</exif:PixelYDimension>
                <exif:ColorSpace>1</exif:ColorSpace>
                <exif:NativeDigest>36864,40960,40961,37121,37122,40962,40963,37510,40964,36867,36868,33434,33437,34850,34852,34855,34856,37377,37378,37379,37380,37381,37382,37383,37384,37385,37386,37396,41483,41484,41486,41487,41488,41492,41493,41495,41728,41729,41730,41985,41986,41987,41988,41989,41990,41991,41992,41993,41994,41995,41996,42016,0,2,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,20,22,23,24,25,26,27,28,30;76DBD9F0A5E7ED8F62B4CE8EFA6478B4</exif:NativeDigest>
             </rdf:Description>
          </rdf:RDF>
       </x:xmpmeta>#{"  "}
    XMP

    actual_xml = Nokogiri::XML(xmp["xmp_data"], &:noblanks)
    expected_xml = Nokogiri::XML(expected_xmp, &:noblanks)

    expect(actual_xml.to_s).to eq(expected_xml.to_s)
  end

  it "extracts the id" do
    xmp = described_class.xmp_from_file(xmp_toolkit_fixture_file("BlueSquare.png"))
    expect(xmp["packet_id"]).to eq("W5M0MpCehiHzreSzNTczkc9d")
  end

  it "extracts the format" do
    xmp = described_class.xmp_from_file(xmp_toolkit_fixture_file("BlueSquare.png"))
    format_str = XmpToolkitRuby::XmpFileFormat.name_for xmp["format_orig"]

    expect(format_str).to eq(:kXMP_PNGFile)
  end

  it "extracts xmp data from a PDF file" do
    xmp = described_class.xmp_from_file(fixture_file("sample.pdf"))
    expected_xmp = <<~XMP
        <x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="XMP Core 6.0.0">
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <rdf:Description xmlns:xmp="http://ns.adobe.com/xap/1.0/" xmlns:pdf="http://ns.adobe.com/pdf/1.3/" xmlns:dc="http://purl.org/dc/elements/1.1/" rdf:about="">
            <xmp:CreateDate>2025-04-02T14:03:42Z</xmp:CreateDate>
            <xmp:CreatorTool>Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/134.0.0.0 Safari/537.36</xmp:CreatorTool>
            <xmp:ModifyDate>2025-04-02T14:03:42Z</xmp:ModifyDate>
            <pdf:Producer>Skia/PDF m134</pdf:Producer>
            <dc:title>
              <rdf:Alt>
                <rdf:li xml:lang="x-default">Golden Sample PDF</rdf:li>
              </rdf:Alt>
            </dc:title>
          </rdf:Description>
        </rdf:RDF>
      </x:xmpmeta>
    XMP

    actual_xml = Nokogiri::XML(xmp["xmp_data"], &:noblanks)
    expected_xml = Nokogiri::XML(expected_xmp, &:noblanks)

    expect(actual_xml.to_s).to eq(expected_xml.to_s)
  end

  it "can handle nil" do
    file = fixture_file_clone("sample.pdf")

    described_class.xmp_to_file file.path, nil, override: true

    xmp = described_class.xmp_from_file(file.path)

    expected_xmp = <<~XMP
        <x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="XMP Core 6.0.0">
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <rdf:Description xmlns:xmp="http://ns.adobe.com/xap/1.0/" rdf:about="">
              <xmp:CreateDate>2025-06-04T20:20:40+02:00</xmp:CreateDate>
              <xmp:ModifyDate>2025-06-04T20:20:40+02:00</xmp:ModifyDate>
          </rdf:Description>
        </rdf:RDF>
      </x:xmpmeta>
    XMP

    actual_xml = Nokogiri::XML(xmp["xmp_data"], &:noblanks)
    expected_xml = Nokogiri::XML(expected_xmp, &:noblanks)

    metadata_date_node = actual_xml.at_xpath("//xmp:CreateDate", "xmp" => XmpToolkitRuby::Namespaces::XMP_NS_XMP)
    metadata_date_node.content = "DUMMY_DATE" if metadata_date_node
    metadata_date_node = actual_xml.at_xpath("//xmp:ModifyDate", "xmp" => XmpToolkitRuby::Namespaces::XMP_NS_XMP)
    metadata_date_node.content = "DUMMY_DATE" if metadata_date_node

    expected_date_node = expected_xml.at_xpath("//xmp:CreateDate", "xmp" => XmpToolkitRuby::Namespaces::XMP_NS_XMP)
    expected_date_node.content = "DUMMY_DATE" if expected_date_node
    expected_date_node = expected_xml.at_xpath("//xmp:ModifyDate", "xmp" => XmpToolkitRuby::Namespaces::XMP_NS_XMP)
    expected_date_node.content = "DUMMY_DATE" if expected_date_node

    expect(actual_xml.to_s).to eq(expected_xml.to_s)
  end

  it "can override existing XMP data" do
    new_xmp = <<~XMP
        <x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="XMP Core 6.0.0">
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <rdf:Description xmlns:xmp="http://ns.adobe.com/xap/1.0/" xmlns:dc="http://purl.org/dc/elements/1.1/" rdf:about="">
             <xmp:MetadataDate>2025-06-04T15:06:05+02:00</xmp:MetadataDate>
             <dc:subject>
                  <rdf:Bag>
                     <rdf:li>XMP</rdf:li>
                     <rdf:li>Blue Square</rdf:li>
                     <rdf:li>test file</rdf:li>
                     <rdf:li>Photoshop</rdf:li>
                     <rdf:li>.psd</rdf:li>
                  </rdf:Bag>
               </dc:subject>
          </rdf:Description>
        </rdf:RDF>
      </x:xmpmeta>
    XMP
    file = fixture_file_clone("sample.pdf")

    described_class.xmp_to_file file.path, new_xmp, override: true

    xmp = described_class.xmp_from_file(file.path)
    actual_xml = Nokogiri::XML(xmp["xmp_data"], &:noblanks)
    expected_xml = Nokogiri::XML(new_xmp, &:noblanks)

    metadata_date_node = actual_xml.at_xpath("//xmp:MetadataDate", "xmp" => XmpToolkitRuby::Namespaces::XMP_NS_XMP)
    metadata_date_node.content = "DUMMY_DATE" if metadata_date_node

    expected_date_node = expected_xml.at_xpath("//xmp:MetadataDate", "xmp" => XmpToolkitRuby::Namespaces::XMP_NS_XMP)
    expected_date_node.content = "DUMMY_DATE" if expected_date_node

    expect(actual_xml.to_s).to eq(expected_xml.to_s)
  end

  it "can upsert existing XMP data" do
    new_xmp = <<~XMP
        <x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="XMP Core 6.0.0">
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <rdf:Description xmlns:xmp="http://ns.adobe.com/xap/1.0/" xmlns:dc="http://purl.org/dc/elements/1.1/" rdf:about="">
             <xmp:MetadataDate>2025-06-04T15:06:05+02:00</xmp:MetadataDate>
             <dc:subject>
                  <rdf:Bag>
                     <rdf:li>XMP</rdf:li>
                     <rdf:li>Blue Square</rdf:li>
                     <rdf:li>test file</rdf:li>
                     <rdf:li>Photoshop</rdf:li>
                     <rdf:li>.psd</rdf:li>
                  </rdf:Bag>
               </dc:subject>
          </rdf:Description>
        </rdf:RDF>
      </x:xmpmeta>
    XMP
    file = fixture_file_clone("sample.pdf")

    described_class.xmp_to_file file.path, new_xmp, override: false

    xmp = described_class.xmp_from_file(file.path)

    expected_xmp = <<~XMP
        <x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="XMP Core 6.0.0">
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <rdf:Description xmlns:xmp="http://ns.adobe.com/xap/1.0/" xmlns:pdf="http://ns.adobe.com/pdf/1.3/"  xmlns:dc="http://purl.org/dc/elements/1.1/" rdf:about="">
             <xmp:CreateDate>2025-04-02T14:03:42Z</xmp:CreateDate>
             <xmp:CreatorTool>Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/134.0.0.0 Safari/537.36</xmp:CreatorTool>
             <xmp:ModifyDate>2025-04-02T14:03:42Z</xmp:ModifyDate>
             <xmp:MetadataDate>2025-06-04T15:06:05+02:00</xmp:MetadataDate>
             <pdf:Producer>Skia/PDF m134</pdf:Producer>
             <dc:title>
              <rdf:Alt>
                 <rdf:li xml:lang="x-default">Golden Sample PDF</rdf:li>
              </rdf:Alt>
             </dc:title>
             <dc:subject>
                  <rdf:Bag>
                     <rdf:li>XMP</rdf:li>
                     <rdf:li>Blue Square</rdf:li>
                     <rdf:li>test file</rdf:li>
                     <rdf:li>Photoshop</rdf:li>
                     <rdf:li>.psd</rdf:li>
                  </rdf:Bag>
               </dc:subject>
          </rdf:Description>
        </rdf:RDF>
      </x:xmpmeta>
    XMP

    actual_xml = Nokogiri::XML(xmp["xmp_data"], &:noblanks)
    expected_xml = Nokogiri::XML(expected_xmp, &:noblanks)

    metadata_date_node = actual_xml.at_xpath("//xmp:MetadataDate", "xmp" => XmpToolkitRuby::Namespaces::XMP_NS_XMP)
    metadata_date_node.content = "DUMMY_DATE" if metadata_date_node

    expected_date_node = expected_xml.at_xpath("//xmp:MetadataDate", "xmp" => XmpToolkitRuby::Namespaces::XMP_NS_XMP)
    expected_date_node.content = "DUMMY_DATE" if expected_date_node

    expect(actual_xml.to_s).to eq(expected_xml.to_s)
  end

  it "detects the correct format" do
    xmp = described_class.xmp_from_file(xmp_toolkit_fixture_file("BlueSquare.png"))

    expect(XmpToolkitRuby::XmpFileFormat.name_for(xmp["format_orig"])).to eq(:kXMP_PNGFile)
  end

  it "detects the correct handler flags" do
    xmp = described_class.xmp_from_file(xmp_toolkit_fixture_file("BlueSquare.png"))

    expect(xmp["handler_flags"]).to include(
                                      :can_inject_xmp,
                                      :can_expand,
                                      :prefers_in_place,
                                      :allows_only_xmp,
                                      :returns_raw_packet,
                                      :needs_read_only_packet
                                    )
  end

  context "when extracting XMP data from various files" do
    %w[
      BlueSquare.ai BlueSquare.avi BlueSquare.eps BlueSquare.indd BlueSquare.jpg BlueSquare.mov BlueSquare.mp3 BlueSquare.pdf
      BlueSquare.png BlueSquare.psd BlueSquare.tif BlueSquare.wav Image1.jpg Image2.jpg
     ].each do |filename|
      let(:file_path) { xmp_toolkit_fixture_file(filename) }

      it "extracts XMP data from #{File.extname(filename)} (#{filename})" do
        xmp = described_class.xmp_from_file(file_path)

        expect(xmp["xmp_data"]).to include("<photoshop:DateCreated>2003-02-04T08:06:18Z</photoshop:DateCreated>")
      end
    end
  end
end
