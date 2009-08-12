# Should be a singleton set? 
require_relative 'tracefilter'

module Trace

  # Event masks from <ruby.h>
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

  def set_trace_func_new(*args)
    if args.size > 3 or args.size < 1
      raise ArgumentError, "wrong number of arguments (#{args.size} for 1..2)"
    end
    proc, mask_arg = args
    if proc.nil? 
      if args.size != 1
        raise ArgumentError, 
        "When first argument (Proc) is nil, there should be only one argument"
      else
        return set_trace_func(proc)
      end
    elsif args.size == 2
      if mask.is_a?(Fixnum)
        event_mask = mask_arg
      elsif mask.kind_of?(Enumerable)
        event_mask, bad_events = event2bitmask(mask_arg)
        unless bad_events.empty?
          raise ArgumentError,
          "Bad set elements: #{bad_events.inspect}"
        end
      end
    end
    p "proc: #{proc} event_mask: #{event_mask}"
    # set_trace_func(proc, event_mask)
  end
  module_function :set_trace_func_new
end

if __FILE__ == $0
  # Demo it
  include Trace
  require 'set'
  p events2bitmask([LINE_EVENT_MASK, CLASS_EVENT_MASK])
  p events2bitmask(Set.new([LINE_EVENT_MASK, CLASS_EVENT_MASK]))
  p events2bitmask(['LINE', 'Class'])
  p events2bitmask(Set.new(['LINE', 'Class']))
  p events2bitmask([:foo, 'bar'])
  p events2bitmask(['C call', ['bar']])
  p events2bitmask(['C call', ['bar']])
end
