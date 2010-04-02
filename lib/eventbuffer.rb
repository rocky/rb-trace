class TraceBuffer
  EventStruct = Struct.new(:event, :arg, :type, :thread, :method,
                           :source_container, :source_location,
                           :iseq, :pc_offset) unless defined?(EventStruct)
  attr_reader   :buf
  attr_accessor :marks    # User position mark into buffer. If buffer is limited,
  attr_reader   :maxsize  # Maximum size of buffer or nil if unlimited.
  attr_reader   :size     # size of buffer 
  # then marks will drop out as they disappear from the buffer
  def initialize(maxsize=nil)
    @maxsize = maxsize
    reset
  end
  
  def reset
    @buf   = []
    @marks = []
    @pos   = -1
    @size  = 0 
  end
  
  # Add a new event dropping off old events if that was declared
  # marks are also dropped if buffer has a limit.
  def append(event, frame, arg)
    iseq = frame.iseq
    item = EventStruct.new(event, arg, frame.type, frame.thread, frame.method,
                           frame.source_container, frame.source_location,
                           iseq, iseq ? frame.pc_offset : nil)
    @pos = next_pos
    @marks.shift if @marks[0] == @pos
    @buf[@pos] = item
    @size     += 1 unless @maxsize && @size == @maxsize
  end
  
  def next_pos
    pos = @pos + 1 
    if @maxsize && @pos == @maxsize
      0
    else
      pos
    end
  end
  
  def add_mark
    @marks << @pos
  end
  
  def each(from=nil, to=nil)
    from = next_pos unless from
    to   = @pos     unless to
    if from <= to
      from.upto(to).each do |pos|
        yield @buf[pos]
      end
    else
      from.upto(@size-1).each do |pos|
        yield @buf[pos]
      end
      0.upto(@pos).each do |pos|
        yield @buf[pos]
      end
    end
  end
  
  def format_entry(item, long_format=true)
    # require 'rbdbgr'; Debugger.debug
    container = 
      if item.source_container[0] == 'file'
        item.source_container[1].inspect
      else
        item.source_container.inspect
      end
    
    location = 
      if 1 == item.source_location.size 
        item.source_location[0].inspect
      else
        item.source_location.inspect
      end
    
    mess = "#{item.event} #{item.type} #{item.method} " + 
      "#{container} #{location}"
    if long_format && item.iseq
      mess += "\n\t" + "VM offset #{item.pc_offset} of #{item.iseq.name}"
    end
    mess
  end
end
if __FILE__ == $0
  def event_processor(event, frame, arg=nil)
    begin 
      @eventbuf.append(event, frame, arg)
    rescue
      p $!
    end
  end
  def dump_all
    puts '-' * 40
    @eventbuf.each do |e| 
      puts @eventbuf.format_entry(e) if e
    end
  end

  require 'trace'
  @eventbuf = TraceBuffer.new(5)
  dump_all

  trace_filter = TraceFilter.new
  trace_func   = method(:event_processor).to_proc
  trace_filter << trace_func
  trace_filter.set_trace_func(trace_func)
  z=5
  z.times do |i|
    x = i
    y = x+2
  end
  trace_filter.set_trace_func(nil)
  dump_all
  @eventbuf.reset
  dump_all
end
