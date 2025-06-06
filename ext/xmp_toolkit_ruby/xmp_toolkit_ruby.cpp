// xmp_init.cpp

#include "xmp_toolkit.hpp"
#include <ruby.h>

// The one and only Init function.  Ruby will look for Init_xmp_toolkit_ruby
// because we will (in extconf.rb) build this extension as “xmp_toolkit_ruby.so”.
extern "C"
void Init_xmp_toolkit_ruby()
{

   SXMPMeta::SetDefaultErrorCallback(
        xmp_meta_error_callback,
        nullptr,
        0
    );

    SXMPFiles::SetDefaultErrorCallback(
            xmp_file_error_callback,
            nullptr,
            0
   );

   VALUE mXmpToolkitRuby = rb_define_module("XmpToolkitRuby");
   VALUE mXMPToolkit = rb_define_module_under(mXmpToolkitRuby, "XmpToolkit");

   rb_define_singleton_method(mXMPToolkit,
                              "initialize_xmp",
                              RUBY_METHOD_FUNC(xmp_initialize),
                              -1);
   rb_define_singleton_method(mXMPToolkit,
                              "terminate",
                              RUBY_METHOD_FUNC(xmp_terminate),
                              0);
   rb_define_singleton_method(mXMPToolkit,
                              "read_xmp",
                              RUBY_METHOD_FUNC(get_xmp_from_file),
                              1);
 rb_define_singleton_method(mXMPToolkit,
                              "write_xmp",
                              RUBY_METHOD_FUNC(write_xmp_to_file),
                              -1);

}
