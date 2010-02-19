#!/usr/bin/env ruby
require 'test/unit'
require_relative %w(.. .. lib tracefilter)

# Testing Trace Filter class
class TestTraceFilter < Test::Unit::TestCase

  def setup
    $args     = []
    $events   = []
    $line_nos = []
    @trace_filter = TraceFilter.new unless defined?(@trace_filter)
    @trace_filter.clear
  end

  def teardown
    $args   = []
    $events = []
    $line_nos = []
  end

  # Just something to trace
  def square(x)
    x * x
  end

  # Save stuff from the trace for inspection later.
  def my_hook(event, tf, arg=nil)
    $args     << arg if arg
    $events   << event
    $line_nos << tf.source_location[0] if tf.source_location
  end

  def trace_test(dont_trace_me)
    $start_line = __LINE__
    @trace_filter << self.method(:trace_test) if dont_trace_me

    # Start tracing.
    @trace_filter.set_trace_func(method(:my_hook).to_proc)
    square(10)
    x = 100
    square(x)
    $end_line = __LINE__
  end

  def print_trace
    $line_nos.each_with_index do |line_no, i|
      print "%2d %s %s\n" % [i, $events[i], line_no]
    end
    p $args
  end

  def test_basic
    trace_test(true)
    @trace_filter.set_trace_func(nil)
    print_trace if $DEBUG

    assert_equal(false, $events.empty?, 
                 'We should have gotting some trace output')
    assert_equal([Kernel, Kernel], $args,
                 'C call/returns set $args')
    assert_equal(0, $args.size % 2, 
                 'Should have equal number of C calls and returns')

    $line_nos.each_with_index do 
      |line_no, i|
      assert_equal(false, ($start_line..$end_line).member?(line_no),
                   "We should not find a line number in " +
                   "#{$start_line}..#{$end_line}; " + 
                   "got line number #{line_no} at index #{i}, " + 
                   "event #{$events[i]}")
    end
    untraced_line_nos = $line_nos
    untrace_events = $events

    setup
    trace_test(false)
    @trace_filter.set_trace_func(nil)
    print_trace if $DEBUG

    assert_equal(true, $line_nos.size > untraced_line_nos.size,
                 'We should have traced more stuff than untraced output')

    found_one = false
    $line_nos.each_with_index do 
      |line_no, i|
      if ($start_line..$end_line).member?(line_no)
        found_one = true
        break
      end
    end
    assert_equal(true, found_one, 
                 'We should have found a line number for at least one event ' +
                 'in traced output.')

    assert_raises TypeError do 
      @trace_filter.set_trace_func(method(:trace_test))
    end
  end

end
