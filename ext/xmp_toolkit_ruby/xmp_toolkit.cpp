#include "xmp_toolkit.hpp"

#include <mutex>

static std::mutex sdk_init_mutex;
static bool sdk_initialized = false;
static bool terminate_registered = false;

static void terminate_sdk_internal() {
  std::lock_guard<std::mutex> guard(sdk_init_mutex);
  if (sdk_initialized) {
    SXMPFiles::Terminate();
    SXMPMeta::Terminate();
    sdk_initialized = false;
  }
}

// Register termination at Ruby exit
static void register_terminate_at_exit() {
  if (terminate_registered) {
    return;  // Already registered
  }

  terminate_registered = true;

  rb_set_end_proc([](VALUE) { terminate_sdk_internal(); }, Qnil);
}

static void ensure_sdk_initialized(const char *path) {
  std::lock_guard<std::mutex> guard(sdk_init_mutex);

  if (sdk_initialized) {
    return;
  }

  try {
    if (!SXMPMeta::Initialize()) {
      rb_raise(rb_eRuntimeError, "Failed to initialize XMP Toolkit metadata");
      return;
    }

    sdk_initialized = true;
    register_terminate_at_exit();

    XMP_OptionBits options = 0;
    options |= kXMPFiles_ServerMode;

    if (path) {
      if (!SXMPFiles::Initialize(options, path)) {
        rb_raise(rb_eRuntimeError, "Failed to initialize XMP Files with plugin path");
        return;
      }
    } else {
      if (!SXMPFiles::Initialize(options)) {
        rb_raise(rb_eRuntimeError, "Failed to initialize XMP Files without plugin path");
        return;
      }
    }

    return;
  } catch (const XMP_Error &e) {
    rb_raise(rb_eRuntimeError, "XMP Error during initialization: %s", e.GetErrMsg());
    return;
  } catch (const std::exception &e) {
    rb_raise(rb_eRuntimeError, "C++ exception during initialization: %s", e.what());
    return;
  } catch (...) {
    rb_raise(rb_eRuntimeError, "Unknown error during XMP initialization");
    return;
  }
}

VALUE
is_sdk_initialized(VALUE self) {
  std::lock_guard<std::mutex> guard(sdk_init_mutex);
  return sdk_initialized ? Qtrue : Qfalse;
}

void ensure_sdk_initialized() {
  // Look up XmpToolkitRuby::PLUGINS_PATH if defined
  VALUE xmp_module = rb_const_get(rb_cObject, rb_intern("XmpToolkitRuby"));
  if (rb_const_defined(xmp_module, rb_intern("PLUGINS_PATH"))) {
    VALUE plugins_path = rb_const_get(xmp_module, rb_intern("PLUGINS_PATH"));

    if (TYPE(plugins_path) == T_STRING) {
      const char *path = StringValueCStr(plugins_path);
      ensure_sdk_initialized(path);
      return;
    }
  }

  ensure_sdk_initialized(nullptr);

  return;
}

bool xmp_meta_error_callback(void *clientContext, XMP_ErrorSeverity severity, XMP_Int32 cause, XMP_StringPtr message) {
  const char *sevStr = (severity == kXMPErrSev_Recoverable)      ? "RECOVERABLE"
                       : (severity == kXMPErrSev_OperationFatal) ? "FATAL OPERATION"
                       : (severity == kXMPErrSev_FileFatal)      ? "FATAL FILE"
                       : (severity == kXMPErrSev_ProcessFatal)   ? "FATAL PROCESS"
                                                                 : "UNKNOWN";
  std::cerr << "[TXMPMeta " << sevStr << "] "
            << "Code=0x" << std::hex << cause << std::dec << "  Msg=\"" << (message ? message : "(no detail)")
            << "\"\n";

  // If it's a recoverable error, return true so XMP can try to continue;
  // otherwise return false to force an exception back to the caller.
  return (severity == kXMPErrSev_Recoverable);
}

bool xmp_file_error_callback(void *clientContext, XMP_StringPtr filePath, XMP_ErrorSeverity severity, XMP_Int32 cause,
                             XMP_StringPtr message) {
  const char *sevStr = (severity == kXMPErrSev_Recoverable)      ? "RECOVERABLE"
                       : (severity == kXMPErrSev_OperationFatal) ? "FATAL OPERATION"
                       : (severity == kXMPErrSev_FileFatal)      ? "FATAL FILE"
                       : (severity == kXMPErrSev_ProcessFatal)   ? "FATAL PROCESS"
                                                                 : "UNKNOWN";

  std::cerr << "[TXMPFiles " << sevStr << "] "
            << "file=\"" << (filePath ? filePath : "(null)") << "\"  "
            << "cause=0x" << std::hex << cause << std::dec << "\n"
            << "    msg=\"" << (message ? message : "(no detail)") << "\"\n";

  // Only attempt recovery if the error is marked recoverable
  return (severity == kXMPErrSev_Recoverable);
}

// xmp_initialize(self)
// Initialize the XMP Toolkit and SXMPFiles with an optional PLUGINS_PATH
VALUE
xmp_initialize(int argc, VALUE *argv, VALUE self) {
  VALUE rb_path_arg = Qnil;

  rb_scan_args(argc, argv, "01", &rb_path_arg);

  if (rb_path_arg != Qnil) {
    Check_Type(rb_path_arg, T_STRING);
    const char *path = StringValueCStr(rb_path_arg);

    ensure_sdk_initialized(path);

    return Qnil;
  }

  ensure_sdk_initialized();
  return Qnil;
}

VALUE
xmp_terminate(VALUE self) {
  terminate_sdk_internal();
  return Qnil;
}