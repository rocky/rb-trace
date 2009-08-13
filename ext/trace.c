#include "vm_core_mini.h"  /* Pulls in ruby.h */

extern VALUE rb_cRubyVM;   /* RubyVM class */
extern rb_vm_t *ruby_current_vm;

VALUE rb_cTraceHook;       /* TraceHook class */

/* FIXME: will expand to get and return an all event hooks. For now
 * though, return just the first one. */
VALUE
trace_s_trace_hook()
{
    rb_vm_t *vm = GET_VM();
    rb_event_hook_t *hook = vm->event_hooks;

    if (!hook) return Qnil;
    return Data_Wrap_Struct(rb_cTraceHook, NULL, NULL, hook);
}

/*
  Return the event mask value for a given hook. If no hook, then return nil.
 */
static VALUE
trace_hook_event_mask(VALUE klass)
{
    rb_event_hook_t *hook;
    Data_Get_Struct(klass, rb_event_hook_t, hook);
    if (!hook) return Qnil;
    return INT2FIX(hook->flag);
}

/* Set a new mask value for given hook and return the old mask
   value. Can raise an error if there is no hook installed.  */
static VALUE
trace_hook_event_mask_set(VALUE klass, VALUE maskval)
{
    rb_event_hook_t *hook;
    rb_event_flag_t flag;
    Data_Get_Struct(klass, rb_event_hook_t, hook);
    if (!hook) 
	rb_raise(rb_eRuntimeError, "No hook installed");
    else if (!FIXNUM_P(maskval)) {
	rb_raise(rb_eTypeError, "integer argument expected");
    } 
    flag = hook->flag;
    hook->flag = FIX2INT(maskval);
    return INT2FIX(flag);
}


void
Init_trace(void)
{
    rb_cTraceHook = rb_define_class_under(rb_cRubyVM, "Trace", 
					  rb_cObject);
    rb_define_singleton_method(rb_cTraceHook, "trace_hook", 
			       trace_s_trace_hook, 0);

    rb_define_method(rb_cTraceHook, "event_mask", 
		     trace_hook_event_mask, 0);
    rb_define_method(rb_cTraceHook, "event_mask=", 
		     trace_hook_event_mask_set, 1);
}
