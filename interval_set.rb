class IntervalSet
  # Array of {Interval}s for this {IntervalSet}
  # @return [Array]
  attr_accessor :intervals

  def initialize(int = [])
    fail ArgumentError, 'IntervalSet requires an array argument' unless int.is_a? Array
    @intervals = []
    int.each do |interval|
      if interval.is_a?(Interval)
        @intervals << interval
      elsif interval.is_a?(IntervalSet)
        @intervals += interval.intervals
      else
        @intervals << Interval.new(*interval)
      end
    end
  end

  # Parses a string of the form '1-2,2-3,3-4' into an {IntervalSet}
  #
  # @param interval_string [String]
  # @return [IntervalSet]
  def self.parse(interval_string)
    intervals = interval_string.split(",")
    intervals = intervals.collect do |interval|
      interval.split("-").collect(&:to_i)
    end
    new(intervals)
  end

  def dump
    @intervals.map &:dump
  end

  # Equality operator
  #
  # Two interval sets are equal if their sorter intervals are equal
  # @param other_set [IntervalSet]
  # @return [Boolean]
  def ==(other)
    if other.is_a?(IntervalSet)
      intervals.sort == other.intervals.sort
    else
      false
    end
  end

  # Computes the union of the two {IntervalSet IntervalSets}
  #
  # Iterates over the the two IntervalSet's sorted intervals. If the current interval does not overlap
  # with the last inverval it is added to the result. Otherwise the last interval is modified
  # in place to have the same end time as the current invertval
  #
  # @param other_set [IntervalSet]
  # @return [IntervalSet]
  def union(other_set)
    sorted_intervals = (intervals + other_set.intervals).sort

    ret = sorted_intervals.inject([sorted_intervals.shift]) do |result, interval|
      if result.last.end < interval.start
        result << interval
      elsif interval.end > result.last.end
        result.last.end = interval.end
      end

      result
    end

    ret.compact!

    IntervalSet.new(ret.to_a)
  end

  # Computes the intersection of the two {IntervalSet IntervalSets}
  #
  # Intersects every interval in the current set with every interval in other_set.
  # Then unions the resulting {IntervalSet} with itself thus removing duplicates and overlaps
  #
  # @param other_set [IntervalSet]
  # @return [IntervalSet]
  def intersect(other_set)
    res = []
    intervals.each do |i|
      other_set.intervals.each do |j|
        inter = i.intersect(j)
        res << inter if inter
      end
    end

    set = IntervalSet.new

    set.intervals = res

    set.union(set)
  end

  def -(other_set)
    if other_set.is_a?(Interval)
      other_set = other_set.to_interval_set
    end

    return self if other_set.intervals.empty?

    result_intervals = intervals
    other_set.intervals.each do |o_interval|
      temp = []
      result_intervals.each do |self_interval|
        next if self_interval == o_interval # if the intervals are the same do nothing
        if self_interval.contains?(o_interval)
          temp << Interval.new(self_interval.start, o_interval.start) unless self_interval.start == o_interval.start
          temp << Interval.new(o_interval.end, self_interval.end) unless o_interval.end == self_interval.end
        elsif self_interval.overlaps?(o_interval)
          if self_interval.end < o_interval.end
            temp << Interval.new(self_interval.start, o_interval.start)
          else
            temp << Interval.new(o_interval.end, self_interval.end)
          end
        elsif !o_interval.contains?(self_interval)
          temp << self_interval
        end
      end
      result_intervals = temp
    end

    set = IntervalSet.new(result_intervals)
    if self.empty?
      set
    else
      set.union(set)
    end
  end

  def empty?
    @intervals.empty?
  end

  def contains?(interval)
    answer = false

    intervals.each do |s_interval|
      answer = true if s_interval.contains?(interval)
    end

    answer
  end

  # Converts the interval set to an array
  #
  # Array is of the form:
  #   [[1,2], [2,3], ..]
  #
  # @return [Array]
  def to_a
    result = []
    @intervals.each do |int|
      result << int.to_a
    end
    result
  end

  def merge_overlapping_intervals!
    intervals = cloned_intervals.sort
    new_intervals = []
    while intervals.any?
      interval = intervals.shift
      overlapping_intervals = intervals.select { |i| i.overlaps? interval }

      if overlapping_intervals.any?
        overlapping_intervals.each do |o_int|
          interval = interval.merge_overlapping o_int
          intervals.unshift interval
        end
      else
        new_intervals << interval
      end

      intervals -= overlapping_intervals
    end

    @intervals = new_intervals
    self
  end

  # Converts the {IntervalSet} to an array
  #
  # Array is of the form:
  #   [{"start" => 0, "end" => 2400}]
  #
  # @return [Array]
  def as_json(*_)
    @intervals.sort!.collect { |i| { "start" => i.start, "end" => i.end } }
  end

  def clone
    IntervalSet.new(cloned_intervals)
  end

  def cloned_intervals
    @intervals.map { |x| Interval.new(x.start, x.end) }
  end
end
