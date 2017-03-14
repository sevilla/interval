class Interval
  include Comparable
  # @return [Integer]
  attr_accessor :start, :end

  def initialize(istart = 0, iend = 0)
    fail "Start and End times should be numeric" unless istart.is_a?(Fixnum) && iend.is_a?(Fixnum)
    fail "Invalid interval" if istart > iend
    @start = istart
    @end = iend
  end

  # Converts the interval to a staring of the form 'Interval(@start, @end)'
  # @return [String]
  def to_s
    "Interval(#{@start}, #{@end})"
  end

  # Converts the interval to an array of the form [@start, @end]
  # @return [Array]
  def to_a
    [@start, @end]
  end
  alias_method :dump, :to_a

  # Returns an integer (-1, 0, or +1) if this {Interval} is less than, equal to, or greater than other_interval.
  #
  # An interval is greater or less than another interval depending on their start values. If both start values are equal
  # the end values are used
  # @param other_interval [Interval] to compare
  # @return [Integer] (-1, 0, or +1)
  def <=>(other)
    if @start == other.start
      @end <=> other.end
    else
      @start <=> other.start
    end
  end

  # Equality operator
  #
  # Two intervals are equal if both their start and end values are equal
  # @param other_interval [Interval]
  # @return [Boolean]
  def ==(other)
    (other.is_a? Interval) && (@start == other.start && @end == other.end)
  end

  # Computes the interval at which the two intervals instersect.
  # @param other_interval [Interval]
  # @return [Interval]
  def intersect(other_interval)
    if self.end <= other_interval.start || other_interval.end <= start
      nil
    else
      Interval.new([start, other_interval.start].max, [self.end, other_interval.end].min)
    end
  end

  def -(other)
    unless other.is_a?(Interval)
      other = other.to_interval_set
    end
    self_interval_set = to_interval_set

    self_interval_set - other
  end

  def to_interval_set
    IntervalSet.new([[start, self.end]])
  end

  def contains?(interval)
    start <= interval.start && self.end >= interval.end
  end

  def overlaps?(other_interval)
    other_interval.start.between?(start, self.end) || other_interval.end.between?(start, self.end) ||
      start == other_interval.end || self.end == other_interval.start
  end

  def merge_overlapping(interval)
    fail "Intervals are not overlapping" unless overlaps? interval

    start_time = start <= interval.start ? start : interval.start
    end_time = self.end >= interval.end ? self.end : interval.end

    Interval.new(start_time, end_time)
  end

  def duration
    end_time = to_time(self.end)
    start_time = to_time(start)
    time = end_time - start_time
    (time / 60).to_i
  end

  def empty?
    start == self.end
  end

  private

  def to_time(number)
    h = number / 100
    m = number - h * 100
    Time.parse("#{h}:#{m}")
  end
end