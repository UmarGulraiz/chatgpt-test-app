class EssaySuggestionToolJob
  include Sidekiq::Job

  FIRST_BULLET_REGEX  = /((?<=1\)).*(?=2\))|(?<=1\.).*(?=2\.)|(?<=1\:).*(?=2\:)|(?<=Step 1\:).*(?=Step 2\:))/m
  SECOND_BULLET_REGEX = /((?<=2\)).*(?=3\))|(?<=2\.).*(?=3\.)|(?<=2\:).*(?=3\:)|(?<=Step 2\:).*(?=Step 3\:))/m
  THIRD_BULLET_REGEX  = /((?<=3\)).*|(?<=3\.).*|(?<=3\:).*|(?<=Step 3\:).*)/m

  def perform year_level, type_of_paragraph, essay_type, essay_question, your_paragraph, model, email_address
    @year_level = year_level
    @type_of_paragraph = type_of_paragraph
    @essay_type = essay_type
    @essay_question = essay_question
    @your_paragraph = your_paragraph
    @client = OpenAI::Client.new
    @model = model

    if @model == "text-davinci-003"
      response_data = use_completion_api
    elsif ["gpt-3.5-turbo", "gpt-4"].include?(@model)
      response_data =  use_chat_api
    end

    suggestions_array = handle_response(response_data)

    OpenaiMailer.send_response(suggestions_array, email_address).deliver_now
  end

  private

   def use_completion_api
    response = @client.completions(
      parameters: {
          model: "text-davinci-003",
          temperature: 0.9,
          prompt: design_prompt,
          max_tokens: 1500,
      })
    response["choices"][0]["text"]
  end

  def use_chat_api
    response = @client.chat(
      parameters:{
        model: @model,
        messages: [{"role": "user", "content": design_prompt}]
      })

    response["choices"][0]["message"]["content"]
  end

  def handle_response(text)
    text_array = []
    text_array.push text.match(FIRST_BULLET_REGEX).to_s
    text_array.push text.match(SECOND_BULLET_REGEX).to_s
    text_array.push modify_third_point(text.match(THIRD_BULLET_REGEX).to_s)
    text_array
  end

  def modify_third_point(text)
    text.split("\n\n")[0] rescue ""
  end

  def design_prompt
    return text_analytics_prompt if @essay_type == "Text Analysis"
    return comparative_prompt if @essay_type == "Comparative"
    return persuasive_prompt if @essay_type == "Persuasive"
  end

 def text_analytics_prompt
    "I am a Year #{@year_level} student and I was given the essay prompt:\"#{@essay_question}\".\n"\
    "This is a text analysis #{@type_of_paragraph}. This essay is meant to focus on a particular theme of literary element within a specific work of literature.\n"\
    "What are three steps I could do to improve my #{@type_of_paragraph}? Could you explain why I should do those improvements without rewriting it for me?\n"\
    "#{@your_paragraph}"
  end

  def comparative_prompt
    "I am a Year #{@year_level} student and I was given the essay prompt:\"#{@essay_question}\".\n"\
    "This is a comparative #{@type_of_paragraph}. This essay is meant to compare and contrast two or more texts focusing on a particular theme or literary element.\n"\
    "What are three steps I could do to improve my #{@type_of_paragraph}? Could you explain why I should do those improvements without rewriting it for me?\n"\
    "#{@your_paragraph}"
  end

  def persuasive_prompt
    "I am a Year #{@year_level} student and I was given the essay prompt:\"#{@essay_question}\".\n"\
    "This is a persuasive #{@type_of_paragraph}. This essay is meant to argue for a particular reason or viewpoint on a controversial issue.\n"\
    "What are three steps I could do to improve my #{@type_of_paragraph}? Could you explain why I should do those improvements without rewriting it for me?\n"\
    "#{@your_paragraph}"
  end
end
