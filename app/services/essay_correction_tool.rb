class EssayCorrectionTool


  FIRST_BULLET_REGEX  = /((?<=1\)).*(?=2\))|(?<=1\.).*(?=2\.)|(?<=1\:).*(?=2\:)|(?<=Step 1\:).*(?=Step 2\:))/m
  SECOND_BULLET_REGEX = /((?<=2\)).*(?=3\))|(?<=2\.).*(?=3\.)|(?<=2\:).*(?=3\:)|(?<=Step 2\:).*(?=Step 3\:))/m
  THIRD_BULLET_REGEX  = /((?<=3\)).*|(?<=3\.).*|(?<=3\:).*|(?<=Step 3\:).*)/m

  def initialize year_level, type_of_paragraph, essay_question, your_paragraph, model
    @year_level = year_level
    @type_of_paragraph = type_of_paragraph
    @essay_question = essay_question
    @your_paragraph = your_paragraph
    @client = OpenAI::Client.new
    @model = model
  end

  def get_suggestions
    response_data = ""

    if @model == "text-davinci-003"
      response_data = use_completion_api
    else @model == "gpt-3.5-turbo"
      response_data =  use_chat_api
    end
    # handle_response(response_data)
    handle_response_v2(response_data)
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
        model: "gpt-3.5-turbo",
        messages: [{"role": "user", "content": design_prompt}]
      })
    response["choices"][0]["message"]["content"]
  end

  def handle_response(text)
    bullets_regex = Regexp.union(["1.", "2.", "3.", "1)", "2)", "3)", "Step 1:", "Step 2:", "Step 3:"])
    sanitize_array text.split(bullets_regex)
  end

  def handle_response_v2(text)
    text_array = []
    text_array.push text.match(FIRST_BULLET_REGEX).to_s
    text_array.push text.match(SECOND_BULLET_REGEX).to_s
    text_array.push text.match(THIRD_BULLET_REGEX).to_s
    text_array
  end

  def sanitize_array(suggestion_array)
    suggestion_array.map{|e| e.gsub(/\n/, "").strip}.reject{ |e| e.empty? }
  end

  def design_prompt
    "I am a Year #{@year_level} student and I was given the essay prompt \"#{@essay_question}\"\n\n
    This is my #{@type_of_paragraph}. What are the three steps I could do to improve my #{@type_of_paragraph}.
    Could you please explain why I should do these improvements in British English without rewriting it for me?
    #{@your_paragraph}"
  end
end
