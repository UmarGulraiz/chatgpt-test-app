class HomeController < ApplicationController
  def index
    @year_level = params[:year_level]
    @type_of_paragraph = params[:type_of_paragraph]
    @essay_question = params[:essay_question]
    @your_paragraph = params[:your_paragraph]
    @suggestions = EssayCorrectionTool.new(
      @year_level,
      @type_of_paragraph,
      @essay_question,
      @your_paragraph,
      "gpt-3.5-turbo",
    ).get_suggestions
  end
end
