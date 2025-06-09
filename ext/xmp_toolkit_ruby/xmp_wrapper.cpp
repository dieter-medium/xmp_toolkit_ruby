#include "xmp_toolkit.hpp"
#include "xmp_wrapper.hpp"

#include <mutex>


static size_t xmpwrapper_memsize(const void* ptr) {
    return sizeof(XMPWrapper);
}

static void xmpwrapper_free(void* ptr) {
    XMPWrapper* wrapper = static_cast<XMPWrapper*>(ptr);
    if (wrapper) {
        std::lock_guard<std::mutex> lock(wrapper->mutex);
        if (wrapper->xmpFile) {
            wrapper->xmpFile->CloseFile();
            delete wrapper->xmpFile;
            wrapper->xmpFile = nullptr;
        }
        if (wrapper->xmpMeta) {
            delete wrapper->xmpMeta;
            wrapper->xmpMeta = nullptr;
        }

        delete wrapper;
    }
}

static const rb_data_type_t xmpwrapper_data_type = {
    "XMPWrapper",
    {
        0,
        xmpwrapper_free,
        xmpwrapper_memsize,
    },
    0, 0,
    RUBY_TYPED_FREE_IMMEDIATELY
};

VALUE xmpwrapper_allocate(VALUE klass) {
    XMPWrapper* wrapper = new XMPWrapper();
    wrapper->xmpMeta = nullptr;
    wrapper->xmpFile = nullptr;
    wrapper->xmpMetaDataLoaded = false;
    return TypedData_Wrap_Struct(klass, &xmpwrapper_data_type, wrapper);
}

static void get_xmp(XMPWrapper* wrapper){
   if (wrapper->xmpMetaDataLoaded) {
        fprintf(stderr, "XMP metadata already loaded, skipping GetXMP call.\n");
        return;
    }

    bool ok = wrapper->xmpFile->GetXMP(wrapper->xmpMeta);

    if (!ok) {
        wrapper->xmpFile->CloseFile();
        delete wrapper->xmpMeta;
        delete wrapper->xmpFile;
        wrapper->xmpMeta = nullptr;
        wrapper->xmpFile = nullptr;
        rb_raise(rb_eRuntimeError, "Failed to get XMP metadata");
    }

    wrapper->xmpMetaDataLoaded = true;
}

VALUE xmpwrapper_open_file(int argc, VALUE* argv, VALUE self) {
    ensure_sdk_initialized();

    XMPWrapper* wrapper;
    TypedData_Get_Struct(self, XMPWrapper, &xmpwrapper_data_type, wrapper);

    if (wrapper->xmpFile != nullptr) {
        rb_raise(rb_eRuntimeError, "File already opened");
    }

    VALUE rb_filename = Qnil;
    VALUE rb_opts_mask = Qnil;
    rb_scan_args(argc, argv, "11", &rb_filename, &rb_opts_mask);

    const char* filename = StringValueCStr(rb_filename);

    // Allocate native objects
    wrapper->xmpMeta = new SXMPMeta();
    wrapper->xmpFile = new SXMPFiles();

    XMP_OptionBits opts;

    if(!NIL_P(rb_opts_mask)) {
        Check_Type(rb_opts_mask, T_FIXNUM);
        opts = NUM2UINT(rb_opts_mask);
    } else {
        opts = kXMPFiles_OpenForRead | kXMPFiles_OpenUseSmartHandler;
    }

    bool ok = wrapper->xmpFile->OpenFile(filename, kXMP_UnknownFile, opts);
    if (!ok) {
        delete wrapper->xmpMeta;
        delete wrapper->xmpFile;
        wrapper->xmpMeta = nullptr;
        wrapper->xmpFile = nullptr;
        rb_raise(rb_eIOError, "Failed to open file %s", filename);
    }

    return Qtrue;
}

VALUE xmpwrapper_set_property(VALUE self, VALUE rb_ns, VALUE rb_prop, VALUE rb_value) {
    XMPWrapper* wrapper;
    TypedData_Get_Struct(self, XMPWrapper, &xmpwrapper_data_type, wrapper);

    get_xmp(wrapper);

    if (!wrapper->xmpMetaDataLoaded) {
        rb_raise(rb_eRuntimeError, "No XMP metadata loaded");
    }

    const char* ns = StringValueCStr(rb_ns);
    const char* prop = StringValueCStr(rb_prop);
    const char* val = StringValueCStr(rb_value);

    try {
        const char* kPDFUA_NS = "http://www.aiim.org/pdfua/ns/id/";
        wrapper->xmpMeta->SetProperty(ns, prop, val, 0);
    } catch (...) {
        rb_raise(rb_eRuntimeError, "Failed to set XMP property");
    }

    return Qtrue;
}

