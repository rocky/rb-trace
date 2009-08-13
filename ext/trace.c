#include "vm_core_mini.h"  /* Pulls in ruby.h */

/* What release we got? */
#define TRACE_VERSION "0.1"  

extern VALUE rb_cRubyVM;   /* RubyVM class */
extern rb_vm_t *ruby_current_vm;

VALUE rb_cTraceHook;       /* TraceHook class */
VALUE rb_eTraceHookError;  /* Exception raised by TraceHook class */

/* Extra information we need to save about a hook. 
   FIXME: For now we will work only with vm hooks. When this
   extends to thread hooks, we will need to use this.
 */
typedef struct 
{
  rb_thread_t *th;         /* If NULL, hook is in vm. Otherwise, this
			      is the thread the hook belongs to. */
  rb_event_hook_t *hook;
} hook_info_t;

static int is_hook_member(rb_event_hook_t *check_hook, rb_event_hook_t *hook);

static void
check_hook_valid(rb_event_hook_t *check_hook)
{
  /* FIXME: in the future use check_hook to find the hook head. */
  rb_event_hook_t *hook_head = GET_VM()->event_hooks;
  
  if (!is_hook_member(check_hook, hook_head))
    rb_raise(rb_eTraceHookError, "hook not found");
}

/* Return an Array of vm event hooks found from hook. */
VALUE
get_trace_hooks(rb_event_hook_t *hook)
{
    VALUE ary;
    for (ary = rb_ary_new(); hook; hook = hook->next)
	rb_ary_push(ary, Data_Wrap_Struct(rb_cTraceHook, NULL, NULL, hook));
    return ary;
}

/* Return 1 if check_hook is found in the list of hooks pointed to by
 'hook', or 0 if not found. */
static int 
is_hook_member(rb_event_hook_t *check_hook, rb_event_hook_t *hook) 
{
    for (; hook; hook = hook->next) if (check_hook == hook) return 1;
    return 0;  /* Not found */
}

/* Return an Array of VM event hooks objects. */
VALUE
trace_hook_s_trace_hooks()
{
  return get_trace_hooks(GET_VM()->event_hooks);
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
    check_hook_valid(hook);
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
	rb_raise(rb_eTraceHookError, "No hook installed");
    if (!FIXNUM_P(maskval)) {
	rb_raise(rb_eTypeError, "integer argument expected");
    } 
    check_hook_valid(hook);
    flag = hook->flag;
    hook->flag = FIX2INT(maskval);
    return INT2FIX(flag);
}

/*
  Return the event mask value for a given hook. If no hook, then return nil.
 */
static VALUE
trace_hook_proc(VALUE klass)
{
    rb_event_hook_t *hook;
    Data_Get_Struct(klass, rb_event_hook_t, hook);
    if (!hook) return Qnil;
    check_hook_valid(hook);
    return hook->data;
}

/*
  Return true if hook is still valid or is nil), false otherwise.
 */
static VALUE
trace_hook_valid(VALUE klass)
{
    rb_event_hook_t *hook;
    Data_Get_Struct(klass, rb_event_hook_t, hook);
    /* FIXME in the future we will need to extract whether this hook is
       part of a thread or from the vm.
    */
    return is_hook_member(hook, GET_VM()->event_hooks) ? Qtrue : Qfalse;
}

void
Init_trace(void)
{
  rb_eTraceHookError = rb_define_class_under(rb_cRubyVM, "TraceHookError",
					     rb_eStandardError);
  rb_cTraceHook      = rb_define_class_under(rb_cRubyVM, "TraceHook", 
					     rb_cObject);

  rb_define_singleton_method(rb_cTraceHook, "trace_hooks", 
			     trace_hook_s_trace_hooks, 0);
  
  rb_define_method(rb_cTraceHook, "event_mask", 
		   trace_hook_event_mask, 0);
  rb_define_method(rb_cTraceHook, "event_mask=", 
		   trace_hook_event_mask_set, 1);
  rb_define_method(rb_cTraceHook, "proc", 
		   trace_hook_proc, 0);
  rb_define_method(rb_cTraceHook, "valid?", 
		   trace_hook_valid, 0);
}
