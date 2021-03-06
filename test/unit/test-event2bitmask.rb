#!/usr/bin/env ruby
require 'test/unit'
require 'set'
require_relative '../../lib/trace_mod'

class TestEvent2Bitmask < Test::Unit::TestCase
  include Trace
  
  def test_basic
    test_pair = events2bitmask([LINE_EVENT_MASK, CLASS_EVENT_MASK])
    test_mask, unhandled = test_pair
    assert_equal(test_pair, 
                 events2bitmask(Set.new([LINE_EVENT_MASK, CLASS_EVENT_MASK])))
    assert_equal([:class, :line], bitmask2events(test_mask))

    EVENT2MASK.each do |mask_name, bit_value|
      assert_equal([mask_name], bitmask2events(bit_value))
    end

    assert_equal(test_pair, events2bitmask(['LINE', 'Class']))
    assert_equal(test_pair, events2bitmask(Set.new(['LINE', 'Class'])))
    [[:foo, 'bar'], ['C call', ['bar']]].each do |bad|
      assert_equal([0, bad], events2bitmask(bad))
    end
  end
end
