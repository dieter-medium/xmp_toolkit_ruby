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
**Linux example (adjust paths/versions as needed):**

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

**See [Adobe’s docs](https://github.com/adobe/XMP-Toolkit-SDK) for details on other platforms.**

---

### 2. Install the Gem

**Bundler:**

```bash
bundle config set --local build.xmp_toolkit_ruby "--with-xmp-lib=/path/to/XMP-Toolkit-SDK/public/libraries/i80386linux_x64/debug --with-xmp-include=/path/to/XMP-Toolkit-SDK/public/include"
bundle add xmp_toolkit_ruby
```

**Or, with plain RubyGems:**

```bash
gem install xmp_toolkit_ruby --   --with-xmp-lib /path/to/XMP-Toolkit-SDK/public/libraries/i80386linux_x64/debug   --with-xmp-include /path/to/XMP-Toolkit-SDK/public/include
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
```

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
