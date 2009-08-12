require 'set'
require 'thread_frame'

# A class that can be used to test whether
# certain frames or functions should be excluded in tracing.
class TraceFilter

  attr_reader :excluded

  def initialize(excluded_fns = [])
    valid_fns = excluded_fns.select{|fn| valid_fn?(fn)}
    @excluded = Set.new(valid_fns)
  end

  def valid_fn?(frame_or_fn)
    frame_or_fn.is_a?(RubyVM::ThreadFrame)
  end

  def <<(frame_or_fn)
    if valid_fn?(frame_or_fn)
      @excluded << frame
      return true
    else
      return false
    end
  end

  # Null out list of excluded fns
  def clear
    @excluded = Set.new
  end

  # Return true if `frame_or_fn' is in the list of functions to exclude
  def excluded?(frame_or_fn)
    return nil unless valid_fn(frame_or_fn)
    @excluded.member?(frame_or_fn)
  end
        
  # Remove `frame_or_fn' from the list of functions to include
  def remove(frame_or_fn)
    return nil unless valid_fn(frame_or_fn)
    @excluded -= [frame_or_fn]
  end

end

if __FILE__ == $0
end
