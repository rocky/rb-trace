require 'set'
# require '/src/external-vcs/rb-threadframe/ext/thread_frame'
require 'thread_frame'
require_relative 'trace_mod'

# A class that can be used to test whether certain methods should be
# excluded.  We also convert the hook call to pass a threadframe and
# an event rather than event and those other 5 parameters.
class TraceFilter

  attr_reader :excluded

  def initialize(excluded_meths = [])
    excluded_meths = excluded_meths.select{|fn| valid_meth?(fn)}
    @excluded = Set.new(excluded_meths)
  end

  # fn should be a ThreadFrame or a Proc which has an instruction sequence
  def valid_meth?(fn)
    fn.is_a?(Method)
  end

  def <<(meth)
    if valid_meth?(meth)
      @excluded << meth
      return true
    else
      return false
    end
  end

  # Null out list of excluded methods
  def clear
    @excluded = Set.new
  end

  # Remove `meth' from the list of functions to include
  def remove(meth)
    return nil unless valid_meth?(meth)
    @excluded -= [meth]
  end

  # Filter based on @excluded and convert to newer style trace hook
  # call based on RubyVM::ThreadFrame.
  def trace_hook(event, file, line, id, binding, klass)
    tf = RubyVM::ThreadFrame::current.prev

    # FIXME: Clean this mess up. And while your at it, understand
    # what's going on better.
    tf_check = tf
    while tf_check.method == "IFUNC" do 
      tf_check = tf_check.prev 
    end
    return unless tf_check
    begin 
      meth = eval("self.method(:#{tf_check.method})", tf_check.binding)
    rescue
    rescue SyntaxError
      return
    end
    return if @excluded.member?(meth)
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
    raise TypeError, "arity of proc should be 2 or -3 (is #{proc.arity})" unless 
      2 == proc.arity || -3 == proc.arity
    @proc = proc
    if event_mask
      Trace::set_trace_func(method(:trace_hook).to_proc, event_mask)
    else
      Kernel.set_trace_func(method(:trace_hook).to_proc)
    end
  end

end

if __FILE__ == $0

  def square(x)
    y = x * x
    puts "the square of #{x} is #{y}\n"
    y
  end

  def my_hook(event, tf)
    @events << event
    @line_nos << tf.source_location[0]
  end

  def trace_test(dont_trace_me)
    @start_line = __LINE__
    @trace_filter.excluded << self.method(:trace_test) if dont_trace_me

    # Start tracing.
    @trace_filter.set_trace_func(method(:my_hook).to_proc)
    square(10)
    x = 100
    square(x)
    @end_line = __LINE__
  end

  def setup
    @events   = []
    @line_nos = []
    @trace_filter.clear
  end

  def print_trace
    @line_nos.each_with_index do |line_no, i|
      print "%2d %s %s\n" % [i, @events[i], line_no]
    end
  end

  @trace_filter = TraceFilter.new
  markers       = '*' * 10

  [[false, 'out'], [true, '']].each do |arg, suffix|
    setup 
    puts "%s with%s ignore %s" % [markers, suffix, markers]
    trace_test(arg)
    @trace_filter.set_trace_func(nil)
    print_trace
  end

  @line_nos.each_with_index do 
    |line_no, i|
    if (@start_line..@end_line).member?(line_no)
      puts "We should not have found a line number in #{@start_line}..#{@end_line}." 
      puts "Got line number #{line_no} at index #{i}, event #{@events[i]}"
    end
  end
end