// GetFileInfo() retrieves basic information about an opened file. to be defined

VALUE xmpwrapper_update_localized_text(int argc, VALUE *argv, VALUE self) {
    XMPWrapper* wrapper;
    TypedData_Get_Struct(self, XMPWrapper, &xmpwrapper_data_type, wrapper);

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
    kw_values[4] = rb_str_new_cstr(""); // Default for generic_lang
    kw_values[5] = INT2NUM(0);          // Default for options

    // Extract keywords from kwargs hash
    rb_get_kwargs(kwargs, kw_table, 4, 2, kw_values);

    VALUE schema_ns     = kw_values[0];
    VALUE alt_text_name = kw_values[1];
    VALUE generic_lang  = kw_values[2]; // Will be default if not provided
    VALUE specific_lang = kw_values[3];
    VALUE item_value    = kw_values[4];
    VALUE options       = kw_values[5]; // Will be default if not provided

    // Provide defaults if needed
    if (NIL_P(generic_lang)) generic_lang = rb_str_new_cstr("");
    if (NIL_P(options)) options = INT2NUM(0);


    // Convert Ruby values to C strings / types
    const char* c_schema_ns     = StringValueCStr(schema_ns);
    const char* c_alt_text_name = StringValueCStr(alt_text_name);
    const char* c_generic_lang  = StringValueCStr(generic_lang);
    const char* c_specific_lang = StringValueCStr(specific_lang);
    const char* c_item_value    = StringValueCStr(item_value);
    XMP_OptionBits c_options    = NUM2UINT(options);

    fprintf(stderr, "Updating localized text with schema_ns='%s', alt_text_name='%s', generic_lang='%s', specific_lang='%s', item_value='%s', options=%u\n",
        c_schema_ns, c_alt_text_name, c_generic_lang, c_specific_lang, c_item_value, c_options
    );


    wrapper->xmpMeta->SetLocalizedText(
        c_schema_ns,
        c_alt_text_name,
        c_generic_lang,
        c_specific_lang,
        std::string(c_item_value),
        c_options
    );



    return Qtrue;
}

VALUE register_namespace(VALUE self, VALUE rb_namespaceURI, VALUE rb_suggestedPrefix) {
    const char* namespaceURI = StringValueCStr(rb_namespaceURI);
    const char* suggestedPrefix = StringValueCStr(rb_suggestedPrefix);
    std::string registeredPrefix;

    ensure_sdk_initialized();

    bool isRegistered = SXMPMeta::GetNamespacePrefix(namespaceURI, &registeredPrefix);

    if (isRegistered) {
        fprintf(stderr, "Namespace '%s' is already registered with prefix '%s'\n", namespaceURI, registeredPrefix.c_str());
        return rb_str_new_cstr(registeredPrefix.c_str());
    }

    bool isSuggestedPrefix = SXMPMeta::RegisterNamespace(namespaceURI, suggestedPrefix, &registeredPrefix);

    if (isSuggestedPrefix){
       return rb_suggestedPrefix;
    }

    return rb_str_new_cstr(registeredPrefix.c_str());
}

VALUE write_xmp(VALUE self){
    XMPWrapper* wrapper;
    TypedData_Get_Struct(self, XMPWrapper, &xmpwrapper_data_type, wrapper);

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
       } catch (const XMP_Error& e) {
           rb_raise(rb_eRuntimeError, "XMP SDK error: %s", e.GetErrMsg());
       }
    }

    return Qtrue;
}

VALUE xmpwrapper_close_file(VALUE self) {
    XMPWrapper* wrapper;
    TypedData_Get_Struct(self, XMPWrapper, &xmpwrapper_data_type, wrapper);

    if (wrapper->xmpFile) {
        wrapper->xmpFile->CloseFile();
        if (wrapper->xmpMeta){
            delete wrapper->xmpMeta;
        }

        delete wrapper->xmpFile;

        wrapper->xmpMeta = nullptr;
        wrapper->xmpFile = nullptr;
    }

    return Qtrue;
}


