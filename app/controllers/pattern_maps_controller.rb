class PatternMapsController < ApplicationController

  before_filter :authenticate_user!
  before_filter :load_patternable, :only => [:multi_update]

  def multi_update
    pattern_ids = params[:pattern_map][:pattern]
    if pattern_ids
      patterns = current_user.patterns.find(pattern_ids)
      # The find method above does not return the patterns in order of the pattern_ids so we have to sort them manually
      sorted_patterns = params[:pattern_map][:pattern].inject([]){|res, val| res << patterns.detect {|u| u.id.to_s == val}}
      PatternMap.transaction do
        @patternable.remove_all_patterns(params[:pattern_map][:patternable_attribute])
        @patternable.add_patterns(params[:pattern_map][:patternable_attribute], sorted_patterns)
      end
    else
      @patternable.remove_all_patterns(params[:pattern_map][:patternable_attribute])
    end
    redirect_to :back
  end

  private
  def load_patternable
    raise AppExceptions::InvalidParameter.new("Patterns can only be added to user models.") unless
        Pattern::USER_PATTERNABLE_MODELS.include?(params[:pattern_map][:patternable_type])
    @patternable = params[:pattern_map][:patternable_type].constantize.where(
        'id = ? AND user_id = ?', params[:pattern_map][:patternable_id], current_user.id).first
    raise ActiveRecord::RecordNotFound unless @patternable
  end
end