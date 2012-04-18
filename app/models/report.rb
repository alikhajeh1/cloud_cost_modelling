class Report < ActiveRecord::Base
  USER_REPORTABLE_MODELS = ['Deployment']
  REPORT_STATUSES = ['Pending', 'Processing', 'Completed', 'Failed']

  belongs_to :user
  belongs_to :reportable, :polymorphic => true

  validates :user_id, :name, :reportable_id, :reportable_type, :presence => true
  validates :start_date, :date => {:after => Time.new(2011, 12, 31),
                                   :message => "can't be earlier than 2012-01 as we don't have pricing details for earlier dates"}
  validates :end_date, :date => {:after => :start_date}
  validate :check_date_range

  attr_accessible :name, :description, :start_date, :end_date
  before_destroy :updatable?

  default_scope select((column_names - ['xml', 'html']).map { |column_name| "\"#{table_name}\".\"#{column_name}\""})

  def check_date_range
    errors.add(:end_date, 'is invalid. Maximum reporting period is 10 years') if start_date && end_date &&
        Time.diff(start_date, end_date)[:year] > 10
  end

  def display_start_date
    start_date.strftime("%Y-%m")
  end

  def display_end_date
    end_date.strftime("%Y-%m")
  end

  def updatable?
    ['Completed', 'Failed'].include? self.status
  end
end