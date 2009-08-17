require_relative %w(.. ext trace)

module Trace

  # Event masks from <ruby.h>
  unless defined?(NO_EVENT_MASK)
    NO_EVENT_MASK        = 0x0000
    LINE_EVENT_MASK      = 0x0001
    CLASS_EVENT_MASK     = 0x0002
    END_EVENT_MASK       = 0x0004
    CALL_EVENT_MASK      = 0x0008
    RETURN_EVENT_MASK    = 0x0010
    C_CALL_EVENT_MASK    = 0x0020
    C_RETURN_EVENT_MASK  = 0x0040
    RAISE_EVENT_MASK     = 0x0080
    INSN_EVENT_MASK      = 0x0100
    ALL_EVENT_MASKS      = (0xffff & ~INSN_EVENT_MASK)
    VM_EVENT_MASK        = 0x10000
    SWITCH_EVENT_MASK    = 0x20000
    COVERAGE_EVENT_MASK  = 0x40000
    
    DEFAULT_EVENT_MASK   = 
      CALL_EVENT_MASK     |
      CLASS_EVENT_MASK    |
      C_CALL_EVENT_MASK   |
      C_RETURN_EVENT_MASK |
      END_EVENT_MASK      |
      LINE_EVENT_MASK     |
      RAISE_EVENT_MASK    |
      RETURN_EVENT_MASK 
    
    
    EVENT2MASK = {
      :c_call   => C_CALL_EVENT_MASK,
      :c_return => C_RETURN_EVENT_MASK,
      :call     => CALL_EVENT_MASK,
      :class    => CLASS_EVENT_MASK,
      :end      => END_EVENT_MASK,
      :insn     => INSN_EVENT_MASK,
      :line     => LINE_EVENT_MASK,
      :raise    => RAISE_EVENT_MASK,
      :return   => RETURN_EVENT_MASK,
    }

    EVENTS = EVENT2MASK.keys.sort
  end

  # events should be Enumerable and each element
  # should either be a Fixnum mask value or 
  # something that can be converted to a symbol. If the
  # latter, the case is not important as we'll downcase
  # the string representation.
  def events2bitmask(events)
    bitmask = NO_EVENT_MASK
    bad_events = []
    events.each do |event|
      nextbit = nil
      if event.is_a?(Fixnum)
        # Assume a bit mask
        nextbit = event
      elsif event.respond_to?(:to_sym)
        # Assume an event name
        sym = event.to_sym.to_s.downcase.to_sym
        nextbit = EVENT2MASK[sym] if EVENT2MASK.member?(sym)
      end
      if nextbit
        bitmask |= nextbit
      else
        bad_events << event
      end
    end
    return bitmask, bad_events
  end
  module_function :events2bitmask

  def bitmask2events(mask)
    bitmask = []
    EVENT2MASK.each do |key, value|
      bitmask << key if (value & mask) != 0
    end
    return bitmask
  end

  def convert_event_mask(mask_arg)
    if mask_arg.is_a?(Fixnum)
      event_mask = mask_arg
    elsif mask_arg.kind_of?(Enumerable)
      event_mask, bad_events = events2bitmask(mask_arg)
      raise ArgumentError, "Bad set elements: #{bad_events.inspect}" unless
        bad_events.empty?
    else
      raise ArgumentError, "Bad set mask arg: #{mask_arg}"
    end
    event_mask
  end
  module_function :convert_event_mask

  # Return a list of the global event masks in effect
  def event_masks
    RubyVM::TraceHook::trace_hooks.map do |hook|
      hook.event_mask
    end
  end
  module_function :event_masks

  # Set event masks
  def event_masks=(mask_arg)
    RubyVM::TraceHook::trace_hooks.map do |hook|
      event_mask = convert_event_mask(mask_arg)
      hook.event_mask = event_mask
    end
  end
  module_function :'event_masks='

  # Replacement for Kernel set_trace - allows for a more liberal event mask
  def set_trace_func(*args)
    if args.size > 3 or args.size < 1
      raise ArgumentError, "wrong number of arguments (#{args.size} for 1..2)"
    end
    proc, mask_arg = args
    if proc.nil? 
      if args.size != 1
        raise ArgumentError, 
        "When first argument (Proc) is nil, there should be only one argument"
      end
      return Kernel.set_trace_func(proc)
    elsif mask_arg.nil?
      Kernel.set_trace_func(proc)
    else # args.size == 2
      event_mask = convert_event_mask(mask_arg)
      Kernel.set_trace_func(proc, event_mask)
    end
  end
  module_function :set_trace_func
end

if __FILE__ == $0
  # Demo it
  include Trace
  require 'set'
  mask, unhandled = events2bitmask([LINE_EVENT_MASK, CLASS_EVENT_MASK])
  p bitmask2events(mask)
  p [mask, unhandled]
  p events2bitmask(Set.new([LINE_EVENT_MASK, CLASS_EVENT_MASK]))
  p events2bitmask(['LINE', 'Class'])
  p events2bitmask(Set.new(['LINE', 'Class']))
  p events2bitmask([:foo, 'bar'])
  p events2bitmask(['C call', ['bar']])
  p events2bitmask(['C call', ['bar']])
  def foo ; end
  Trace::set_trace_func(Proc.new {|e, tf| p e}, [:call, :return])
  foo
  Trace::event_masks.each { |m| print "event mask: 0x%x\n" % m }
  Trace::event_masks = [:call]
  p '=' * 40
  foo
  Trace::event_masks.each { |m| print "event mask: 0x%x\n" % m }
  p '=' * 40
  Trace::set_trace_func(Proc.new {|e, tf| p e})
  Trace::event_masks.each { |m| print "event mask: 0x%x\n" % m }
  foo
  Trace::set_trace_func(nil)
  p '=' * 40
  foo
  p '=' * 40
  Trace::event_masks.each { |m| print "event mask: 0x%x\n" % m }
  
end
