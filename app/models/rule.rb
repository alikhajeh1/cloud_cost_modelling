class Rule < ActiveRecord::Base
  belongs_to :user # If it does not belong to user, then it's being used by cloud_cost_structure
  belongs_to :pattern
  acts_as_list :scope => :pattern

  RULE_TYPES = ['permanent', 'temporary']
  VARIATIONS = {'+' => 'add', '-' => 'subtract', '*' => 'multiply by', '/' => 'divide by', '^' => 'raise to power of', '=' => 'set to'}
  MONTHS = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec']
  DAYS = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat']

  validates :pattern_id, :presence => true

  validates_format_of :rule_type, :with => /\A(#{RULE_TYPES.join('|')})\z/i
  validates_format_of :year, :with => /\A(every\.\d+\.years?|year\.\d+-year\.\d+|year\.\d+|\d{4}|\d{4}-\d{4})\z/i
  validates_format_of :month, :allow_blank => true, :with => /\A(every\.\d+\.months?|(?:#{MONTHS.join('|')})-(?:#{MONTHS.join('|')})|#{MONTHS.join('|')})\z/i
  validates_format_of :day, :allow_blank => true, :with => /\A(every\.\d+\.days?|(?:first|last).(?:#{DAYS.join('|')})|(?:first|last).(?:#{DAYS.join('|')})-(?:#{DAYS.join('|')})|every.(?:#{DAYS.join('|')})-(?:#{DAYS.join('|')})|every.(?:#{DAYS.join('|')})|\d{1,2}|\d{1,2}-\d{1,2})\z/i
  validates_format_of :hour, :allow_blank => true, :with => /\A(every\.\d+\.hours?|\d{1,2}|\d{1,2}-\d{1,2})\z/i
  validates :variation, :inclusion => {:in => VARIATIONS.keys, :message => "%{value} is not a valid variation symbol"}
  validates :value, :numericality => {:greater_than_or_equal_to => 0}
  validates :position, :allow_nil => true, :numericality => {:only_integer => true, :greater_than_or_equal_to => 0}
  validate :check_ranges

  scope :no_users, where(:user_id => nil)

  attr_accessible :rule_type, :year, :month, :day, :hour, :variation, :value, :position

  def check_ranges
    errors.add(:year, 'must be greater than 0') if year =~ /\Ayear\.(\d+)\z/i && $1.to_i <= 0
    errors.add(:year, 'must be greater than 0') if year =~ /\Aevery\.(\d+).years?\z/i && $1.to_i <= 0
    errors.add(:year, 'must be a valid range (first year must be earlier than second year)') if year && !valid_range?(year, 1900, 2200)
    errors.add(:month, 'must be a valid range (first month must be earlier than second month)') if month && !valid_range?(month, 1, 12)
    errors.add(:day, 'must be between 1 and 31') if day && !valid_range?(day, 1, 31)
    errors.add(:hour, 'must be between 0 and 23') if hour && !valid_range?(hour, 0, 23)
  end

  def deep_clone(options={})
    Rule.transaction do
      new_rule = self.dup
      new_rule.save!
      new_rule
    end
  end

  # Used by PatternsEngine to decide when the rule is applied
  def applicable?(start_date, current_date)
    time_diff = Time.diff(current_date, start_date)

    case self.year
      # every.1.years
      when /\Aevery\.(\d+)\.years?\z/i
        if self.month && !self.month.empty?
          return true if time_diff[:year] % $1.to_i == 0 && applicable_month?(current_date, time_diff)
        else
          return true if time_diff[:year] % $1.to_i == 0 && time_diff[:month] == 0
        end

      # year.4
      when /\Ayear\.(\d+)\z/i
        if self.month && !self.month.empty?
          return true if (time_diff[:year] + 1) == $1.to_i && applicable_month?(current_date, time_diff)
        else
          return true if (time_diff[:year] + 1) == $1.to_i && time_diff[:month] == 0
        end

      # year.4-year.6
      when /\Ayear\.(\d+)-year\.(\d+)\z/i
        if self.month && !self.month.empty?
          return true if (time_diff[:year] + 1).between?($1.to_i, $2.to_i) && applicable_month?(current_date, time_diff)
        else
          return true if (time_diff[:year] + 1).between?($1.to_i, $2.to_i) && time_diff[:month] == 0
        end

      # 2015
      when /\A(\d{4})\z/i
        if self.month && !self.month.empty?
          return true if current_date.year == $1.to_i && applicable_month?(current_date, time_diff)
        else
          return true if current_date.year == $1.to_i && current_date.month == 1
        end

      # 2015-2020
      when /\A(\d{4})-(\d{4})\z/i
        if self.month && !self.month.empty?
          return true if current_date.year.between?($1.to_i, $2.to_i) && applicable_month?(current_date, time_diff)
        else
          return true if current_date.year.between?($1.to_i, $2.to_i) && current_date.month == 1
        end
    end

    false
  end

  private
  def valid_range?(field, min, max)
    if field =~ /\A(\d+)\z/
      $1.to_i.between?(min, max)
    elsif field =~ /\A(\d+)-(\d+)\z/
      $1.to_i.between?(min, max) && $2.to_i.between?(min, max) && $1.to_i < $2.to_i
    elsif field =~ /\Ayear\.(\d+)-year\.(\d+)\z/i
      $1.to_i > 0 && $1.to_i < $2.to_i
    elsif field =~ /\A(#{MONTHS.join('|')})-(#{MONTHS.join('|')})\z/i
      Rule::MONTHS.index($1) < Rule::MONTHS.index($2)
    else
      true
    end
  end

  # Used internally by the applicable? method to decide when the rule is applied
  def applicable_month?(current_date, time_diff)
    case self.month
      # every.2.months
      when /\Aevery\.(\d+)\.months?\z/i
        return true if time_diff[:month] % $1.to_i == 0

      # jun
      when /\A(#{MONTHS.join('|')})\z/i
        return true if (Rule::MONTHS.index($1) + 1) == current_date.month

      # jun-sep
      when /\A(#{MONTHS.join('|')})-(#{MONTHS.join('|')})\z/i
        return true if current_date.month.between?(Rule::MONTHS.index($1) + 1, Rule::MONTHS.index($2) + 1)
    end

    false
  end
end

