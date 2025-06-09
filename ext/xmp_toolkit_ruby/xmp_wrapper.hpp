#ifndef XMP_WRAPPER_HPP
#define XMP_WRAPPER_HPP

struct XMPWrapper {
  SXMPMeta *xmpMeta;
  SXMPFiles *xmpFile;
  bool xmpMetaDataLoaded;
  std::mutex mutex;  // Protects all mutable members
};

VALUE xmpwrapper_allocate(VALUE klass);

VALUE register_namespace(VALUE self, VALUE rb_namespaceURI, VALUE rb_suggestedPrefix);

VALUE xmpwrapper_open_file(int argc, VALUE *argv, VALUE self);

VALUE xmpwrapper_set_property(VALUE self, VALUE rb_ns, VALUE rb_prop, VALUE rb_value);
VALUE xmpwrapper_update_localized_text(int argc, VALUE *argv, VALUE self);

VALUE write_xmp(VALUE self);

VALUE xmpwrapper_close_file(VALUE self);

#endif