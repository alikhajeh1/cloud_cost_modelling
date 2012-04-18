module ModelMixins::DataLinkMixin
  def self.included(base)
    base.instance_eval { has_many :source_data_links, :as => :sourcable, :class_name => 'DataLink', :dependent => :destroy }
    base.instance_eval { has_many :target_data_links, :as => :targetable, :class_name => 'DataLink', :dependent => :destroy }
  end

end