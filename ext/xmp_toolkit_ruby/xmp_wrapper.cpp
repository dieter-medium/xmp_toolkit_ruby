#include "xmp_toolkit.hpp"
#include "xmp_wrapper.hpp"

#include <mutex>

static size_t xmpwrapper_memsize(const void *ptr) { return sizeof(XMPWrapper); }

static void check_wrapper_initialized(XMPWrapper *wrapper) {
  if (wrapper->xmpFile == nullptr || wrapper->xmpMeta == nullptr || wrapper->xmpPacket == nullptr) {
    rb_raise(rb_eRuntimeError, "XMP file or metadata not initialized or file not opened");
  }
}

static void clean_wrapper(XMPWrapper *wrapper) {
  if (wrapper->xmpFile) {
    wrapper->xmpFile->CloseFile();
    delete wrapper->xmpFile;
    wrapper->xmpFile = nullptr;
  }
  if (wrapper->xmpMeta) {
    delete wrapper->xmpMeta;
    wrapper->xmpMeta = nullptr;
  }
  if (wrapper->xmpPacket) {
    delete wrapper->xmpPacket;
    wrapper->xmpPacket = nullptr;
  }

  wrapper->xmpMetaDataLoaded = false;
}

static void xmpwrapper_free(void *ptr) {
  XMPWrapper *wrapper = static_cast<XMPWrapper *>(ptr);
  if (wrapper) {
    clean_wrapper(wrapper);

    delete wrapper;
  }
}

static const rb_data_type_t xmpwrapper_data_type = {"XMPWrapper",
                                                    {
                                                        0,
                                                        xmpwrapper_free,
                                                        xmpwrapper_memsize,
                                                    },
                                                    0,
                                                    0,
                                                    RUBY_TYPED_FREE_IMMEDIATELY};

VALUE
xmpwrapper_allocate(VALUE klass) {
  XMPWrapper *wrapper = new XMPWrapper();
  wrapper->xmpMeta = nullptr;
  wrapper->xmpFile = nullptr;
  wrapper->xmpPacket = nullptr;
  wrapper->xmpMetaDataLoaded = false;
  return TypedData_Wrap_Struct(klass, &xmpwrapper_data_type, wrapper);
}

static void get_xmp(XMPWrapper *wrapper) {
  if (wrapper->xmpMetaDataLoaded) {
    return;
  }

  check_wrapper_initialized(wrapper);

  bool ok = wrapper->xmpFile->GetXMP(wrapper->xmpMeta, 0, wrapper->xmpPacket);

  if (!ok) {
    clean_wrapper(wrapper);
    rb_raise(rb_eRuntimeError, "Failed to get XMP metadata");
  }

  wrapper->xmpMetaDataLoaded = true;
}

VALUE
xmpwrapper_open_file(int argc, VALUE *argv, VALUE self) {
  ensure_sdk_initialized();

  XMPWrapper *wrapper;
  TypedData_Get_Struct(self, XMPWrapper, &xmpwrapper_data_type, wrapper);

  if (wrapper->xmpFile != nullptr) {
    rb_raise(rb_eRuntimeError, "File already opened");
  }

  VALUE rb_filename = Qnil;
  VALUE rb_opts_mask = Qnil;
  rb_scan_args(argc, argv, "11", &rb_filename, &rb_opts_mask);

  const char *filename = StringValueCStr(rb_filename);

  // Allocate native objects
  wrapper->xmpMeta = new SXMPMeta();
  wrapper->xmpFile = new SXMPFiles();
  wrapper->xmpPacket = new XMP_PacketInfo();

  XMP_OptionBits opts;

  if (!NIL_P(rb_opts_mask)) {
    Check_Type(rb_opts_mask, T_FIXNUM);
    opts = NUM2UINT(rb_opts_mask);
  } else {
    opts = kXMPFiles_OpenForRead | kXMPFiles_OpenUseSmartHandler;
  }

  bool ok = wrapper->xmpFile->OpenFile(filename, kXMP_UnknownFile, opts);
  if (!ok) {
    clean_wrapper(wrapper);
    rb_raise(rb_eIOError, "Failed to open file %s, try open_use_packet_scanning instead of open_use_smart_handler",
             filename);
  }

  return Qtrue;
}

