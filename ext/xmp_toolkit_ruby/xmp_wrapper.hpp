#ifndef XMP_WRAPPER_HPP
#define XMP_WRAPPER_HPP

#include <mutex>

struct XMPWrapper {
  SXMPMeta *xmpMeta;
  SXMPFiles *xmpFile;
  XMP_PacketInfo *xmpPacket;
  bool xmpMetaDataLoaded;
  std::mutex mutex;  // Protects all mutable members
};

VALUE xmpwrapper_allocate(VALUE klass);

VALUE register_namespace(VALUE self, VALUE rb_namespaceURI, VALUE rb_suggestedPrefix);

VALUE xmpwrapper_open_file(int argc, VALUE *argv, VALUE self);

VALUE xmp_file_info(VALUE self);
VALUE xmp_packet_info(VALUE self);

VALUE xmp_meta(VALUE self);
VALUE xmpwrapper_get_property(VALUE self, VALUE rb_ns, VALUE rb_prop);
VALUE xmpwrapper_get_localized_text(int argc, VALUE *argv, VALUE self);

VALUE xmpwrapper_set_meta(int argc, VALUE *argv, VALUE self);
VALUE xmpwrapper_set_property(VALUE self, VALUE rb_ns, VALUE rb_prop, VALUE rb_value);
VALUE xmpwrapper_update_localized_text(int argc, VALUE *argv, VALUE self);

VALUE write_xmp(VALUE self);

VALUE xmpwrapper_close_file(VALUE self);

#endif