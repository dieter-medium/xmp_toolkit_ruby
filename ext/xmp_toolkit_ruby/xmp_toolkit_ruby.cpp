// xmp_init.cpp

#include "xmp_toolkit.hpp"
#include "xmp_wrapper.hpp"

#include <ruby.h>

// The one and only Init function.  Ruby will look for Init_xmp_toolkit_ruby
// because we will (in extconf.rb) build this extension as “xmp_toolkit_ruby.so”.
RUBY_FUNC_EXPORTED "C" void Init_xmp_toolkit_ruby() {
  SXMPMeta::SetDefaultErrorCallback(xmp_meta_error_callback, nullptr, 0);

  SXMPFiles::SetDefaultErrorCallback(xmp_file_error_callback, nullptr, 0);

  VALUE mXmpToolkitRuby = rb_define_module("XmpToolkitRuby");
  VALUE mXMPToolkit = rb_define_module_under(mXmpToolkitRuby, "XmpToolkit");

  rb_define_singleton_method(mXMPToolkit, "initialize_xmp", RUBY_METHOD_FUNC(xmp_initialize), -1);
  rb_define_singleton_method(mXMPToolkit, "terminate", RUBY_METHOD_FUNC(xmp_terminate), 0);
  rb_define_singleton_method(mXMPToolkit, "initialized?", RUBY_METHOD_FUNC(is_sdk_initialized), 0);

  VALUE cXMPWrapper = rb_define_class_under(mXmpToolkitRuby, "XmpWrapper", rb_cObject);

  rb_define_alloc_func(cXMPWrapper, xmpwrapper_allocate);
  rb_define_method(cXMPWrapper, "open", RUBY_METHOD_FUNC(xmpwrapper_open_file), -1);
  rb_define_method(cXMPWrapper, "file_info", RUBY_METHOD_FUNC(xmp_file_info), 0);
  rb_define_method(cXMPWrapper, "packet_info", RUBY_METHOD_FUNC(xmp_packet_info), 0);
  rb_define_method(cXMPWrapper, "meta", RUBY_METHOD_FUNC(xmp_meta), 0);
  rb_define_method(cXMPWrapper, "property", RUBY_METHOD_FUNC(xmpwrapper_get_property), 2);
  rb_define_method(cXMPWrapper, "localized_property", RUBY_METHOD_FUNC(xmpwrapper_get_localized_text), -1);
  rb_define_method(cXMPWrapper, "update_meta", RUBY_METHOD_FUNC(xmpwrapper_set_meta), -1);
  rb_define_method(cXMPWrapper, "update_property", RUBY_METHOD_FUNC(xmpwrapper_set_property), 3);
  rb_define_method(cXMPWrapper, "update_localized_property", RUBY_METHOD_FUNC(xmpwrapper_update_localized_text), -1);
  rb_define_method(cXMPWrapper, "write", RUBY_METHOD_FUNC(write_xmp),
                   0);  // close flushes the file until then the data is not guaranteed to be written
  rb_define_method(cXMPWrapper, "close", RUBY_METHOD_FUNC(xmpwrapper_close_file), 0);
  rb_define_singleton_method(cXMPWrapper, "register_namespace", RUBY_METHOD_FUNC(register_namespace), 2);
}
