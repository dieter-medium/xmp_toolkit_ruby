# frozen_string_literal: true

# extconf.rb
require "mkmf"

# Makes all symbols private by default to avoid unintended conflict
# with other gems. To explicitly export symbols you can use RUBY_FUNC_EXPORTED
# selectively, or entirely remove this flag.
append_cflags("-fvisibility=hidden")

XML_TOOLKIT_RUBY_HELP_MESSAGE = <<~HELP.freeze
  It's recommended to use the compile Adobe XMP-Toolkit-SDK https://github.com/adobe/XMP-Toolkit-SDK/tree/main first#{" "}

  USAGE: ruby #{$PROGRAM_NAME} [options]

  Options:
    --help, -h          Show this help message

    --with-xmp-dir=DIR
        Look for headers and libraries in DIRECTORY form the Adobe XMP-Toolkit-SDK.

    --with-xmp-lib=DIRECTORY
        Look for libraries in DIRECTORY.

    --with-xmp-include=DIRECTORY
        Look for headers in DIRECTORY.
HELP

def do_help
  print(XML_TOOLKIT_RUBY_HELP_MESSAGE)
  exit!(0)
end

do_help if arg_config("--help")

# Name of the extension (“xmp_toolkit_ruby” → xmp_toolkit_ruby.so/.bundle, etc.)
extension_name = "xmp_toolkit_ruby/xmp_toolkit_ruby"

# If you have any headers in a custom directory, you can do:
# dir_config('xmp_toolkit_ruby', '/usr/local/include/…', '/usr/local/lib/…')

# Since we’re compiling C++ code, tell mkmf to use the C++ compiler:
# (On some platforms you might need to adjust this—sometimes mkmf picks C by default.)
# $CXXFLAGS << ' -std=c++11 '

if with_config("xmp-dir")
  xmp_include_dir, xmp_lib_dir = dir_config('xmp')

  # Add the custom directories to search paths
  $INCFLAGS << " -I#{xmp_include_dir}"
  $INCFLAGS << " -I#{xmp_include_dir}/client-glue"

  xmp_lib_path = xmp_lib_dir
else
  $INCFLAGS << " -I$(srcdir)/XMP-Toolkit-SDK/public/include"
  $INCFLAGS << " -I$(srcdir)/XMP-Toolkit-SDK/public/include/client-glue"
  $INCFLAGS << " -I$(srcdir)/XMP-Toolkit-SDK/"

  if (RbConfig::CONFIG["host_os"] =~ /darwin/) && RbConfig::CONFIG["host_cpu"] !~ /arm64/
    xmp_lib_path = "$(srcdir)/XMP-Toolkit-SDK/public/libraries/macintosh/universal/Debug"
  elsif RbConfig::CONFIG["host_os"] =~ /linux/ && RbConfig::CONFIG["host_cpu"] =~ /x86_64|amd64/
    xmp_lib_path = "$(srcdir)/XMP-Toolkit-SDK/public/libraries/i80386linux_x64/debug"
  else
    abort("ERROR: libXMPCoreStatic and  libXMPFilesStatic is required!")
  end
end
$CXXFLAGS << " -std=c++17"

if RbConfig::CONFIG["host_os"] =~ /darwin/
  $LDFLAGS << " -Wl,-search_paths_first -Wl,-headerpad_max_install_names -Wl,-multiply_defined,suppress"
  $LDFLAGS << " -L#{xmp_lib_path} -lXMPCoreStatic -lXMPFilesStatic"
  $LDFLAGS << " -Wl,-undefined,dynamic_lookup"
elsif RbConfig::CONFIG["host_os"] =~ /linux/ && RbConfig::CONFIG["host_cpu"] =~ /x86_64|amd64/
  xmp_lib_path = "$(srcdir)/XMP-Toolkit-SDK/public/libraries/i80386linux_x64/debug"

  $LDFLAGS << " -L#{xmp_lib_path} -lXMPCoreStatic -lXMPFilesStatic"
end

# Define XMP environment based on host OS
case RbConfig::CONFIG["host_os"]
when /mac|darwin/
  $defs << "-DMAC_ENV=1"
when /linux/
  $defs << "-DUNIX_ENV=1"
when /mswin|mingw|cygwin/
  $defs << "-DWIN_ENV=1"
else
  # You might want to raise an error or default to UNIX_ENV
  # For now, let's default to UNIX_ENV if unsure, or you can make it an error
  warn "Unsupported OS for XMP environment: #{RbConfig::CONFIG["host_os"]}. Defaulting to UNIX_ENV."
  $defs << "-DUNIX_ENV=1"
end

$defs << "-DXMP_COMPONENT_INT_NAMESPACE=AdobeXMPCore_Int"
$defs << "-DXMP_StaticBuild=1"
$defs << "-DXMP_COMPONENTS_VERSION=0x60000000"
$defs << "-DXMP_PUBLIC_APIS=1"
$defs << "-DBUILDING_XMPCOMMON=1"

# Create the Makefile
create_makefile(extension_name)
