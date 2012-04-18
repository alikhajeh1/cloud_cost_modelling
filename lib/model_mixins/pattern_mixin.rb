module ModelMixins::PatternMixin
  def self.included(base)
    base.instance_eval { has_many :pattern_maps, :as => :patternable, :order => 'position', :dependent => :destroy }
    base.instance_eval { has_many :patterns, :through => :pattern_maps }
  end

  def get_patterns(attribute)
    PatternMap.includes(:pattern).where("patternable_id = ? AND patternable_type = ? AND patternable_attribute = ?",
      self.id, self.class.to_s, attribute).order(:position).collect{|pm| pm.pattern}
  end

  # This method return all of the patterns for the object ordered correctly, followed by the remaining user patterns ordered by name.
  # The list is used by the pattern_attachment UI
  def get_all_patterns_ordered(attribute)
    hash = {:attribute => attribute, :all_patterns => []}
    hash[:all_patterns] += get_patterns(attribute)
    hash[:selected_patterns_count] = hash[:all_patterns].count
    self.user.patterns.order(:name).each do |p|
      hash[:all_patterns] << p unless hash[:all_patterns].include?(p)
    end
    hash
  end

  def is_pattern_attached?(attribute, pattern)
      PatternMap.includes(:pattern).where("pattern_id = ? AND patternable_id = ? AND patternable_type = ? AND patternable_attribute = ?",
      pattern.id, self.id, self.class.to_s, attribute).size > 0
  end

  def add_patterns(attribute, patterns)
    raise AppExceptions::InvalidParameter.new("Patterns can only be added to one of #{self.class}'s attributes.") unless self.has_attribute?(attribute)
    raise AppExceptions::InvalidParameter.new("Patterns can only be added to numeric attributes.") unless
        [:integer, :float, :decimal].include?(self.column_for_attribute(attribute).type)
    patterns.each do |pattern|
      pattern_map = PatternMap.new
      pattern_map.user = self.user if self.has_attribute?(:user_id)
      pattern_map.patternable = self
      pattern_map.patternable_attribute = attribute
      pattern_map.pattern = pattern
      pattern_map.save!
    end
  end

  def remove_patterns(attribute, patterns)
    PatternMap.destroy_all(["patternable_id = ? AND patternable_type = ? AND patternable_attribute = ? AND pattern_id IN (?)",
                           self.id, self.class.to_s, attribute, patterns.collect{|p| p.id}])
  end

  def remove_all_patterns(attribute)
    PatternMap.delete_all(["patternable_id = ? AND patternable_type = ? AND patternable_attribute = ?",
                          self.id, self.class.to_s, attribute])
  end

end