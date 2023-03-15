class HomeController < ApplicationController
  def index
  end

   def get_suggestions
    @year_level = params[:year_level]
    @type_of_paragraph = params[:type_of_paragraph]
    @essay_question = params[:essay_question]
    @your_paragraph = params[:your_paragraph]
    @suggestions = EssayCorrectionTool.new(
      @year_level,
      @type_of_paragraph,
      @essay_question,
      @your_paragraph,
      "text-davinci-003",
    ).get_suggestions
  end
end
