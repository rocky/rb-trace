#!/usr/bin/env ruby
require 'test/unit'
require_relative File.join(%w(.. .. ext trace))
class TestEventHook < Test::Unit::TestCase
  def test_basic
    tt = RubyVM::TraceHook::trace_hooks
    assert_equal([], tt)

    set_trace_func(Proc.new { 1  })
    tt = RubyVM::TraceHook::trace_hooks

    assert_equal(1, tt.size)
    assert_equal(true, tt[0].valid?)
    assert tt[0].event_mask.is_a?(Fixnum)
    assert_equal true, tt[0].proc.is_a?(Proc)
    assert_equal 1, tt[0].proc.call
    
    set_trace_func(Proc.new { }, 5)
    tt = RubyVM::TraceHook::trace_hooks

    assert_equal(1, tt.size)
    assert_equal(5, tt[0].event_mask)

    tt[0].event_mask = 6;
    assert_equal(6, tt[0].event_mask)

    set_trace_func(nil)
    assert_equal(false, tt[0].valid?)

    assert_raises RubyVM::TraceHookError do 
      tt[0].event_mask 
    end

    assert_raises RubyVM::TraceHookError do 
      tt[0].proc
    end
    
    tt = RubyVM::TraceHook::trace_hooks
    assert_equal(true, tt.empty?)
    
  end
end
