#!/usr/bin/env ruby
require 'test/unit'
require_relative %w(.. .. lib trace_mod)

# Testing Trace Module
class TestTrace < Test::Unit::TestCase

  def test_set_trace_func
    @events = []
    def foo ; end

    event_set = [:call, :return]
    Trace::set_trace_func(Proc.new {|e, tf| @events << e}, event_set)
    foo
    call_return_mask = Trace::event_masks[0]
    assert_equal(Fixnum, call_return_mask.class)

    Trace::event_masks = [:call]
    foo
    call_mask = Trace::event_masks[0]
    Trace::set_trace_func(nil)

    @events.each do |e| 
      assert_equal(true, event_set.member?(e.to_sym), 
                   "#{e} should be in #{event_set}")
    end
    
    assert_equal(true,
                 ((call_return_mask > call_mask) &&
                  (0 != (call_return_mask & call_mask))))
                 
    @events = []
    Trace::set_trace_func(nil)
    @events.each do |e| 
      assert_equal(true, event_set.member?(e.to_sym), 
                   "#{e} should be in #{event_set}")
    end

    assert_equal(nil, Trace::event_masks[0])
  end

end
