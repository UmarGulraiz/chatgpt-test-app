class HomeController < ApplicationController
  before_action :configure_params
  def index
  end

   def get_suggestions
    return unless execute_chatgpt_api?

    @suggestions = EssayCorrectionTool.new(
      @year_level,
      @type_of_paragraph,
      @essay_type,
      @essay_question,
      @your_paragraph,
      "gpt-4",
    ).get_suggestions

    reset_fields
  end

  private

  def configure_params
    @year_level = params[:year_level]
    @type_of_paragraph = params[:type_of_paragraph]
    @essay_type = params[:essay_type]
    @essay_question = params[:essay_question]
    @your_paragraph = params[:your_paragraph]
    @suggestions = ""
  end

  def execute_chatgpt_api?
    @year_level.present? && @type_of_paragraph.present? && @essay_type.present? && @essay_question.present? && @your_paragraph.present?
  end

  def reset_fields
    @year_level = "7"
    @type_of_paragraph = "Introduction"
    @essay_type = "Comparative"
    @essay_question = ""
    @your_paragraph = ""
  end

end
