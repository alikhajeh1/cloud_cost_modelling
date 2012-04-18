class PatternsController < ApplicationController

  before_filter :authenticate_user!
  before_filter :load_pattern, :only => [:show, :update, :destroy, :clone]

  def index
    load_patterns
    @pattern = current_user.patterns.new
  end

  def show
    flash.keep
    # By default, go to the rules tab of the pattern when it's opened
    redirect_to pattern_rules_url(@pattern)
  end

  def update
    if @pattern.update_attributes(params[:pattern])
      head :ok
    else
      render :json => @pattern.errors.full_messages, :status => :unprocessable_entity
    end
  end

  def create
    @pattern = current_user.patterns.new(params[:pattern])
    if @pattern.save
      redirect_to @pattern, :flash => {:success => 'Pattern was created.'}
    else
      load_patterns
      render :index
    end
  end

  def destroy
    @pattern.destroy
    redirect_to patterns_url, :flash => {:success => 'Pattern and all of its rules were deleted.'}
  end

  def clone
    begin
      new_pattern = @pattern.deep_clone
      redirect_to new_pattern, :flash => {:success => 'Pattern and all of its rules were cloned.'}
    rescue
      redirect_to patterns_url, :flash => {:error => 'Pattern could not be cloned.'}
    end
  end

  private
  def load_pattern
    @pattern = current_user.patterns.find(params[:id])
  end

  def load_patterns
    @patterns = current_user.patterns.page(params[:page]).order(:name)
  end
end