VALUE
xmp_file_info(VALUE self) {
  XMPWrapper *wrapper;
  TypedData_Get_Struct(self, XMPWrapper, &xmpwrapper_data_type, wrapper);
  check_wrapper_initialized(wrapper);

  XMP_FileFormat format;
  XMP_OptionBits openFlags, handlerFlags;
  bool ok = wrapper->xmpFile->GetFileInfo(0, &openFlags, &format, &handlerFlags);
  if (!ok) {
    clean_wrapper(wrapper);
    rb_raise(rb_eRuntimeError, "Failed to get file info");
    return Qnil;
  }

  VALUE result = rb_hash_new();

  rb_hash_aset(result, rb_str_new_cstr("format"), UINT2NUM(format));
  rb_hash_aset(result, rb_str_new_cstr("handler_flags"), UINT2NUM(handlerFlags));
  rb_hash_aset(result, rb_str_new_cstr("open_flags"), UINT2NUM(openFlags));

  return result;
}

VALUE xmp_packet_info(VALUE self) {
  XMPWrapper *wrapper;
  TypedData_Get_Struct(self, XMPWrapper, &xmpwrapper_data_type, wrapper);
  check_wrapper_initialized(wrapper);

  get_xmp(wrapper);

  if (!wrapper->xmpMetaDataLoaded) {
    rb_raise(rb_eRuntimeError, "No XMP metadata loaded");
  }

  VALUE result = rb_hash_new();

  rb_hash_aset(result, rb_str_new_cstr("offset"), LONG2NUM(wrapper->xmpPacket->offset));
  rb_hash_aset(result, rb_str_new_cstr("length"), LONG2NUM(wrapper->xmpPacket->length));
  rb_hash_aset(result, rb_str_new_cstr("pad_size"), LONG2NUM(wrapper->xmpPacket->padSize));

  rb_hash_aset(result, rb_str_new_cstr("char_form"), UINT2NUM(wrapper->xmpPacket->charForm));
  rb_hash_aset(result, rb_str_new_cstr("writeable"), wrapper->xmpPacket->writeable ? Qtrue : Qfalse);
  rb_hash_aset(result, rb_str_new_cstr("has_wrapper"), wrapper->xmpPacket->hasWrapper ? Qtrue : Qfalse);
  rb_hash_aset(result, rb_str_new_cstr("pad"), UINT2NUM(wrapper->xmpPacket->pad));

  return result;
}

VALUE
xmp_meta(VALUE self) {
  XMPWrapper *wrapper;
  TypedData_Get_Struct(self, XMPWrapper, &xmpwrapper_data_type, wrapper);
  check_wrapper_initialized(wrapper);

  get_xmp(wrapper);

  if (!wrapper->xmpMetaDataLoaded) {
    rb_raise(rb_eRuntimeError, "No XMP metadata loaded");
  }

  std::string xmpString;
  wrapper->xmpMeta->SerializeToBuffer(&xmpString);

  VALUE rb_xmp_data = rb_str_new_cstr(xmpString.c_str());

  return rb_xmp_data;
}

