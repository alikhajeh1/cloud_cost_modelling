class RulesController < ApplicationController

  before_filter :authenticate_user!
  before_filter :load_pattern, :only => [:index, :show, :update, :create, :destroy, :clone, :move_higher, :move_lower]
  before_filter :load_rule, :only => [:update, :destroy, :clone, :move_higher, :move_lower]

  def index
    load_rules
    @rule = current_user.rules.new
  end

  def show
    redirect_to pattern_rules_url(@pattern)
  end

  def update
    if @rule.update_attributes(params[:rule])
      head :ok
    else
      render :json => @rule.errors.full_messages, :status => :unprocessable_entity
    end
  end

  def create
    @rule = current_user.rules.new(params[:rule])
    @rule.pattern = @pattern
    if @rule.save
      redirect_to pattern_rules_url(@pattern), :flash => {:success => 'Rule was created.'}
    else
      load_rules
      render :index
    end
  end

  def destroy
    @rule.destroy
    redirect_to pattern_rules_url(@pattern), :flash => {:success => 'Rule was deleted.'}
  end

  def clone
    begin
      @rule.deep_clone
      redirect_to pattern_rules_url(@pattern), :flash => {:success => 'Rule was cloned.'}
    rescue
      redirect_to pattern_rules_url(@pattern), :flash => {:error => 'Rule could not be cloned.'}
    end
  end

  def move_higher
    @rule.move_higher
    redirect_to pattern_rules_url(@pattern), :flash => {:success => 'Rule was moved higher.'}
  end

  def move_lower
    @rule.move_lower
    redirect_to pattern_rules_url(@pattern), :flash => {:success => 'Rule was moved lower.'}
  end

  private
  def load_pattern
    @pattern = current_user.patterns.find(params[:pattern_id])
  end

  def load_rule
    @rule = @pattern.rules.find(params[:id])
  end

  def load_rules
    @rules = @pattern.rules.page(params[:page])
  end
end
