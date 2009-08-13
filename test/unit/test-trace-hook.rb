#!/usr/bin/env ruby
require 'test/unit'
require_relative File.join(%w(.. .. ext trace))
class TestEventHook < Test::Unit::TestCase
  def test_basic
    assert_equal(nil, RubyVM::Trace::trace_hook)
    set_trace_func(Proc.new { })
    tt = RubyVM::Trace::trace_hook
    assert tt.event_mask.is_a?(Fixnum)
    set_trace_func(Proc.new { }, 5)
    tt = RubyVM::Trace::trace_hook
    assert_equal(5, tt.event_mask)
    tt.event_mask = 6;
    assert_equal(6, tt.event_mask)
  end
end