VALUE
xmpwrapper_get_property(VALUE self, VALUE rb_ns, VALUE rb_prop) {
  XMPWrapper *wrapper;
  TypedData_Get_Struct(self, XMPWrapper, &xmpwrapper_data_type, wrapper);
  check_wrapper_initialized(wrapper);

  Check_Type(rb_ns, T_STRING);
  Check_Type(rb_prop, T_STRING);

  get_xmp(wrapper);

  if (!wrapper->xmpMetaDataLoaded) {
    rb_raise(rb_eRuntimeError, "No XMP metadata loaded");
  }

  const char *ns = StringValueCStr(rb_ns);
  const char *prop = StringValueCStr(rb_prop);

  std::string property_value;
  XMP_OptionBits options;
  bool property_exists = wrapper->xmpMeta->GetProperty(ns, prop, &property_value, &options);

  VALUE result = rb_hash_new();
  rb_hash_aset(result, rb_str_new_cstr("options"), UINT2NUM(options));
  rb_hash_aset(result, rb_str_new_cstr("exists"), property_exists ? Qtrue : Qfalse);
  rb_hash_aset(result, rb_str_new_cstr("value"), rb_str_new_cstr(property_value.c_str()));

  return result;
}

VALUE
xmpwrapper_get_localized_text(int argc, VALUE *argv, VALUE self) {
  XMPWrapper *wrapper;
  TypedData_Get_Struct(self, XMPWrapper, &xmpwrapper_data_type, wrapper);
  check_wrapper_initialized(wrapper);

  get_xmp(wrapper);

  if (!wrapper->xmpMetaDataLoaded) {
    rb_raise(rb_eRuntimeError, "No XMP metadata loaded");
  }

  VALUE kwargs;
  rb_scan_args(argc, argv, ":", &kwargs);

  // Define allowed keywords
  ID kw_table[4];

  kw_table[0] = rb_intern("schema_ns");
  kw_table[1] = rb_intern("alt_text_name");
  kw_table[2] = rb_intern("generic_lang");
  kw_table[3] = rb_intern("specific_lang");

  VALUE kw_values[4];
  kw_values[2] = rb_str_new_cstr("");  // Default for generic_lang

  rb_get_kwargs(kwargs, kw_table, 3, 1, kw_values);

  VALUE schema_ns = kw_values[0];
  VALUE alt_text_name = kw_values[1];
  VALUE generic_lang = kw_values[2];  // Will be default if not provided
  VALUE specific_lang = kw_values[3];

  if (NIL_P(generic_lang)) generic_lang = rb_str_new_cstr("");

  const char *c_schema_ns = StringValueCStr(schema_ns);
  const char *c_alt_text_name = StringValueCStr(alt_text_name);
  const char *c_generic_lang = StringValueCStr(generic_lang);
  const char *c_specific_lang = StringValueCStr(specific_lang);

  std::string actual_lang;
  std::string item_value;
  XMP_OptionBits options;

  bool array_items_exists = wrapper->xmpMeta->GetLocalizedText(c_schema_ns, c_alt_text_name, c_generic_lang,
                                                               c_specific_lang, &actual_lang, &item_value, &options);

  VALUE result = rb_hash_new();
  rb_hash_aset(result, rb_str_new_cstr("options"), UINT2NUM(options));
  rb_hash_aset(result, rb_str_new_cstr("exists"), array_items_exists ? Qtrue : Qfalse);
  rb_hash_aset(result, rb_str_new_cstr("value"), rb_str_new_cstr(item_value.c_str()));
  rb_hash_aset(result, rb_str_new_cstr("actual_lang"), rb_str_new_cstr(actual_lang.c_str()));

  return result;
}

