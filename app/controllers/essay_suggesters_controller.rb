class EssaySuggestersController < ApplicationController

  def show
    @essay_suggester = EssaySuggester.find(params[:id])
  end
end
