#ifndef XMP_TOOLKIT_HPP
#define XMP_TOOLKIT_HPP

#include <cstdio>
#include <vector>
#include <string>
#include <cstring>

//#define ENABLE_XMP_CPP_INTERFACE 1

// Must be defined to instantiate template classes
#define TXMP_STRING_TYPE std::string

// Must be defined to give access to XMPFiles
#define XMP_INCLUDE_XMPFILES 1

// Ensure XMP templates are instantiated
#include "XMP.incl_cpp"

// Provide access to the API
#include "XMP.hpp"

#include <iostream>
#include <fstream>

#include <ruby.h>

using namespace std;

//#define ENABLE_XMP_CPP_INTERFACE 1;

// Must be defined to instantiate template classes
#define TXMP_STRING_TYPE std::string
// Must be defined to give access to XMPFiles
#define XMP_INCLUDE_XMPFILES 1

#include "XMP.incl_cpp"
#include "XMP.hpp"

// TXMPMeta‐style error callback
bool xmp_meta_error_callback(
    void *             clientContext,
    XMP_ErrorSeverity  severity,
    XMP_Int32          cause,
    XMP_StringPtr      message
);

// TXMPFiles‐style error callback
bool xmp_file_error_callback(
    void *             clientContext,
    XMP_StringPtr      filePath,
    XMP_ErrorSeverity  severity,
    XMP_Int32          cause,
    XMP_StringPtr      message
);

// Initialize SXMPMeta + SXMPFiles, installing callbacks.
// If PLUGINS_PATH is defined, it will be used to initialize the XMP Toolkit.
VALUE xmp_initialize(int argc, VALUE* argv, VALUE self);

// Terminate SXMPFiles + SXMPMeta.
VALUE xmp_terminate(VALUE self);

// process_file(filename) → Ruby Hash or nil
VALUE get_xmp_from_file(VALUE self, VALUE rb_filename);

VALUE write_xmp_to_file(int argc, VALUE* argv, VALUE self);

#endif