static XMP_DateTime datetime_to_xmp(VALUE rb_value) {
  XMP_DateTime dt;

  VALUE cDateTime = rb_const_get(rb_cObject, rb_intern("DateTime"));

  if (!rb_obj_is_kind_of(rb_value, cDateTime)) {
    rb_raise(rb_eTypeError, "expected a DateTime");
  }

  dt.year = NUM2INT(rb_funcall(rb_value, rb_intern("year"), 0));
  dt.month = NUM2INT(rb_funcall(rb_value, rb_intern("month"), 0));
  dt.day = NUM2INT(rb_funcall(rb_value, rb_intern("day"), 0));
  dt.hour = NUM2INT(rb_funcall(rb_value, rb_intern("hour"), 0));
  dt.minute = NUM2INT(rb_funcall(rb_value, rb_intern("minute"), 0));
  dt.second = NUM2INT(rb_funcall(rb_value, rb_intern("second"), 0));

  VALUE offset_r = rb_funcall(rb_value, rb_intern("offset"), 0);
  VALUE num_r = rb_funcall(offset_r, rb_intern("numerator"), 0);
  VALUE den_r = rb_funcall(offset_r, rb_intern("denominator"), 0);
  long num = NUM2LONG(num_r);
  long den = NUM2LONG(den_r);

  // offset in minutes = (num/den) days * 24h * 60m
  long off_minutes = (num * 24 * 60) / den;
  long abs_off_minutes = llabs(off_minutes);

  if (off_minutes == 0)
    dt.tzSign = kXMP_TimeIsUTC;
  else if (off_minutes > 0)
    dt.tzSign = kXMP_TimeEastOfUTC;
  else
    dt.tzSign = kXMP_TimeWestOfUTC;

  dt.tzHour = (XMP_Int32)(abs_off_minutes / 60);
  dt.tzMinute = (XMP_Int32)(abs_off_minutes % 60);

  return dt;
}

VALUE
xmpwrapper_set_meta(int argc, VALUE *argv, VALUE self) {
  XMPWrapper *wrapper;
  TypedData_Get_Struct(self, XMPWrapper, &xmpwrapper_data_type, wrapper);
  check_wrapper_initialized(wrapper);

  VALUE rb_xmp_data, kwargs;
  XMP_OptionBits templateFlags =
      kXMPTemplate_AddNewProperties | kXMPTemplate_ReplaceExistingProperties | kXMPTemplate_IncludeInternalProperties;

  rb_scan_args(argc, argv, "1:", &rb_xmp_data, &kwargs);

  const char *xmpString = NULL;
  if (!NIL_P(rb_xmp_data)) {
    Check_Type(rb_xmp_data, T_STRING);
    xmpString = StringValueCStr(rb_xmp_data);
  }

  ID kw_table[1];
  kw_table[0] = rb_intern("mode");

  VALUE kw_values[1];
  kw_values[0] = rb_str_new_cstr("upsert");

  rb_get_kwargs(kwargs, kw_table, 0, 1, kw_values);

  VALUE rb_mode_sym = kw_values[0];

  const char *mode_cstr;
  if (RB_TYPE_P(rb_mode_sym, T_SYMBOL)) {
    // Convert symbol to string first
    VALUE mode_str = rb_sym_to_s(rb_mode_sym);
    mode_cstr = StringValueCStr(mode_str);
  } else {
    // Already a string
    mode_cstr = StringValueCStr(rb_mode_sym);
  }

  bool override;
  if (strcmp(mode_cstr, "upsert") == 0) {
    override = false;
  } else if (strcmp(mode_cstr, "override") == 0) {
    override = true;
  } else {
    rb_raise(rb_eArgError, "mode must be :upsert or :override (String or Symbol). Got '%s'", mode_cstr);
    return Qnil;  // unreachable, but for clarity
  }

  get_xmp(wrapper);

  SXMPMeta newMeta;

  if (xmpString != NULL) {
    int i;
    for (i = 0; i < (long)strlen(xmpString) - 10; i += 10) {
      newMeta.ParseFromBuffer(&xmpString[i], 10, kXMP_ParseMoreBuffers);
    }

    newMeta.ParseFromBuffer(&xmpString[i], (XMP_StringLen)strlen(xmpString) - i);
  }

  XMP_DateTime dt;
  SXMPUtils::CurrentDateTime(&dt);

  if (xmpString != NULL) {
    newMeta.SetProperty_Date(kXMP_NS_XMP, "MetadataDate", dt, 0);
  }

  if (override) {
    wrapper->xmpMeta->Erase();
  }

  SXMPUtils::ApplyTemplate(wrapper->xmpMeta, newMeta, templateFlags);

  return Qnil;
}

