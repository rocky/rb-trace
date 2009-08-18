#!/usr/bin/env ruby
require 'test/unit'
require_relative %w(.. .. ext trace)

# Testing RubyVM::TraceHook
class TestTraceHook < Test::Unit::TestCase

  def setup
    set_trace_func(nil)
  end

  def test_trace_hooks
    tt = RubyVM::TraceHook::trace_hooks
    assert_equal([], tt)

    set_trace_func(Proc.new { 1  })
    tt = RubyVM::TraceHook::trace_hooks

    assert_equal(1, tt.size)
    assert tt[0].event_mask.is_a?(Fixnum)
    
    set_trace_func(Proc.new { }, 5)
    tt = RubyVM::TraceHook::trace_hooks

    assert_equal(1, tt.size)

    set_trace_func(nil)
    tt = RubyVM::TraceHook::trace_hooks
    assert_equal([], tt)
    
  end

  # Test getting and setting event mask of a trace hook
  def test_event
    set_trace_func(Proc.new { }, 5)
    tt = RubyVM::TraceHook::trace_hooks
    assert_equal(5, tt[0].event_mask)

    tt[0].event_mask = 6;
    assert_equal(6, tt[0].event_mask)

    set_trace_func(nil)
    assert_raises RubyVM::TraceHookError do 
      tt[0].event_mask 
    end

    assert_raises RubyVM::TraceHookError do 
      tt[0].event_mask = 10
    end

  end

  # Test getting and setting proc of a trace hook
  def test_proc
    p = Proc.new { 1 }
    set_trace_func(p)
    tt = RubyVM::TraceHook::trace_hooks
    assert_equal(p, tt[0].proc)
    assert_equal 1, tt[0].proc.call

    p2 = Proc.new { 2 }
    assert_raises TypeError do
      tt[0].proc = 5
    end
    tt[0].proc = p2

    assert_equal(p2, tt[0].proc)
    assert_equal 2, tt[0].proc.call

    set_trace_func(nil)
    assert_raises RubyVM::TraceHookError do 
      tt[0].proc
    end

    assert_raises TypeError do 
      tt[0].proc = 6
    end

    # Test valid?
    def test_valid
      tt = RubyVM::TraceHook::trace_hooks
      assert_equal(true, tt[0].valid?)
      set_trace_func(Proc.new {} )
      tt = RubyVM::TraceHook::trace_hooks
      assert_equal(true, tt[0].valid?)
      set_trace_func(Proc.new { 1 } )
      assert_equal(false, tt[0].valid?)
      tt = RubyVM::TraceHook::trace_hooks
      assert_equal(true, tt[0].valid?)
      set_trace_func(nil)
      GC.start
      assert_equal(false, tt[0].valid?)
    end
  end
end
