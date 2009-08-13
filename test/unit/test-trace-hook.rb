#!/usr/bin/env ruby
require 'test/unit'
require_relative File.join(%w(.. .. ext trace))
class TestEventHook < Test::Unit::TestCase
  def test_basic
    tt = RubyVM::Trace::trace_hooks
    assert_equal([], tt)
    set_trace_func(Proc.new { 1  })
    tt = RubyVM::Trace::trace_hooks
    assert_equal(1, tt.size)
    assert tt[0].event_mask.is_a?(Fixnum)
    assert_equal true, tt[0].proc.is_a?(Proc)
    assert_equal 1, tt[0].proc.call
    
    set_trace_func(Proc.new { }, 5)
    tt = RubyVM::Trace::trace_hooks
    assert_equal(1, tt.size)
    assert_equal(5, tt[0].event_mask)
    tt[0].event_mask = 6;
    assert_equal(6, tt[0].event_mask)

    set_trace_func(nil)
    tt = RubyVM::Trace::trace_hooks
    assert_equal(true, tt.empty?)
    
  end
end