VALUE
xmpwrapper_set_property(VALUE self, VALUE rb_ns, VALUE rb_prop, VALUE rb_value) {
  XMPWrapper *wrapper;
  TypedData_Get_Struct(self, XMPWrapper, &xmpwrapper_data_type, wrapper);
  check_wrapper_initialized(wrapper);

  Check_Type(rb_ns, T_STRING);
  Check_Type(rb_prop, T_STRING);

  get_xmp(wrapper);

  if (!wrapper->xmpMetaDataLoaded) {
    rb_raise(rb_eRuntimeError, "No XMP metadata loaded");
  }

  VALUE mXmpToolkitRuby = rb_const_get(rb_cObject, rb_intern("XmpToolkitRuby"));
  VALUE cXmpValue = rb_const_get(mXmpToolkitRuby, rb_intern("XmpValue"));

  const char *ns = StringValueCStr(rb_ns);
  const char *prop = StringValueCStr(rb_prop);

  if (rb_obj_is_kind_of(rb_value, cXmpValue)) {
    VALUE rb_inner_val = rb_funcall(rb_value, rb_intern("value"), 0);
    VALUE rb_type_val = rb_funcall(rb_value, rb_intern("type"), 0);

    const char *type_str;
    if (RB_TYPE_P(rb_type_val, T_SYMBOL)) {
      VALUE mode_str = rb_sym_to_s(rb_type_val);
      type_str = StringValueCStr(mode_str);
    } else {
      type_str = StringValueCStr(rb_type_val);
    }

    if (strcmp(type_str, "string") == 0) {
      Check_Type(rb_inner_val, T_STRING);
      wrapper->xmpMeta->SetProperty(ns, prop, StringValueCStr(rb_inner_val), 0);
      return Qtrue;
    } else if (strcmp(type_str, "int") == 0) {
      Check_Type(rb_inner_val, T_FIXNUM);
      wrapper->xmpMeta->SetProperty_Int(ns, prop, NUM2INT(rb_inner_val), 0);
      return Qtrue;
    } else if (strcmp(type_str, "int64") == 0) {
      Check_Type(rb_inner_val, T_FIXNUM);
      wrapper->xmpMeta->SetProperty_Int64(ns, prop, NUM2LL(rb_inner_val), 0);
      return Qtrue;
    } else if (strcmp(type_str, "float") == 0) {
      Check_Type(rb_inner_val, T_FLOAT);
      wrapper->xmpMeta->SetProperty_Float(ns, prop, NUM2DBL(rb_inner_val), 0);
      return Qtrue;
    } else if (strcmp(type_str, "bool") == 0) {
      wrapper->xmpMeta->SetProperty_Bool(ns, prop, RTEST(rb_inner_val), 0);
      return Qtrue;
    } else if (strcmp(type_str, "date") == 0) {
      wrapper->xmpMeta->SetProperty_Date(ns, prop, datetime_to_xmp(rb_inner_val), 0);
      return Qtrue;
    }
  }

  const char *val = StringValueCStr(rb_value);

  try {
    wrapper->xmpMeta->SetProperty(ns, prop, val, 0);
  } catch (...) {
    rb_raise(rb_eRuntimeError, "Failed to set XMP property");
  }

  return Qtrue;
}

// GetFileInfo() retrieves basic information about an opened file. to be defined

