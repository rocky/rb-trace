#  Copyright (C) 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'set'
# require '/src/external-vcs/rb-threadframe/ext/thread_frame'
require 'thread_frame'
require_relative 'trace_mod'

module Trace

  # A class that can be used to test whether certain methods should be
  # excluded.  We also convert the hook call to pass a threadframe and
  # an event rather than event and those other 5 parameters.
  class Filter

    attr_reader :excluded
    attr_reader :hook_proc

    def initialize(excluded_meths = [])
      excluded_meths = excluded_meths.select{|fn| valid_meth?(fn)}
      excluded_meths << self.method(:set_trace_func).to_s
      @excluded = Set.new(excluded_meths.map{|m| m.to_s})
    end

    # +fn+ should be a RubyVM::Frame object or a Proc which has an
    # instruction sequence
    def valid_meth?(fn)
      fn.is_a?(Method)
    end

    # Add +meth+ to list of trace filters.
    def <<(meth)
      if valid_meth?(meth)
        @excluded << meth.to_s
        return true
      else
        return false
      end
    end

    # Null out list of excluded methods
    def clear
      @excluded = Set.new
    end

    # Returns +true+ if +meth+ is a member of the trace filter set.
    def member?(meth)
      if valid_meth?(meth)
        @excluded.member?(meth.to_s)
      else
        false
      end
    end

    # Remove +meth+ from the list of functions to include.
    def remove(meth)
      return nil unless valid_meth?(meth)
      @excluded -= [meth.to_s]
    end

    # A shim to convert between older-style trace hook call to newer
    # style trace hook using RubyVM::Frame. Methods stored in 
    # @+excluded+ are ignored.
    def trace_hook(event, file, line, id, binding, klass)
      tf = RubyVM::Frame::current.prev

      # FIXME: Clean this mess up. And while your at it, understand
      # what's going on better.
      tf_check = tf

      while %w(IFUNC CFUNC).member?(tf_check.type) do 
        tf_check = tf_check.prev 
      end
      return unless tf_check

      begin 
        if tf_check.method && !tf_check.method.empty?
          meth_name = tf_check.method.gsub(/^.* in /, '')
          meth = eval("self.method(:#{meth_name})", tf_check.binding)
          if @excluded.member?(meth.to_s)
            # Turn off tracing for any calls from this frame.  Note
            # that Ruby turns of tracing in the thread of a hook while
            # it is running, but I don't think this is as good as
            # turning it off in the frame and frames called from that.
            # Example: if a trace hook yields to or calls a block
            # outside not derived from the frame, then tracing should
            # start again.  But either way, since RubyVM::Frame
            # allows control over tracing *any* decision is not
            # irrevocable, just possibly unhelpful.
            tf_check.trace_off = true
            return 
          end
        end
      rescue NameError
      rescue SyntaxError
      rescue ArgumentError
      end
      while %w(IFUNC).member?(tf.type) do 
        tf = tf.prev 
      end

      # There is what looks like a a bug in Ruby where self.class for C
      # functions are not set correctly. Until this is fixed in what I
      # consider a more proper way, we'll hack around this by passing
      # the binding as the optional arg parameter.
      arg = 
        if 'CFUNC' == tf.type && NilClass != klass 
          klass 
        elsif 'raise' == event
          # As a horrible hack to be able to get the raise message on a
          # 'raise' event before the event occurs, I changed RubyVM to store
          # the message in the class field.
          klass
        else
          nil
        end

      retval = @hook_proc.call(event, tf, arg)
      if retval.respond_to?(:ancestors) && retval.ancestors.include?(Exception)
        raise retval 
      end
    end

    # Replacement for Kernel.add_trace_func. hook_proc should be a Proc that
    # takes two arguments, a string event, and threadframe object.
    def add_trace_func(hook_proc, event_mask=nil)
      if hook_proc.nil?
        Kernel.set_trace_func(nil)
        return
      end
      raise TypeError, 
      "trace_func needs to be Proc or nil (is #{hook_proc.class})" unless 
        hook_proc.is_a?(Proc)
      raise TypeError, "arity of hook_proc should be 2 or -3 (is #{hook_proc.arity})" unless 
        2 == hook_proc.arity || -3 == hook_proc.arity
      @hook_proc = hook_proc
      if event_mask
        Trace::add_trace_func(method(:trace_hook).to_proc, event_mask)
      else
        Kernel.add_trace_func(method(:trace_hook).to_proc)
      end
    end

    # FIXME: remove just this trace function
    def remove_trace_func
        Kernel.clear_trace_func
    end


    # Replacement for Kernel.set_trace_func. proc should be a Proc that
    # takes two arguments, a string event, and threadframe object.
    def set_trace_func(hook_proc, event_mask=nil)
      if hook_proc.nil?
        Kernel.set_trace_func(nil)
        return
      end
      raise TypeError, 
      "trace_func needs to be Proc or nil (is #{hook_proc.class})" unless 
        hook_proc.is_a?(Proc)
      raise TypeError, "arity of hook_proc should be 2 or -3 (is #{hook_proc.arity})" unless 
        2 == hook_proc.arity || -3 == hook_proc.arity
      @hook_proc = hook_proc
      if event_mask
        Trace::set_trace_func(method(:trace_hook).to_proc, event_mask)
      else
        Kernel.set_trace_func(method(:trace_hook).to_proc)
      end
    end
  end
end

if __FILE__ == $0
  include Trace

  def square(x) # :nodoc:
    y = x * x
    puts "the square of #{x} is #{y}\n"
    y
  end

  def my_hook(event, tf, arg=nil) # :nodoc:
    puts "#{event} #{tf.source_container[1]} #{tf.source_location[0]}"
    @events << event
    @line_nos << ((tf.source_location) ? tf.source_location[0] : '?')
  end

  def trace_test(dont_trace_me) # :nodoc:
    @start_line = __LINE__
    @trace_filter << self.method(:trace_test) if dont_trace_me
    p @trace_filter.member?(self.method(:trace_test))

    # Start tracing.
    event_mask = DEFAULT_EVENT_MASK # & ~(C_RETURN_EVENT_MASK | RETURN_EVENT_MASK)
    @trace_filter.set_trace_func(method(:my_hook).to_proc, event_mask)
    square(10)
    x = 100
    square(x)
    @end_line = __LINE__
  end

  def setup # :nodoc:
    @events   = []
    @line_nos = []
    @trace_filter.clear
  end

  def print_trace # :nodoc:
    @line_nos.each_with_index do |line_no, i|
      print "%2d %s %s\n" % [i, @events[i], line_no]
    end
  end

  @trace_filter = Trace::Filter.new
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
