require 'set'
require 'thread_frame'
require_relative 'trace'

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
    (fn.is_a?(RubyVM::ThreadFrame) || fn.is_a?(Proc)) && fn.iseq
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
    @excluded.any? {|check_fn| check_fn.equal?(fn)}
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
    # FIXME: also check for excluded proc
    return if excluded?(tf)
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
  trace_filter = TraceFilter.new
  trace_filter.set_trace_func(Proc.new {|e, tf| p e})
  p '=' * 40
  trace_filter.set_trace_func(nil)
end
