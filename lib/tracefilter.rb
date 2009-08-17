require 'set'
# require '/src/external-vcs/rb-threadframe/ext/thread_frame'
require 'thread_frame'
require_relative 'trace_mod'

# A class that can be used to test whether certain functions should be
# excluded.  We also convert the hook call to pass a threadframe and
# an event rather than event and those other 5 parameters.
class TraceFilter

  attr_reader :excluded

  def initialize(excluded_fns = [])
    valid_fns = excluded_fns.select{|fn| valid_fn?(fn)}
    @excluded = Set.new(valid_fns)
  end

  # fn should be a ThreadFrame or a Proc which has an instruction sequence
  def valid_fn?(fn)
    if (fn.is_a?(RubyVM::ThreadFrame) || fn.is_a?(Proc))
      fn.respond_to?(:iseq)
    else fn.is_a?(RubyVM::InstructionSequence)
      true
    end
  end

  def <<(fn)
    if valid_fn?(fn)
      @excluded << fn
      return true
    else
      return false
    end
  end

  # Null out list of excluded fns
  def clear
    @excluded = Set.new
  end

  # Return true if `fn' is in the list of functions to exclude
  def excluded?(fn)
    return nil unless valid_fn?(fn)
    # FIXME: also check for excluded proc
    retval = @excluded.any? do |check_fn| 
      check_fn.equal?(fn)
    end
    # p "bool: #{retval}"
    return retval
  end

  # Add the caller's instruction sequence to the list of ignored
  # routines.
  def ignore_me
    @excluded << RubyVM::ThreadFrame::current.prev.iseq
  end

  # Remove `fn' from the list of functions to include
  def remove(fn)
    return nil unless valid_fn?(fn)
    @excluded -= [fn]
  end

  # Filter based on @excluded and convert to newer style trace hook
  # call based on RubyVM::ThreadFrame.
  def trace_hook(event, file, line, id, binding, klass)
    tf = RubyVM::ThreadFrame::current.prev
    tf_check = tf
    while !tf_check.iseq do 
      tf_check = tf_check.prev 
    end
    return if tf_check.nil? || excluded?(tf_check.iseq)
    @proc.call(event, tf)
  end

  # Replacement for Kernel.set_trace_func. proc should be a Proc that
  # takes two arguments, a string event, and threadframe object.
  def set_trace_func(proc, event_mask=nil)
    if proc.nil?
      Kernel.set_trace_func(nil)
      return
    end
    raise TypeError, 
    "trace_func needs to be Proc or nil (is #{proc.class})" unless 
      proc.is_a?(Proc)
    raise TypeError, "arity of proc should be 2 (is #{proc.arity}" unless 
      2 == proc.arity
    @proc = proc
    if event_mask
      Trace::set_trace_func(method(:trace_hook).to_proc, event_mask)
    else
      Kernel.set_trace_func(method(:trace_hook).to_proc)
    end
  end

end

if __FILE__ == $0

  def foo
    puts "foo here\n"
  end

  def my_hook(event, tf)
    p "#{event} #{tf.method} #{tf.source_location[0]}"
  end

  def trace_test(filter, dont_trace_me)
    filter.ignore_me if dont_trace_me
    filter.set_trace_func(method(:my_hook).to_proc)
    foo
    x = 1
    foo
  end

  markers = '*' * 10
  trace_filter = TraceFilter.new
  p "%s with ignore %s" % [markers, markers]
  trace_filter.set_trace_func(nil)
  trace_test(trace_filter, true)
  trace_filter.set_trace_func(nil)
  trace_filter.clear
  p "%s without ignore (compare with above) %s" % [markers, markers]
  trace_test(trace_filter, false)
  trace_filter.set_trace_func(nil)
end