VALUE
xmpwrapper_update_localized_text(int argc, VALUE *argv, VALUE self) {
  XMPWrapper *wrapper;
  TypedData_Get_Struct(self, XMPWrapper, &xmpwrapper_data_type, wrapper);
  check_wrapper_initialized(wrapper);

  get_xmp(wrapper);

  if (!wrapper->xmpMetaDataLoaded) {
    rb_raise(rb_eRuntimeError, "No XMP metadata loaded");
  }

  VALUE kwargs;
  rb_scan_args(argc, argv, ":", &kwargs);

  // Define allowed keywords
  ID kw_table[6];

  kw_table[0] = rb_intern("schema_ns");
  kw_table[1] = rb_intern("alt_text_name");
  kw_table[2] = rb_intern("generic_lang");
  kw_table[3] = rb_intern("specific_lang");
  kw_table[4] = rb_intern("item_value");
  kw_table[5] = rb_intern("options");

  VALUE kw_values[6];
  kw_values[2] = rb_str_new_cstr("");  // Default for generic_lang
  kw_values[5] = INT2NUM(0);           // Default for options

  // Extract keywords from kwargs hash
  rb_get_kwargs(kwargs, kw_table, 4, 2, kw_values);

  VALUE schema_ns = kw_values[0];
  VALUE alt_text_name = kw_values[1];
  VALUE generic_lang = kw_values[2];  // Will be default if not provided
  VALUE specific_lang = kw_values[3];
  VALUE item_value = kw_values[4];
  VALUE options = kw_values[5];  // Will be default if not provided

  // Provide defaults if needed
  if (NIL_P(generic_lang)) generic_lang = rb_str_new_cstr("");
  if (NIL_P(options)) options = INT2NUM(0);

  // Convert Ruby values to C strings / types
  const char *c_schema_ns = StringValueCStr(schema_ns);
  const char *c_alt_text_name = StringValueCStr(alt_text_name);
  const char *c_generic_lang = StringValueCStr(generic_lang);
  const char *c_specific_lang = StringValueCStr(specific_lang);
  const char *c_item_value = StringValueCStr(item_value);
  XMP_OptionBits c_options = NUM2UINT(options);

  wrapper->xmpMeta->SetLocalizedText(c_schema_ns, c_alt_text_name, c_generic_lang, c_specific_lang,
                                     std::string(c_item_value), c_options);

  return Qtrue;
}

VALUE
register_namespace(VALUE self, VALUE rb_namespaceURI, VALUE rb_suggestedPrefix) {
  const char *namespaceURI = StringValueCStr(rb_namespaceURI);
  const char *suggestedPrefix = StringValueCStr(rb_suggestedPrefix);
  std::string registeredPrefix;

  ensure_sdk_initialized();

  bool isRegistered = SXMPMeta::GetNamespacePrefix(namespaceURI, &registeredPrefix);

  if (isRegistered) {
    fprintf(stderr, "Namespace '%s' is already registered with prefix '%s'\n", namespaceURI, registeredPrefix.c_str());
    return rb_str_new_cstr(registeredPrefix.c_str());
  }

  bool isSuggestedPrefix = SXMPMeta::RegisterNamespace(namespaceURI, suggestedPrefix, &registeredPrefix);

  if (isSuggestedPrefix) {
    return rb_suggestedPrefix;
  }

  return rb_str_new_cstr(registeredPrefix.c_str());
}

VALUE
write_xmp(VALUE self) {
  XMPWrapper *wrapper;
  TypedData_Get_Struct(self, XMPWrapper, &xmpwrapper_data_type, wrapper);
  check_wrapper_initialized(wrapper);

  if (wrapper->xmpFile && wrapper->xmpMeta) {
    try {
      if (wrapper->xmpFile->CanPutXMP(*(wrapper->xmpMeta))) {
        wrapper->xmpFile->PutXMP(*(wrapper->xmpMeta));
        std::string newBuffer;
        wrapper->xmpMeta->SerializeToBuffer(&newBuffer);
      } else {
        std::string newBuffer;
        wrapper->xmpMeta->SerializeToBuffer(&newBuffer);
        rb_raise(rb_eArgError, "Can't update XMP new Data: '%s'", newBuffer.c_str());
      }
    } catch (const XMP_Error &e) {
      rb_raise(rb_eRuntimeError, "XMP SDK error: %s", e.GetErrMsg());
    }
  }

  return Qtrue;
}

VALUE
xmpwrapper_close_file(VALUE self) {
  XMPWrapper *wrapper;
  TypedData_Get_Struct(self, XMPWrapper, &xmpwrapper_data_type, wrapper);

  if (wrapper->xmpFile) {
    clean_wrapper(wrapper);
  }

  return Qtrue;
}
