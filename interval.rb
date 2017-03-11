class Interval
  attr_accessor :start, :end

  def initialize(istart = 0, iend = 0)
    fail "Start and End times should be numeric" unless istart.is_a?(Fixnum) && iend.is_a?(Fixnum)
    fail "Invalid interval" if istart > iend
    @start = istart
    @end = iend
  end

  def contains?(interval)
    start <= interval.start && self.end >= interval.end
  end

  def ==(interval)
    self.start == interval.start && self.end == interval.end
  end

  def union(interval)
    istart = (self.start <= interval.start) ? self.start : interval.start
    iend = (self.end >= interval.end) ? self.end : interval.end

    Interval.new(istart, iend)
  end

  def intersection(interval)
    istart = (self.start >= interval.start) ? self.start : interval.start
    iend = (self.end <= interval.end) ? self.end : interval.end

    Interval.new(istart, iend)
  end

  def to_s
    "[#{self.start}, #{self.end}]"
  end
end
