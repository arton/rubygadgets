/*
 * rawstring - c string importer
 * copyright(c) 2006 arton
 *
 * Usage of the works is permitted provided that this instrument is retained
 * with the works, so that any entity that uses the works is notified of this
 * instrument.
 *
 * DISCLAIMER: THE WORKS ARE WITHOUT WARRANTY.
 *
 * $Id:$
 * $Log:$
 */
#define RAWSTRING_VERSION "0.1.1"

#include "ruby.h"

#if SIZEOF_VOIDP == 4
#define VAL2PTR(v) ((void*)NUM2ULONG(v))
#elif SIZEOF_VOIDP == 8
#define VAL2PTR(v) ((void*)NUM2LL(v))
#else
#error pointer size not supported
#endif    

/*
 * Document-class: RawString
 *
 * == Summary
 *
 * Ruby extension for loading a raw C string to Ruby's String instance
 *
 * == Abstract
 *
 * RawString is a module that convert raw C string pointer to the String object.
 *
 */

static VALUE rawstring;

static void* get_ptr(int argc, VALUE* argv, int* length)
{
    void* ret;
    VALUE ptr, vlen;
    if (rb_scan_args(argc, argv, "11", &ptr, &vlen) == 1)
    {
        *length = -1; // negative value means null termination.
    }
    else
    {
        *length = NUM2INT(vlen);
    }
    if (NIL_P(ptr)) return NULL;
    return VAL2PTR(ptr);
}

/*
 * Document-method: load
 * call-seq: RawString::load
 *
 * Returns the String from number.
 */
static VALUE rs_s_load(int argc, VALUE* argv, VALUE self)
{
    int length;
    void* p = get_ptr(argc, argv, &length);
    if (!p) return Qnil;
    if (length < 0)
        return rb_str_new2(p);
    return rb_str_new(p, length);
}

/*
 * Document-method: wload
 * call-seq: RawString::wload
 *
 * Returns the wchar_t String from number.
 */
static VALUE rs_s_wload(int argc, VALUE* argv, VALUE self)
{
    int length;
    void* p = get_ptr(argc, argv, &length);
    if (!p) return Qnil;
    if (length < 0)
    {
        unsigned short * pu;
        length = 0;
        for (pu = (unsigned short *)p; *pu; pu++)
        {
            length++;
        }
    }
    return rb_str_new(p, length * 2);
}

struct TestStruct {
    char* pName;
    wchar_t* pWName;
};
static struct TestStruct testData = {
    "char*",
    L"wchar_t*",
};
/**
 * Test function:
 * Returns PCSTR and PWSTR
 */
static VALUE rs_s_ptest(VALUE self)
{
    return rb_str_new((char*)&testData, sizeof(struct TestStruct));
}

/**
 * Class Initializer called by Ruby while requiring this library
 */
void Init_RawString()
{
    rb_require("rbconfig");

    rawstring = rb_define_module("RawString");
    rb_define_module_function(rawstring, "load", rs_s_load, -1);
    rb_define_module_function(rawstring, "wload", rs_s_wload, -1);
    rb_define_module_function(rawstring, "pointer_test", rs_s_ptest, 0);
    rb_define_const(rawstring, "VERSION", rb_str_new2(RAWSTRING_VERSION));
}
