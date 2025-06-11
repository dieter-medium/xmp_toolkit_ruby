# XmpToolkitRuby

[![Gem Version](https://badge.fury.io/rb/xmp_toolkit_ruby.svg)](https://badge.fury.io/rb/xmp_toolkit_ruby)

**XmpToolkitRuby** is a Ruby gem that provides fast, native bindings to
the [Adobe XMP Toolkit](https://github.com/adobe/XMP-Toolkit-SDK), enabling Ruby applications to **read and write XMP
metadata** in various file formats (images, PDFs, etc.).

---

- **Full XMP read/write support**
- **Works with PNG, JPEG, TIFF, PDF, and more**
- **Command-line interface & Ruby API**
- **Works on Linux, macOS, and via Docker**

---

## Installation

**Recommended:** Compile natively on your target system for best performance and compatibility.  
A precompiled extension may be available for some platforms.

### 1. Get the Adobe XMP Toolkit

First, clone and prepare the Adobe XMP Toolkit SDK.

#### Linux example (adjust paths/versions as needed)

```bash
export XMP_TOOLKIT_SDK_VERSION=2025.03

# Prerequisites
sudo apt update && sudo apt install cmake build-essential curl

# Download and extract the SDK
mkdir XMP-Toolkit-SDK
cd XMP-Toolkit-SDK
curl -LO https://github.com/adobe/XMP-Toolkit-SDK/archive/refs/tags/v${XMP_TOOLKIT_SDK_VERSION}.tar.gz 
tar -xzf v${XMP_TOOLKIT_SDK_VERSION}.tar.gz --strip-components=1

# Prepare required third-party libraries
cd third-party

# zlib
cd zlib
curl -O https://zlib.net/zlib.tar.gz
tar --strip-components=1 -xzf zlib.tar.gz
cd ..

# expat
cd expat
curl -LO https://github.com/libexpat/libexpat/releases/download/R_2_5_0/expat-2.5.0.tar.gz
tar --strip-components=1  -xzf expat-2.5.0.tar.gz
cd ../..

# Build instructions
cd build
# ⚠️ Patch required: Remove `${XMP_GCC_LIBPATH}/libssp.a` from `ProductConfig.cmake` (see [this issue](https://github.com/adobe/XMP-Toolkit-SDK/issues/8))
# Optionally, disable secure settings in `shared/ToolchainGCC.cmake`:
#   -set(XMP_ENABLE_SECURE_SETTINGS "ON")
#   +set(XMP_ENABLE_SECURE_SETTINGS "OFF")
make
```

#### macOS example

When you copy and paste the following commands, make sure that during the paste nothing got escaped (e.g.  `{` becomes
`\{`).

```bash
export XMP_TOOLKIT_SDK_VERSION=2025.03

xcode-select --install # Ensure Xcode command line tools are selected

# within a directory of your choice

mkdir XMP-Toolkit-SDK

cd XMP-Toolkit-SDK
curl -LO https://github.com/adobe/XMP-Toolkit-SDK/archive/refs/tags/v${XMP_TOOLKIT_SDK_VERSION}.tar.gz 
tar -xzf v${XMP_TOOLKIT_SDK_VERSION}.tar.gz --strip-components=1

# Prepare required third-party libraries
cd third-party

# zlib
cd zlib
curl -O https://zlib.net/zlib.tar.gz
tar --strip-components=1 -xzf zlib.tar.gz
cd ..

# expat
cd expat
curl -LO https://github.com/libexpat/libexpat/releases/download/R_2_5_0/expat-2.5.0.tar.gz
tar --strip-components=1  -xzf expat-2.5.0.tar.gz
cd ../..

# cmake
cd tools/cmake
mkdir  bin
cd bin
curl -LO https://cmake.org/files/v3.15/cmake-3.15.5-Darwin-x86_64.tar.gz
tar --strip-components=1  -xzf cmake-3.15.5-Darwin-x86_64.tar.gz
cd ../../..

cd build
./GenerateXMPToolkitSDK_mac.sh

# choose 3 => Generate XMPToolkitSDK Static  64


cd xcode/static/universal/

# I needed to patch SDKROOT from macOS 13.1 SDK to 15.1 SDK in two places inside the Xcode project file:
# 
# From:
# SDKROOT = /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.1.sdk;
#
# To:
# SDKROOT = /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX15.1.sdk;
#
# The following sed script replaces both occurrences in-place, backing up the original file with a .bak extension:
#
# Usage:
#   sed -i.bak -E 's|(SDKROOT = /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX)13\.1(\.sdk;)|\115.1\2|g' ./XMPToolkitSDK64.xcodeproj/project.pbxproj
#
# Explanation:
# - The regex captures the prefix and suffix around "13.1" to ensure only the SDK version number is replaced.
# - The 'g' flag ensures all matching lines (both places) are updated.


# Build Debug configuration
xcodebuild -scheme ALL_BUILD -configuration Debug build

# Build Release configuration
xcodebuild -scheme ALL_BUILD -configuration Release build

```

**See [Adobe’s docs](https://github.com/adobe/XMP-Toolkit-SDK) for details on other platforms.**

---

### 2. Install the Gem

**Bundler:**

```bash
# for linux 
bundle config set --local build.xmp_toolkit_ruby "--with-xmp-lib=/path/to/XMP-Toolkit-SDK/public/libraries/i80386linux_x64/debug --with-xmp-include=/path/to/XMP-Toolkit-SDK/public/include"
# for macOS
bundle config set --local build.xmp_toolkit_ruby "--with-xmp-lib=/path/to/XMP-Toolkit-SDK/public/libraries/macintosh/universal/Debug --with-xmp-include=/path/to/XMP-Toolkit-SDK/public/include"

bundle add xmp_toolkit_ruby
```

**Or, with plain RubyGems:**

```bash
# for linux 
gem install xmp_toolkit_ruby -- --with-xmp-lib /path/to/XMP-Toolkit-SDK/public/libraries/i80386linux_x64/debug --with-xmp-include /path/to/XMP-Toolkit-SDK/public/include
# for macOS
gem install xmp_toolkit_ruby -- --with-xmp-lib /path/to/XMP-Toolkit-SDK/public/libraries/macintosh/universal/Debug --with-xmp-include /path/to/XMP-Toolkit-SDK/public/include
```

_Replace paths as needed for your environment._

---

## Precompiled Binaries and Platform Support

This gem **ships with precompiled binaries** for the native libraries `libxmpcore` and `libxmpfile` for common
platforms.

> ⚠️ **Note:**  
> These precompiled binaries may **not work on your system**, especially if your OS, architecture, or C++ standard
> library differs from those used to build the binaries.  
> For maximum compatibility, **it is strongly recommended to compile the native libraries yourself** on your target
> machine.

If you encounter issues or want maximum portability, please build the SDK from source using the instructions above.

**Tip:**  
Check out [`docker/Dockerfile`](docker/Dockerfile) in this repository for a full working example of a native build
setup, including all dependencies and configuration flags.

---

## Usage

### In Ruby

```ruby
require "xmp_toolkit_ruby"

xmp = XmpToolkitRuby.xmp_from_file("BlueSquare.png")

pp xmp.keys
puts xmp["xmp_data"]

new_xmp = <<~XMP
  <x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="XMP Core 6.0.0">
    <rdf:RDF xmlns:rdf="#{XmpToolkitRuby::Namespaces::XMP_NS_RDF}">
      <rdf:Description xmlns:xmp="#{XmpToolkitRuby::Namespaces::XMP_NS_XMP}" rdf:about="">
        <xmp:CreateDate>2025-06-04T20:20:40+02:00</xmp:CreateDate>
        <xmp:ModifyDate>2025-06-04T20:20:40+02:00</xmp:ModifyDate>
      </rdf:Description>
    </rdf:RDF>
  </x:xmpmeta>
XMP

XmpToolkitRuby.xmp_to_file(
  "BlueSquare.png",
  new_xmp,
  override: true # Set to false to upsert/merge instead of replacing
)

# fine-grained control

# if you want to take full control over the SDK lifecycle
# you can use the XmpToolkitRuby::XmpToolkit module directly:
XmpToolkitRuby::XmpToolkit.initialize_xmp(XmpToolkitRuby::PLUGINS_PATH)
# in this case you can call here 
XmpToolkitRuby::XmpFile.register_namespace XmpToolkitRuby::Namespaces::XMP_NS_PDFUA_ID, "pdfuaid"

XmpToolkitRuby::XmpFile.with_xmp_file(filename, open_flags: XmpToolkitRuby::XmpFileOpenFlags.bitmask_for(:open_for_update, :open_use_smart_handler, auto_terminate_toolkit: false)) do |xmp_file|
  # in case the lifecycle is managed by with_xmp_file
  XmpToolkitRuby::XmpFile.register_namespace XmpToolkitRuby::Namespaces::XMP_NS_PDFUA_ID, "pdfuaid"

  xmp_file.update_localized_property schema_ns: XmpToolkitRuby::Namespaces::XMP_NS_DC,
                                     alt_text_name: "title",
                                     generic_lang: "en",
                                     specific_lang: "en-US",
                                     item_value: "Hello world",
                                     options: 0

  xmp_file.update_property XmpToolkitRuby::Namespaces::XMP_NS_PDFUA_ID, "part", "1"
end

# if auto_terminate_toolkit is false, you must call
XmpToolkitRuby::XmpToolkit.terminate
# to clean up resources
```

If you built the XMP Toolkit yourself or store the plugins elsewhere,
set the `XMP_TOOLKIT_PLUGINS_PATH` environment variable so the gem can
locate the PDF handler:

```bash
export XMP_TOOLKIT_PLUGINS_PATH=/path/to/XMP-Toolkit-SDK/XMPFilesPlugins/PDF_Handler/<platform>
```

Run your Ruby code or CLI commands in the same shell so this variable is
visible.

#### Fine-grained Control with `XmpFile`

The `XmpToolkitRuby::XmpFile` class exposes low-level access to XMP metadata files, allowing you to:

- Register new or custom namespaces to extend XMP property support
- Open files with precise control over file open modes and handlers
- Update localized properties (e.g., multi-language text with alternatives)
- Update simple properties in specified namespaces
- Use blocks to ensure file handles are properly closed and changes saved

In order to work properly you need to ensure the XMP Toolkit is initialized:

```ruby
XmpToolkitRuby::XmpToolkit.initialize_xmp(XmpToolkitRuby::PLUGINS_PATH)
```

Alternatively, you can use the `with_xmp_file` method which automatically initializes and terminates the toolkit.

##### Registering a Namespace

Before working with properties in custom or less-common namespaces, you need to register them with a prefix:

```ruby
XmpToolkitRuby::XmpFile.register_namespace XmpToolkitRuby::Namespaces::XMP_NS_PDFUA_ID, "pdfuaid"
```

This allows the SDK to recognize and correctly handle properties within that namespace.

##### Opening a File with Custom Flags

You can open an XMP file with specific flags to control behavior:

- `open_for_update`: Open the file for modifying metadata
- `open_use_smart_handler`: Use smart handlers for better metadata processing

Flags are combined via the `bitmask_for` helper method:

```ruby
flags = XmpToolkitRuby::XmpFileOpenFlags.bitmask_for(:open_for_update, :open_use_smart_handler)
```

Open the file in a block to ensure safe usage:

```ruby
XmpToolkitRuby::XmpFile.with_xmp_file(filename, open_flags: flags) do |xmp_file|
  # work with xmp_file inside this block
end
```

##### Updating a Localized Property

Localized properties support multiple language alternatives. Use `update_localized_property` with options:

- `schema_ns`: Namespace URI for the schema (e.g., Dublin Core)
- `alt_text_name`: The property name that holds alternative texts
- `generic_lang`: Language tag for the generic language (e.g., `"en"`)
- `specific_lang`: Specific locale variant (e.g., `"en-US"`)
- `item_value`: The actual text value to set
- `options`: Optional flags (typically 0)

Example:

```ruby
xmp_file.update_localized_property(
  schema_ns: XmpToolkitRuby::Namespaces::XMP_NS_DC,
  alt_text_name: "title",
  generic_lang: "en",
  specific_lang: "en-US",
  item_value: "Hello world",
  options: 0
)
```

This sets or updates the localized `"title"` property in English (US).

##### Updating a Simple Property

For simpler property updates without localization, use `update_property`:

```ruby
xmp_file.update_property(
  XmpToolkitRuby::Namespaces::XMP_NS_PDFUA_ID,
  "part",
  "1"
)
```

This updates the `"part"` property within the PDF/UA ID namespace.

---

##### Summary

The fine-grained control API empowers you to work precisely with metadata:

- Register custom namespaces for extended support
- Open files with control over update modes and handlers
- Modify localized text properties with language variants
- Update simple XMP properties by namespace and name

Using these methods allows sophisticated metadata management, crucial for professional publishing, digital asset
management, or compliance workflows.

---

### CLI

The gem ships with a `xmp_toolkit_ruby` command for basic operations:

```bash
# Print XMP metadata to stdout
xmp_toolkit_ruby print_xmp BlueSquare.png

# Print XMP metadata and save to a file
xmp_toolkit_ruby print_xmp BlueSquare.png xmp_metadata.xml

# Update XMP metadata (replace/merge)
xmp_toolkit_ruby override_xmp --override BlueSquare.png xmp_metadata.xml 
```

---

### Docker

You can run the CLI tool via Docker without installing any build tools:

```bash
docker run -it --rm   -v $(pwd):/workspace   dieters877565/xmp-toolkit-ruby:main   xmp_toolkit_ruby print_xmp /workspace/BlueSquare.png
```

---

## Development

1. **Clone the repo**
2. `bin/setup` to install dependencies
3. `rake spec` to run tests
4. `bin/console` for an interactive shell

Build & install locally with:

```bash
bundle exec rake install
```

Release process:

- Bump the version in `lib/xmp_toolkit_ruby/version.rb`
- `bundle exec rake release` to tag, push, and publish to [rubygems.org](https://rubygems.org)

---

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/DieterS/xmp_toolkit_ruby).

---

## License

This project is open source, licensed under the [MIT License](https://opensource.org/licenses/MIT).

---
