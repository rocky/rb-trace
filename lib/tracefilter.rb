require 'set'
require 'thread_frame'

# A class that can be used to test whether certain functions should be
# excluded.  We also convert the hook call to pass a threadframe and
# an event rather than event and those other 5 parameters.
class TraceFilter

  attr_reader :excluded

  def initialize(excluded_fns = [])
    valid_fns = excluded_fns.select{|fn| valid_fn?(fn)}
    @excluded = Set.new(valid_fns)
  end

  def valid_fn?(tf)
    tf.is_a?(RubyVM::ThreadFrame) && tf.iseq
  end

  def <<(tf)
    if valid_fn?(tf)
      @excluded << tf.iseq
      return true
    else
      return false
    end
  end

  # Null out list of excluded fns
  def clear
    @excluded = Set.new
  end

  # Return true if `tf' is in the list of functions to exclude
  def excluded?(tf)
    return nil unless valid_fn(tf)
    @excluded.member?(tf)
  end
        
  # Remove `tf' from the list of functions to include
  def remove(tf)
    return nil unless valid_fn(tf)
    @excluded -= [tf]
  end

  # Filter based on @excluded and convert to newer style trace hook
  # call based on RubyVM::ThreadFrame.
  def trace_hook(event, file, line, id, binding, klass)
    # FIXME: do method filtering here
    tf = RubyVM::ThreadFrame::current.prev
    @proc.call(event, tf)
  end

  # Replacement for Kernel.set_trace_func. proc should be a Proc that
  # takes two arguments, a string event, and threadframe object.
  def set_trace_func(proc, event_mask=nil)
    raise TypeError, "trace_func needs to be Proc" unless proc.is_a?(Proc)
    raise TypeError, "arity of proc should be 2" unless 2 == proc.arity
    @proc = proc
    if event_mask
      Kernel.set_trace_func(method(:trace_hook).to_proc, event_mask)
    else
      Kernel.set_trace_func(method(:trace_hook).to_proc)
    end
  end

end

if __FILE__ == $0
end
